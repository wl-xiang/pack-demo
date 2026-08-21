import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../history/history_store.dart';
import '../models/dice_record.dart';

/// 全局应用状态：历史记录、骰子数量、主题模式。
class AppController extends ChangeNotifier {
  AppController(this._prefs) : _store = HistoryStore(_prefs);

  static const String _diceCountKey = 'dice_roll.diceCount';
  static const String _themeModeKey = 'dice_roll.themeMode';

  static const int minDiceCount = 1;
  static const int maxDiceCount = 6;

  final SharedPreferences _prefs;
  final HistoryStore _store;

  /// 历史记录，最新在前。
  List<DiceRecord> records = const <DiceRecord>[];

  /// 当前骰子数量（1-6）。
  int diceCount = minDiceCount;

  /// 主题模式，默认跟随系统。
  ThemeMode themeMode = ThemeMode.system;

  int get recordCount => records.length;

  bool get hasRecords => records.isNotEmpty;

  /// 从磁盘恢复状态。在 runApp 之前调用。
  Future<void> load() async {
    records = _store.load();
    final storedCount = _prefs.getInt(_diceCountKey) ?? minDiceCount;
    diceCount = storedCount.clamp(minDiceCount, maxDiceCount);
    themeMode = _parseThemeMode(_prefs.getString(_themeModeKey));
    notifyListeners();
  }

  /// 摇骰结束后新增一条记录。
  Future<void> addRecord(List<int> values) async {
    final record = DiceRecord(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      values: List<int>.unmodifiable(values),
      timestamp: DateTime.now(),
    );
    records = <DiceRecord>[record, ...records];
    if (records.length > HistoryStore.maxRecords) {
      records = records.sublist(0, HistoryStore.maxRecords);
    }
    notifyListeners();
    await _store.save(records);
  }

  /// 删除单条记录。
  Future<void> removeRecord(String id) async {
    records = records.where((r) => r.id != id).toList();
    notifyListeners();
    await _store.save(records);
  }

  /// 恢复一条被删除的记录（撤销删除）。
  Future<void> restoreRecord(DiceRecord record, int index) async {
    final insertIndex = index.clamp(0, records.length);
    records = <DiceRecord>[...records]..insert(insertIndex, record);
    notifyListeners();
    await _store.save(records);
  }

  /// 清空全部记录。
  Future<void> clearAll() async {
    records = const <DiceRecord>[];
    notifyListeners();
    await _store.save(records);
  }

  /// 切换骰子数量。
  Future<void> setDiceCount(int value) async {
    diceCount = value.clamp(minDiceCount, maxDiceCount);
    notifyListeners();
    await _prefs.setInt(_diceCountKey, diceCount);
  }

  /// 循环切换主题：跟随系统 → 浅色 → 深色 → 跟随系统。
  void cycleThemeMode() {
    switch (themeMode) {
      case ThemeMode.system:
        themeMode = ThemeMode.light;
      case ThemeMode.light:
        themeMode = ThemeMode.dark;
      case ThemeMode.dark:
        themeMode = ThemeMode.system;
    }
    notifyListeners();
    _prefs.setString(_themeModeKey, themeMode.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
