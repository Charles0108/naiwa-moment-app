import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../core/focus_controller.dart';
import '../core/scene_catalog.dart';

class MediaHub extends ChangeNotifier {
  MediaHub() {
    videoController = VideoController(_video);
    _ambient.stream.error.listen(_onError);
    _video.stream.error.listen(_onError);
    _cue.stream.error.listen(_onError);
  }

  final Player _ambient = Player();
  final Player _video = Player();
  final Player _cue = Player();
  late final VideoController videoController;
  AmbientSound? _sound;
  String? _videoPath;
  bool videoReady = false;
  String? error;
  bool _disposed = false;
  Future<void> _queue = Future<void>.value();

  void _onError(String value) {
    error = value;
    if (!_disposed) notifyListeners();
  }

  Future<void> sync(FocusSettings settings) {
    _queue = _queue.then((_) => _apply(settings)).catchError((Object failure) {
      _onError(failure.toString());
    });
    return _queue;
  }

  Future<void> _apply(FocusSettings settings) async {
    if (_disposed) return;
    await _ambient.setVolume(settings.volume * 100);
    if (settings.soundEnabled) {
      if (_sound != settings.sound) {
        _sound = settings.sound;
        await _ambient.setPlaylistMode(PlaylistMode.loop);
        await _ambient.open(
          Media('asset:///assets/audio/${settings.sound.name}.wav'),
        );
      } else {
        await _ambient.play();
      }
    } else {
      await _ambient.pause();
    }
    final preset = SceneCatalog.byId(settings.sceneId);
    final nextPath = settings.customBackgroundPath != null
        ? (settings.customBackgroundIsVideo
              ? settings.customBackgroundPath
              : null)
        : (preset.isVideo ? 'asset:///${preset.asset}' : null);
    if (_videoPath != nextPath) {
      _videoPath = nextPath;
      videoReady = false;
      await _video.stop();
      if (nextPath != null) {
        if (!nextPath.startsWith('asset:///') &&
            !await File(nextPath).exists()) {
          throw FileSystemException('背景视频文件无法读取', nextPath);
        }
        await _video.setVolume(0);
        await _video.setPlaylistMode(PlaylistMode.loop);
        await _video.open(Media(nextPath));
        videoReady = true;
      }
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> playCue() async {
    await _cue.setVolume(45);
    await _cue.open(Media('asset:///assets/audio/cue.wav'));
  }

  Future<({String path, bool video})?> importBackground() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov', 'm4v'],
      dialogTitle: '选择一张画面，或一段安静的循环视频',
    );
    if (result == null || result.path == null) return null;
    final source = File(result.path!);
    final extension = (result.extension ?? source.path.split('.').last)
        .toLowerCase();
    final directory = await getApplicationSupportDirectory();
    final target = File(
      '${directory.path}/scenes/scene-${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return (
      path: target.path,
      video: ['mp4', 'mov', 'm4v'].contains(extension),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.then((_) async {
      await _ambient.dispose();
      await _video.dispose();
      await _cue.dispose();
    });
    super.dispose();
  }
}
