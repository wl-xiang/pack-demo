import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dice_roll/controller/app_controller.dart';
import 'package:dice_roll/history/history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AppController> createController() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AppController(prefs);
    await controller.load();
    return controller;
  }

  group('AppController', () {
    test('初始状态', () async {
      final controller = await createController();
      expect(controller.records, isEmpty);
      expect(controller.diceCount, 1);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.hasRecords, isFalse);
    });

    test('addRecord 插入到最前并持久化', () async {
      final controller = await createController();
      await controller.addRecord(const [3]);
      await controller.addRecord(const [4, 2]);

      expect(controller.recordCount, 2);
      expect(controller.records.first.sum, 6);
      expect(controller.records.last.sum, 3);

      // 重新加载验证持久化
      final prefs = await SharedPreferences.getInstance();
      final restored = AppController(prefs);
      await restored.load();
      expect(restored.recordCount, 2);
      expect(restored.records.first.values, [4, 2]);
    });

    test('记录条数上限为 200，超出丢弃最旧记录', () async {
      final controller = await createController();
      for (var i = 0; i < 205; i++) {
        await controller.addRecord(const [1]);
      }
      expect(controller.recordCount, HistoryStore.maxRecords);
      expect(controller.records.length, 200);
    });

    test('removeRecord / restoreRecord / clearAll', () async {
      final controller = await createController();
      await controller.addRecord(const [1]);
      await controller.addRecord(const [2]);
      await controller.addRecord(const [3]);
      final removed = controller.records[1];

      await controller.removeRecord(removed.id);
      expect(controller.recordCount, 2);
      expect(controller.records.contains(removed), isFalse);

      await controller.restoreRecord(removed, 1);
      expect(controller.recordCount, 3);
      expect(controller.records[1].id, removed.id);

      await controller.clearAll();
      expect(controller.recordCount, 0);
      expect(controller.hasRecords, isFalse);
    });

    test('setDiceCount 持久化并夹紧范围', () async {
      final controller = await createController();
      await controller.setDiceCount(5);
      expect(controller.diceCount, 5);

      await controller.setDiceCount(99);
      expect(controller.diceCount, AppController.maxDiceCount);
      await controller.setDiceCount(0);
      expect(controller.diceCount, AppController.minDiceCount);

      final prefs = await SharedPreferences.getInstance();
      final restored = AppController(prefs);
      await restored.load();
      expect(restored.diceCount, 1);
    });

    test('损坏的骰子数量被夹紧到合法范围', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dice_roll.diceCount': 42,
      });
      final controller = await createController();
      expect(controller.diceCount, AppController.maxDiceCount);
    });

    test('cycleThemeMode 循环切换并持久化', () async {
      final controller = await createController();
      expect(controller.themeMode, ThemeMode.system);

      controller.cycleThemeMode();
      expect(controller.themeMode, ThemeMode.light);
      controller.cycleThemeMode();
      expect(controller.themeMode, ThemeMode.dark);
      controller.cycleThemeMode();
      expect(controller.themeMode, ThemeMode.system);

      controller.cycleThemeMode();
      final prefs = await SharedPreferences.getInstance();
      final restored = AppController(prefs);
      await restored.load();
      expect(restored.themeMode, ThemeMode.light);
    });

    test('持久化的主题模式被正确恢复', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'dice_roll.themeMode': 'dark',
      });
      final controller = await createController();
      expect(controller.themeMode, ThemeMode.dark);
    });
  });
}
