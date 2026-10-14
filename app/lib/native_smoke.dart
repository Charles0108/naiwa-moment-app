import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/scene_catalog.dart';
import 'ui/scene_background.dart';

Future<void> runNativeSmoke(String resultPath) async {
  final result = <String, Object?>{'platform': Platform.operatingSystem};
  try {
    final preferences = SharedPreferencesAsync();
    final marker = DateTime.now().microsecondsSinceEpoch.toString();
    await preferences.setString('naiwa_native_smoke', marker);
    if (await preferences.getString('naiwa_native_smoke') != marker) {
      throw StateError('Native preference round trip failed');
    }
    await preferences.remove('naiwa_native_smoke');
    result['preferences'] = 'passed';
    final assets = <String, Object?>{};
    for (final name in ['rain', 'forest', 'ocean', 'cue']) {
      final player = Player();
      final errors = <String>[];
      final subscription = player.stream.error.listen(errors.add);
      try {
        await player.setVolume(0);
        final decoded = await Future.wait<Object?>([
          player.stream.playing.firstWhere((value) => value),
          player.stream.position.firstWhere(
            (value) => value.inMilliseconds > 0,
          ),
          player.stream.duration.firstWhere(
            (value) => value.inMilliseconds > 0,
          ),
          player.open(Media('asset:///assets/audio/$name.wav')),
        ]).timeout(const Duration(seconds: 15));
        if (errors.isNotEmpty) {
          throw StateError('Native audio playback failed: $name; $errors');
        }
        assets[name] = {
          'durationMs': (decoded[2] as Duration).inMilliseconds,
          'positionMs': (decoded[1] as Duration).inMilliseconds,
        };
      } finally {
        await subscription.cancel();
        await player.dispose();
      }
    }
    result['audioDurationsMs'] = assets;
    final scene = SceneCatalog.scenes.firstWhere((scene) => scene.isVideo);
    final video = Player();
    final videoController = VideoController(video);
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SceneBackground(
          preview: AssetImage(scene.preview),
          desktop: true,
          video: videoController,
        ),
      ),
    );
    final videoErrors = <String>[];
    final videoSubscription = video.stream.error.listen(videoErrors.add);
    try {
      await videoController.platform.future.timeout(
        const Duration(seconds: 15),
      );
      await video.setVolume(0);
      await video.setPlaylistMode(PlaylistMode.loop);
      final decoded = await Future.wait<Object?>([
        video.stream.width.firstWhere((width) => width != null && width > 0),
        video.stream.height.firstWhere(
          (height) => height != null && height > 0,
        ),
        video.open(Media('asset:///${scene.asset}')),
      ]).timeout(const Duration(seconds: 15));
      await videoController.waitUntilFirstFrameRendered.timeout(
        const Duration(seconds: 15),
      );
      await video.stream.position
          .firstWhere((position) => position.inMilliseconds > 3000)
          .timeout(const Duration(seconds: 10));
      final wrapped = await video.stream.position
          .firstWhere((position) => position.inMilliseconds < 1000)
          .timeout(const Duration(seconds: 10));
      if (videoErrors.isNotEmpty) {
        throw StateError('Video playback failed: $videoErrors');
      }
      result['video'] = {
        'asset': scene.asset,
        'width': decoded[0],
        'height': decoded[1],
        'loopPositionMs': wrapped.inMilliseconds,
        'firstFrameRendered': true,
      };
    } finally {
      await videoSubscription.cancel();
      await video.dispose();
    }
    result['passed'] = true;
    await File(
      resultPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
    exit(0);
  } catch (error, stack) {
    result['passed'] = false;
    result['error'] = '$error';
    result['stack'] = '$stack';
    await File(
      resultPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
    exit(1);
  }
}
