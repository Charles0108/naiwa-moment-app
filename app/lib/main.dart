import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/focus_controller.dart';
import 'media/media_hub.dart';
import 'native_smoke.dart';
import 'ui/moment_app.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (arguments.contains('--smoke-test')) {
    final resultArgument = arguments.firstWhere(
      (value) => value.startsWith('--smoke-result='),
    );
    await runNativeSmoke(resultArgument.substring('--smoke-result='.length));
    return;
  }
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 820),
        minimumSize: Size(460, 600),
        center: true,
        title: '奶娃片刻',
        backgroundColor: Color(0xFFEBF0E5),
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
  final controller = FocusController(store: PreferencesFocusStore());
  final androidEmulator =
      Platform.isAndroid &&
      await const MethodChannel(
            'com.alexmercerind/media_kit_video',
          ).invokeMethod<bool>('Utils.IsEmulator') ==
          true;
  String? loadError;
  try {
    await controller.load();
  } catch (error) {
    loadError = '无法读取本地记录：$error';
  }
  controller.attachTicker();
  runApp(
    MomentApp(
      controller: controller,
      media: MediaHub(androidEmulator: androidEmulator),
      loadError: loadError,
    ),
  );
}
