import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FocusPhase { focus, shortBreak, longBreak }

extension FocusPhaseLabel on FocusPhase {
  String get label => switch (this) {
    FocusPhase.focus => '专注',
    FocusPhase.shortBreak => '短休息',
    FocusPhase.longBreak => '长休息',
  };
}

enum AmbientSound { rain, forest, ocean }

extension AmbientSoundLabel on AmbientSound {
  String get label => switch (this) {
    AmbientSound.rain => '细雨',
    AmbientSound.forest => '林间风',
    AmbientSound.ocean => '海浪',
  };
}

class FocusSettings {
  const FocusSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sceneId = 'study',
    this.sound = AmbientSound.rain,
    this.soundEnabled = false,
    this.volume = 0.35,
    this.customBackgroundPath,
    this.customBackgroundIsVideo = false,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final String sceneId;
  final AmbientSound sound;
  final bool soundEnabled;
  final double volume;
  final String? customBackgroundPath;
  final bool customBackgroundIsVideo;

  int minutesFor(FocusPhase phase) => switch (phase) {
    FocusPhase.focus => focusMinutes,
    FocusPhase.shortBreak => shortBreakMinutes,
    FocusPhase.longBreak => longBreakMinutes,
  };

  FocusSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    String? sceneId,
    AmbientSound? sound,
    bool? soundEnabled,
    double? volume,
    String? customBackgroundPath,
    bool? customBackgroundIsVideo,
    bool clearCustomBackground = false,
  }) => FocusSettings(
    focusMinutes: focusMinutes ?? this.focusMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    sceneId: sceneId ?? this.sceneId,
    sound: sound ?? this.sound,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    volume: volume ?? this.volume,
    customBackgroundPath: clearCustomBackground
        ? null
        : customBackgroundPath ?? this.customBackgroundPath,
    customBackgroundIsVideo:
        customBackgroundIsVideo ?? this.customBackgroundIsVideo,
  );

  Map<String, Object?> toJson() => {
    'focusMinutes': focusMinutes,
    'shortBreakMinutes': shortBreakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'sceneId': sceneId,
    'sound': sound.name,
    'soundEnabled': soundEnabled,
    'volume': volume,
    'customBackgroundPath': customBackgroundPath,
    'customBackgroundIsVideo': customBackgroundIsVideo,
  };

  factory FocusSettings.fromJson(Map<String, dynamic> json) => FocusSettings(
    focusMinutes: (json['focusMinutes'] as int?) ?? 25,
    shortBreakMinutes: (json['shortBreakMinutes'] as int?) ?? 5,
    longBreakMinutes: (json['longBreakMinutes'] as int?) ?? 15,
    sceneId: json['sceneId'] as String? ?? 'study',
    sound: AmbientSound.values.byName(json['sound'] as String? ?? 'rain'),
    soundEnabled: json['soundEnabled'] as bool? ?? false,
    volume: (json['volume'] as num?)?.toDouble() ?? 0.35,
    customBackgroundPath: json['customBackgroundPath'] as String?,
    customBackgroundIsVideo: json['customBackgroundIsVideo'] as bool? ?? false,
  );
}

class FocusSpan {
  const FocusSpan(this.start, this.end);
  final DateTime start;
  final DateTime end;

  Map<String, Object?> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
  factory FocusSpan.fromJson(Map<String, dynamic> json) => FocusSpan(
    DateTime.parse(json['start'] as String),
    DateTime.parse(json['end'] as String),
  );
}

class FocusEntry {
  const FocusEntry({
    required this.startedAt,
    required this.endedAt,
    required this.seconds,
    required this.completed,
    required this.spans,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int seconds;
  final bool completed;
  final List<FocusSpan> spans;

  Map<String, Object?> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'seconds': seconds,
    'completed': completed,
    'spans': spans.map((span) => span.toJson()).toList(),
  };

  factory FocusEntry.fromJson(Map<String, dynamic> json) => FocusEntry(
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    seconds: json['seconds'] as int,
    completed: json['completed'] as bool,
    spans: (json['spans'] as List<dynamic>)
        .map((span) => FocusSpan.fromJson(span as Map<String, dynamic>))
        .toList(),
  );
}

abstract class FocusStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> snapshot);
}

class PreferencesFocusStore implements FocusStore {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const _key = 'naiwa_moment_state_v1';

  @override
  Future<Map<String, dynamic>?> read() async {
    final encoded = await _preferences.getString(_key);
    return encoded == null ? null : jsonDecode(encoded) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> snapshot) =>
      _preferences.setString(_key, jsonEncode(snapshot));
}

