import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../core/focus_controller.dart';
import '../core/scene_catalog.dart';
import '../media/media_hub.dart';
import 'scene_background.dart';

const _green = Color(0xFF3C6050);

class MomentApp extends StatefulWidget {
  const MomentApp({
    super.key,
    required this.controller,
    this.media,
    this.loadError,
  });
  final FocusController controller;
  final MediaHub? media;
  final String? loadError;

  @override
  State<MomentApp> createState() => _MomentAppState();
}

class _MomentAppState extends State<MomentApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.tick();
    unawaited(widget.controller.save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.media?.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '奶娃片刻',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
      scaffoldBackgroundColor: const Color(0xFFF7F8F3),
      fontFamily: 'Microsoft YaHei UI',
      fontFamilyFallback: const [
        'PingFang SC',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFFF9FAF5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
    ),
    home: MomentHome(
      controller: widget.controller,
      media: widget.media,
      loadError: widget.loadError,
    ),
  );
}

class _ToggleTimerIntent extends Intent {
  const _ToggleTimerIntent();
}

class _ExitFullScreenIntent extends Intent {
  const _ExitFullScreenIntent();
}

class MomentHome extends StatefulWidget {
  const MomentHome({
    super.key,
    required this.controller,
    this.media,
    this.loadError,
  });
  final FocusController controller;
  final MediaHub? media;
  final String? loadError;

  @override
  State<MomentHome> createState() => _MomentHomeState();
}

