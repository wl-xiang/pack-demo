import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dice_roll/history/history_store.dart';
import 'package:dice_roll/models/dice_record.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('HistoryStore', () {
    test('空数据返回空列表', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = HistoryStore(prefs);
      expect(store.load(), isEmpty);
    });

    test('save / load 往返一致', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = HistoryStore(prefs);
      final records = [
        DiceRecord(
          id: 'a',
          values: const [6],
          timestamp: DateTime(2026, 8, 20, 9, 30),
        ),
        DiceRecord(
          id: 'b',
          values: const [2, 3, 5],
          timestamp: DateTime(2026, 8, 21, 18, 45),
        ),
      ];
      await store.save(records);
      final loaded = store.load();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'a');
      expect(loaded[0].values, [6]);
      expect(loaded[1].sum, 10);
    });

    test('损坏的 JSON 返回空列表而不抛异常', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dice_roll.history.v1', '{broken json');
      final store = HistoryStore(prefs);
      expect(store.load(), isEmpty);
    });

    test('非 List 的 JSON 返回空列表', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dice_roll.history.v1', '"just a string"');
      final store = HistoryStore(prefs);
      expect(store.load(), isEmpty);
    });

    test('跳过无效条目，保留有效条目', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'dice_roll.history.v1',
        '[{"id":"good","values":[3],"timestamp":"2026-08-21T10:00:00.000"},'
            '{"id":"","values":[1],"timestamp":"2026-08-21T10:00:00.000"},'
            '"garbage-entry"]',
      );
      final store = HistoryStore(prefs);
      final loaded = store.load();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'good');
    });
  });
}