class FocusController extends ChangeNotifier {
  FocusController({required this.store, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final FocusStore store;
  final DateTime Function() _clock;
  FocusSettings settings = const FocusSettings();
  FocusPhase phase = FocusPhase.focus;
  final List<FocusEntry> _history = [];
  List<FocusEntry> get history => List.unmodifiable(_history);
  Duration _elapsed = Duration.zero;
  DateTime? _runStartedAt;
  DateTime? _cycleStartedAt;
  final List<FocusSpan> _spans = [];
  Timer? _ticker;
  Future<void> _saveQueue = Future<void>.value();
  bool _disposed = false;
  String? persistenceError;
  int completionSerial = 0;
  int _completedInRound = 0;

  bool get isRunning => _runStartedAt != null;
  DateTime get now => _clock();
  Duration get duration => Duration(minutes: settings.minutesFor(phase));
  Duration get elapsed {
    final extra = _runStartedAt == null
        ? Duration.zero
        : _clock().difference(_runStartedAt!);
    final ms = (_elapsed + extra).inMilliseconds.clamp(
      0,
      duration.inMilliseconds,
    );
    return Duration(milliseconds: ms);
  }

  int get remainingSeconds =>
      ((duration - elapsed).inMilliseconds / 1000).ceil();
  double get progress => elapsed.inMilliseconds / duration.inMilliseconds;
  String get timeLabel {
    final seconds = remainingSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  int get completedInRound => _completedInRound;

  Future<void> load() async {
    final snapshot = await store.read();
    if (snapshot != null) {
      settings = FocusSettings.fromJson(
        snapshot['settings'] as Map<String, dynamic>,
      );
      phase = FocusPhase.values.byName(snapshot['phase'] as String);
      _elapsed = Duration(milliseconds: snapshot['elapsedMs'] as int);
      _cycleStartedAt = snapshot['cycleStartedAt'] == null
          ? null
          : DateTime.parse(snapshot['cycleStartedAt'] as String);
      _completedInRound = snapshot['completedInRound'] as int? ?? 0;
      _spans.addAll(
        (snapshot['spans'] as List<dynamic>).map(
          (item) => FocusSpan.fromJson(item as Map<String, dynamic>),
        ),
      );
      _history.addAll(
        (snapshot['history'] as List<dynamic>).map(
          (item) => FocusEntry.fromJson(item as Map<String, dynamic>),
        ),
      );
      if (snapshot['runStartedAt'] != null) {
        _runStartedAt = DateTime.parse(snapshot['runStartedAt'] as String);
      }
    }
    tick();
    notifyListeners();
  }

  void attachTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void toggleRunning() {
    tick();
    if (isRunning) {
      _spans.add(FocusSpan(_runStartedAt!, _clock()));
      _elapsed = elapsed;
      _runStartedAt = null;
    } else {
      _cycleStartedAt ??= _clock();
      _runStartedAt = _clock();
    }
    unawaited(save());
    notifyListeners();
  }

  void tick() {
    if (!isRunning) return;
    if (elapsed >= duration) {
      final endedAt = _runStartedAt!.add(duration - _elapsed);
      if (phase == FocusPhase.focus) {
        _recordFocus(endedAt: endedAt, completed: true);
        _completedInRound++;
        phase = _completedInRound >= 4
            ? FocusPhase.longBreak
            : FocusPhase.shortBreak;
      } else {
        if (phase == FocusPhase.longBreak) _completedInRound = 0;
        phase = FocusPhase.focus;
      }
      _elapsed = Duration.zero;
      _runStartedAt = null;
      _cycleStartedAt = null;
      _spans.clear();
      completionSerial++;
      unawaited(save());
    }
    notifyListeners();
  }

  void _recordFocus({required DateTime endedAt, required bool completed}) {
    if (phase != FocusPhase.focus || _cycleStartedAt == null) return;
    final seconds = elapsed.inSeconds;
    if (seconds == 0) return;
    final entry = FocusEntry(
      startedAt: _cycleStartedAt!,
      endedAt: endedAt,
      seconds: seconds,
      completed: completed,
      spans: _currentSpans(endedAt),
    );
    _history.removeWhere((item) => item.startedAt == entry.startedAt);
    _history.add(entry);
  }

  void reset({FocusPhase? nextPhase}) {
    tick();
    _recordFocus(endedAt: _clock(), completed: false);
    phase = nextPhase ?? phase;
    _elapsed = Duration.zero;
    _runStartedAt = null;
    _cycleStartedAt = null;
    _spans.clear();
    unawaited(save());
    notifyListeners();
  }

  void updateSettings(FocusSettings next) {
    final timingChanged =
        settings.focusMinutes != next.focusMinutes ||
        settings.shortBreakMinutes != next.shortBreakMinutes ||
        settings.longBreakMinutes != next.longBreakMinutes;
    if (timingChanged) reset();
    settings = next;
    unawaited(save());
    notifyListeners();
  }

  int secondsOn(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day + 1);
    final spans = [for (final entry in _history) ...entry.spans];
    if (phase == FocusPhase.focus && _cycleStartedAt != null) {
      spans.addAll(
        _currentSpans(
          isRunning ? _runStartedAt!.add(duration - _elapsed) : _clock(),
        ),
      );
    }
    var milliseconds = 0;
    for (final span in spans) {
      final left = span.start.isAfter(start) ? span.start : start;
      final right = span.end.isBefore(end) ? span.end : end;
      if (right.isAfter(left)) {
        milliseconds += right.difference(left).inMilliseconds;
      }
    }
    return milliseconds ~/ 1000;
  }

  List<FocusSpan> _currentSpans(DateTime endedAt) => [
    ..._spans,
    if (_runStartedAt != null)
      FocusSpan(
        _runStartedAt!,
        endedAt.isBefore(_clock()) ? endedAt : _clock(),
      ),
  ];

  int completedOn(DateTime date) => _history
      .where(
        (entry) =>
            entry.completed &&
            entry.endedAt.year == date.year &&
            entry.endedAt.month == date.month &&
            entry.endedAt.day == date.day,
      )
      .length;

  Future<void> save() {
    final snapshot = <String, dynamic>{
      'schema': 1,
      'settings': settings.toJson(),
      'phase': phase.name,
      'elapsedMs': _elapsed.inMilliseconds,
      'runStartedAt': _runStartedAt?.toIso8601String(),
      'savedAt': _clock().toIso8601String(),
      'cycleStartedAt': _cycleStartedAt?.toIso8601String(),
      'completedInRound': _completedInRound,
      'spans': _spans.map((span) => span.toJson()).toList(),
      'history': _history.map((entry) => entry.toJson()).toList(),
    };
    _saveQueue = _saveQueue.then((_) async {
      try {
        await store.write(snapshot);
        persistenceError = null;
      } catch (error) {
        persistenceError = '保存失败：$error';
        if (!_disposed) notifyListeners();
      }
    });
    return _saveQueue;
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