class _MomentHomeState extends State<MomentHome> {
  FocusController get timer => widget.controller;
  bool _fullScreen = false;
  FocusSettings? _lastSettings;
  int _lastCompletion = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _lastCompletion = timer.completionSerial;
    timer.addListener(_controllerChanged);
    widget.media?.addListener(_mediaChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.loadError != null) _showMessage(widget.loadError!);
      _controllerChanged();
    });
  }

  void _controllerChanged() {
    if (!mounted) return;
    if (_lastSettings != timer.settings) {
      _lastSettings = timer.settings;
      unawaited(widget.media?.sync(timer.settings));
    }
    if (_lastCompletion != timer.completionSerial) {
      _lastCompletion = timer.completionSerial;
      unawaited(widget.media?.playCue());
      _showMessage(
        timer.phase == FocusPhase.focus
            ? '休息结束，准备好再开始。'
            : '这一刻完成了。${timer.phase.label}一下吧。',
      );
    }
    if (timer.persistenceError != null &&
        _lastError != timer.persistenceError) {
      _lastError = timer.persistenceError;
      _showMessage(timer.persistenceError!);
    }
    setState(() {});
  }

  void _mediaChanged() {
    if (!mounted) return;
    if (widget.media?.error != null && _lastError != widget.media?.error) {
      _lastError = widget.media?.error;
      _showMessage('声音或背景无法播放：${widget.media!.error}');
    }
    setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleFullScreen({bool? value}) async {
    final fullScreen = value ?? !_fullScreen;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.setFullScreen(fullScreen);
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        fullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    }
    if (mounted) setState(() => _fullScreen = fullScreen);
  }

  @override
  void dispose() {
    timer.removeListener(_controllerChanged);
    widget.media?.removeListener(_mediaChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = timer.settings;
    final preset = SceneCatalog.byId(settings.sceneId);
    const ink = Color(0xFFF6F6EA);
    final faint = ink.withValues(alpha: .64);
    final background = settings.customBackgroundPath;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.space): _ToggleTimerIntent(),
        SingleActivator(LogicalKeyboardKey.escape): _ExitFullScreenIntent(),
      },
      child: Actions(
        actions: {
          _ToggleTimerIntent: CallbackAction<_ToggleTimerIntent>(
            onInvoke: (_) {
              timer.toggleRunning();
              return null;
            },
          ),
          _ExitFullScreenIntent: CallbackAction<_ExitFullScreenIntent>(
            onInvoke: (_) {
              if (_fullScreen) unawaited(_toggleFullScreen(value: false));
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF20382F)),
                SceneBackground(
                  preview:
                      background != null && !settings.customBackgroundIsVideo
                      ? FileImage(File(background))
                      : AssetImage(preset.preview),
                  desktop:
                      Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux,
                  video:
                      (background == null
                              ? preset.isVideo
                              : settings.customBackgroundIsVideo) &&
                          widget.media?.videoReady == true
                      ? widget.media!.videoController
                      : null,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x8820312C),
                        Color(0x4420312C),
                        Color(0x8820312C),
                      ],
                      stops: [0, .45, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 600;
                      final short = constraints.maxHeight < 620;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 20 : 48,
                          short
                              ? 16
                              : compact
                              ? 22
                              : 32,
                          compact ? 20 : 48,
                          short
                              ? 16
                              : compact
                              ? 24
                              : 32,
                        ),
                        child: Column(
                          children: [
                            _header(ink, compact || short),
                            const Spacer(flex: 3),
                            _phaseSelector(ink),
                            SizedBox(height: short ? 8 : 20),
                            if (!short) ...[
                              Text(
                                timer.isRunning ? '把这一刻，留给眼前。' : '和奶娃一起，慢慢来。',
                                style: TextStyle(
                                  color: faint,
                                  fontSize: compact ? 13 : 15,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              timer.timeLabel,
                              key: const Key('countdown'),
                              style: TextStyle(
                                color: ink,
                                fontFamily: 'Arial',
                                fontSize: math.min(
                                  math.min(
                                    constraints.maxWidth * .23,
                                    constraints.maxHeight * (short ? .19 : .23),
                                  ),
                                  124,
                                ),
                                fontWeight: FontWeight.w300,
                                letterSpacing: -5,
                                height: 1.2,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x8820312C),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            SizedBox(height: short ? 8 : 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilledButton.icon(
                                  key: const Key('toggle-timer'),
                                  onPressed: timer.toggleRunning,
                                  icon: Icon(
                                    timer.isRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 22,
                                  ),
                                  label: Text(
                                    timer.isRunning ? '暂停片刻' : '开始这一刻',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE4EBDD),
                                    foregroundColor: _green,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: short ? 12 : 17,
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Microsoft YaHei UI',
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _roundButton(
                                  Icons.replay_rounded,
                                  '重新计时',
                                  ink,
                                  () => timer.reset(),
                                ),
                              ],
                            ),
                            if (!short) ...[
                              const SizedBox(height: 23),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < 4; i++)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ink.withValues(
                                          alpha: i < timer.completedInRound
                                              ? .72
                                              : .20,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '四个片刻，一次长休息',
                                    style: TextStyle(
                                      color: faint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(flex: 4),
                            _sceneSelector(ink),
                            if (!short) ...[
                              const SizedBox(height: 14),
                              Text(
                                background == null
                                    ? preset.caption
                                    : '眼前的风景，是自己的片刻。',
                                style: TextStyle(
                                  color: faint,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(Color ink, bool compact) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '奶娃片刻',
              style: TextStyle(
                color: ink,
                fontSize: compact ? 20 : 25,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              Text(
                'A LITTLE MOMENT, JUST FOR YOU',
                style: TextStyle(
                  color: ink.withValues(alpha: .5),
                  fontSize: 9,
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ],
        ),
      ),
      _roundButton(
        timer.settings.soundEnabled
            ? Icons.headphones_rounded
            : Icons.headphones_outlined,
        '白噪声',
        ink,
        _soundPanel,
      ),
      const SizedBox(width: 4),
      _roundButton(Icons.bar_chart_rounded, '专注统计', ink, _statsPanel),
      const SizedBox(width: 4),
      _roundButton(Icons.tune_rounded, '计时设置', ink, _settingsPanel),
      const SizedBox(width: 4),
      _roundButton(
        _fullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        '全屏',
        ink,
        () => unawaited(_toggleFullScreen()),
      ),
    ],
  );

  Widget _roundButton(
    IconData icon,
    String label,
    Color ink,
    VoidCallback onPressed,
  ) => IconButton(
    onPressed: onPressed,
    tooltip: label,
    constraints: const BoxConstraints.tightFor(width: 38, height: 38),
    style: IconButton.styleFrom(backgroundColor: ink.withValues(alpha: .07)),
    icon: Icon(icon, color: ink, size: 20),
  );

  Widget _phaseSelector(Color ink) => _glass(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final phase in FocusPhase.values)
          InkWell(
            key: Key('phase-${phase.name}'),
            onTap: () {
              if (timer.phase != phase) timer.reset(nextPhase: phase);
            },
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: timer.phase == phase
                    ? ink.withValues(alpha: .12)
                    : Colors.transparent,
              ),
              child: Text(
                phase.label,
                style: TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: timer.phase == phase
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _sceneSelector(Color ink) => _glass(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _scenePanel,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Tooltip(
              message: '切换场景',
              child: Row(
                children: [
                  Icon(Icons.landscape_outlined, color: ink, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    timer.settings.customBackgroundPath == null
                        ? SceneCatalog.byId(timer.settings.sceneId).label
                        : '我的场景',
                    style: TextStyle(color: ink, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.expand_more_rounded, color: ink, size: 17),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.media == null ? null : _importBackground,
          tooltip: '导入图片或视频',
          icon: Icon(Icons.add_photo_alternate_outlined, color: ink, size: 18),
        ),
      ],
    ),
  );

  Future<void> _scenePanel() => showDialog<void>(
    context: context,
    builder: (context) => _panel(
      title: '换一片风景',
      width: 720,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                '素材致谢：B站 UP主 防御老猫\n奶娃视频及静帧选自「【奶娃】“悲观人生”」。感谢创作者带来的这些画面。',
                style: TextStyle(color: _green, fontSize: 12, height: 1.7),
              ),
            ),
            for (final video in [true, false]) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  video ? '自然微动' : '静态画面',
                  style: const TextStyle(color: _green, fontSize: 13),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth > 580 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  for (final scene in SceneCatalog.scenes.where(
                    (scene) => scene.isVideo == video,
                  ))
                    InkWell(
                      key: Key('scene-${scene.id}'),
                      onTap: () {
                        timer.updateSettings(
                          timer.settings.copyWith(
                            sceneId: scene.id,
                            clearCustomBackground: true,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              scene.preview,
                              fit: BoxFit.cover,
                              cacheWidth: 420,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xAA172C26),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Text(
                                scene.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (timer.settings.sceneId == scene.id &&
                                timer.settings.customBackgroundPath == null)
                              const Positioned(
                                top: 10,
                                right: 10,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            if (scene.isVideo)
                              const Positioned(
                                top: 10,
                                left: 10,
                                child: Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _glass({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(32),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          border: Border.all(color: Colors.white.withValues(alpha: .15)),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(padding: const EdgeInsets.all(4), child: child),
      ),
    ),
  );

  Future<void> _importBackground() async {
    try {
      final background = await widget.media!.importBackground();
      if (background == null || !mounted) return;
      timer.updateSettings(
        timer.settings.copyWith(
          customBackgroundPath: background.path,
          customBackgroundIsVideo: background.video,
        ),
      );
    } catch (error) {
      _showMessage('无法导入这段画面：$error');
    }
  }

  Future<void> _soundPanel() => showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, refresh) => _panel(
        title: '给片刻一点声音',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('环境白噪声'),
              value: timer.settings.soundEnabled,
              onChanged: (value) {
                timer.updateSettings(
                  timer.settings.copyWith(soundEnabled: value),
                );
                refresh(() {});
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                for (final sound in AmbientSound.values)
                  ChoiceChip(
                    label: Text(sound.label),
                    selected: timer.settings.sound == sound,
                    onSelected: (_) {
                      timer.updateSettings(
                        timer.settings.copyWith(
                          sound: sound,
                          soundEnabled: true,
                        ),
                      );
                      refresh(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                const Icon(Icons.volume_down_rounded, color: _green),
                Expanded(
                  child: Slider(
                    value: timer.settings.volume,
                    onChanged: (value) {
                      timer.updateSettings(
                        timer.settings.copyWith(volume: value),
                      );
                      refresh(() {});
                    },
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: _green),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '内置声音离线播放。背景视频默认静音。',
              style: TextStyle(fontSize: 12, color: Color(0xFF778578)),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _statsPanel() => showDialog<void>(
    context: context,
    builder: (context) {
      final today = timer.now;
      final days = List.generate(
        7,
        (i) => DateTime(today.year, today.month, today.day - 6 + i),
      );
      final values = days.map(timer.secondsOn).toList();
      final maxSeconds = math.max(60, values.reduce(math.max));
      final total =
          timer.history.fold<int>(0, (sum, item) => sum + item.seconds) +
          (timer.phase == FocusPhase.focus ? timer.elapsed.inSeconds : 0);
      return _panel(
        title: '每一个片刻，都算数',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _stat('${timer.secondsOn(today) ~/ 60}', '今日专注 · 分钟'),
                ),
                Expanded(
                  child: _stat('${timer.completedOn(today)}', '今日完成 · 片刻'),
                ),
                Expanded(child: _stat('${total ~/ 60}', '累计 · 分钟')),
              ],
            ),
            const SizedBox(height: 30),
            const Text('最近七天', style: TextStyle(fontSize: 13, color: _green)),
            const SizedBox(height: 18),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${values[i] ~/ 60}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: math.max(4, values[i] / maxSeconds * 106),
                              width: 24,
                              decoration: BoxDecoration(
                                color: i == 6
                                    ? _green
                                    : const Color(0xFFBDCDC0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              i == 6 ? '今天' : '${days[i].month}/${days[i].day}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF778578),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _stat(String number, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        style: const TextStyle(
          fontSize: 30,
          color: _green,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF778578)),
      ),
    ],
  );

  Future<void> _settingsPanel() async {
    final fields = [
      TextEditingController(text: '${timer.settings.focusMinutes}'),
      TextEditingController(text: '${timer.settings.shortBreakMinutes}'),
      TextEditingController(text: '${timer.settings.longBreakMinutes}'),
    ];
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (context) => _panel(
        title: '按自己的节奏',
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < fields.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: fields[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: FocusPhase.values[i].label,
                      suffixText: '分钟',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (text) {
                      final number = int.tryParse(text ?? '');
                      return number == null || number < 1 || number > 180
                          ? '请输入 1–180 分钟'
                          : null;
                    },
                  ),
                ),
              const Text(
                '修改时长会重置当前计时，已专注的时间仍会保留。',
                style: TextStyle(fontSize: 12, color: Color(0xFF778578)),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!form.currentState!.validate()) return;
                    timer.updateSettings(
                      timer.settings.copyWith(
                        focusMinutes: int.parse(fields[0].text),
                        shortBreakMinutes: int.parse(fields[1].text),
                        longBreakMinutes: int.parse(fields[2].text),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('保存节奏'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (final field in fields) {
      field.dispose();
    }
  }

  Widget _panel({
    required String title,
    required Widget child,
    double width = 460,
  }) => Dialog(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: '关闭',
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
