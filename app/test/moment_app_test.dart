import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naiwa_moment/core/focus_controller.dart';
import 'package:naiwa_moment/ui/moment_app.dart';
import 'package:naiwa_moment/ui/scene_background.dart';

import 'focus_controller_test.dart' show MemoryFocusStore;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final windowsDirectory = Platform.environment['WINDIR'];
    for (final font in <String, String>{
      if (windowsDirectory != null) ...{
        'Microsoft YaHei UI': '$windowsDirectory/Fonts/msyh.ttc',
        'Arial': '$windowsDirectory/Fonts/arial.ttf',
      },
    }.entries) {
      final file = File(font.value);
      if (await file.exists()) {
        final loader = FontLoader(font.key)
          ..addFont(
            file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final desktop in [true, false]) {
    testWidgets('scene framing for desktop=$desktop', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SceneBackground(
            preview: const AssetImage('assets/scenes/study.png'),
            desktop: desktop,
          ),
        ),
      );
      final foreground = tester.widget<Image>(
        find.byKey(const Key('scene-foreground')),
      );
      expect(foreground.fit, desktop ? BoxFit.contain : BoxFit.cover);
      expect(
        find.byKey(const Key('scene-blurred-fill')),
        desktop ? findsOneWidget : findsNothing,
      );
      if (desktop) {
        final fill = tester.widget<Image>(
          find.byKey(const Key('scene-blurred-fill')),
        );
        expect(fill.fit, BoxFit.cover);
        expect(fill.image, foreground.image);
        expect(find.byType(ImageFiltered), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final size in [
    const Size(1280, 820),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('responsive controls and dialogs at ${size.width} pixels', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = FocusController(store: MemoryFocusStore());
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MomentApp(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/scenes/study.png'),
          tester.element(find.byType(MomentHome)),
        ),
      );
      await tester.pump();
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../work/preview-${size.width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.byKey(const Key('toggle-timer')));
      await tester.pump();
      expect(find.text('暂停片刻'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle-timer')));
      await tester.pump();
      expect(find.text('开始这一刻'), findsOneWidget);
      await tester.tap(find.byKey(const Key('phase-shortBreak')));
      await tester.pump();
      expect(find.text('05:00'), findsOneWidget);
      await tester.tap(find.byTooltip('专注统计'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('最近七天'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('计时设置'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('保存节奏'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('切换场景'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('防御老猫'), findsOneWidget);
      expect(find.textContaining('bilibili.com'), findsNothing);
      await tester.tap(find.byKey(const Key('scene-forest_steps')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.settings.sceneId, 'forest_steps');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
