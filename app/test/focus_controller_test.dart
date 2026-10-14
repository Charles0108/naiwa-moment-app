import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:naiwa_moment/core/focus_controller.dart';

class MemoryFocusStore implements FocusStore {
  Map<String, dynamic>? snapshot;
  @override
  Future<Map<String, dynamic>?> read() async => snapshot;
  @override
  Future<void> write(Map<String, dynamic> value) async {
    snapshot = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }
}

void main() {
  late DateTime now;
  late MemoryFocusStore store;
  late FocusController controller;
  setUp(() {
    now = DateTime(2026, 10, 14, 10);
    store = MemoryFocusStore();
    controller = FocusController(store: store, clock: () => now);
  });
  tearDown(() => controller.dispose());

  test('elapsed wall time survives pauses and process restart', () async {
    await controller.load();
    controller.toggleRunning();
    now = now.add(const Duration(seconds: 70));
    controller.tick();
    expect(controller.timeLabel, '23:50');
    controller.toggleRunning();
    now = now.add(const Duration(hours: 10));
    expect(controller.timeLabel, '23:50');
    controller.toggleRunning();
    now = now.add(const Duration(seconds: 40));
    await controller.save();
    final restored = FocusController(store: store, clock: () => now);
    await restored.load();
    expect(restored.timeLabel, '23:10');
    expect(restored.isRunning, isTrue);
    expect(restored.secondsOn(now), 110);
    restored.dispose();
  });

  test(
    'closing through the deadline completes only the active focus period',
    () async {
      controller.toggleRunning();
      await controller.save();
      now = now.add(const Duration(hours: 3));
      final restored = FocusController(store: store, clock: () => now);
      await restored.load();
      expect(restored.phase, FocusPhase.shortBreak);
      expect(restored.isRunning, isFalse);
      expect(restored.timeLabel, '05:00');
      expect(restored.history.single.seconds, 1500);
      expect(restored.history.single.endedAt, DateTime(2026, 10, 14, 10, 25));
      expect(restored.completedOn(now), 1);
      restored.tick();
      expect(restored.history, hasLength(1));
      restored.dispose();
    },
  );

  test('daily totals split midnight and exclude paused time', () async {
    now = DateTime(2026, 10, 14, 23, 59, 30);
    controller.toggleRunning();
    now = now.add(const Duration(seconds: 30));
    controller.toggleRunning();
    now = now.add(const Duration(minutes: 20));
    controller.toggleRunning();
    now = now.add(const Duration(seconds: 30));
    controller.reset();
    expect(controller.history.single.seconds, 60);
    expect(controller.secondsOn(DateTime(2026, 10, 14)), 30);
    expect(controller.secondsOn(DateTime(2026, 10, 15)), 30);
    expect(controller.completedOn(now), 0);
    await controller.save();
    final restored = FocusController(store: store, clock: () => now);
    await restored.load();
    expect(restored.secondsOn(DateTime(2026, 10, 14)), 30);
    expect(restored.secondsOn(DateTime(2026, 10, 15)), 30);
    restored.dispose();
  });

  test('four completed focus periods lead to a long break', () async {
    controller.updateSettings(
      const FocusSettings(
        focusMinutes: 1,
        shortBreakMinutes: 1,
        longBreakMinutes: 1,
      ),
    );
    for (var i = 0; i < 4; i++) {
      controller.toggleRunning();
      now = now.add(const Duration(minutes: 1));
      controller.tick();
      expect(
        controller.phase,
        i == 3 ? FocusPhase.longBreak : FocusPhase.shortBreak,
      );
      if (i < 3) {
        controller.toggleRunning();
        now = now.add(const Duration(minutes: 1));
        controller.tick();
        expect(controller.phase, FocusPhase.focus);
      }
    }
    expect(controller.history, hasLength(4));
    expect(controller.secondsOn(now), 240);
    controller.toggleRunning();
    now = now.add(const Duration(minutes: 1));
    controller.tick();
    expect(controller.phase, FocusPhase.focus);
    expect(controller.completedInRound, 0);
  });

  test('changing duration preserves partial focus and resets the cycle', () {
    controller.toggleRunning();
    now = now.add(const Duration(minutes: 3));
    controller.updateSettings(controller.settings.copyWith(focusMinutes: 40));
    expect(controller.timeLabel, '40:00');
    expect(controller.isRunning, isFalse);
    expect(controller.history.single.seconds, 180);
    expect(controller.secondsOn(now), 180);
  });
}
