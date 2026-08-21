import 'package:flutter_test/flutter_test.dart';
import 'package:dice_roll/models/dice_record.dart';

void main() {
  final epoch = DateTime(2026, 1, 1);

  group('DiceRecord', () {
    test('sum 与 diceCount 计算正确', () {
      final record = DiceRecord(
        id: 'r1',
        values: const [2, 5, 6],
        timestamp: epoch,
      );
      expect(record.sum, 13);
      expect(record.diceCount, 3);
    });

    test('toJson / fromJson 往返一致', () {
      final record = DiceRecord(
        id: 'r42',
        values: const [1, 4, 4, 6],
        timestamp: DateTime(2026, 8, 21, 14, 30, 25),
      );
      final restored = DiceRecord.fromJson(record.toJson());
      expect(restored.id, 'r42');
      expect(restored.values, [1, 4, 4, 6]);
      expect(restored.timestamp, record.timestamp);
      expect(restored.sum, 15);
    });

    test('fromJson 对损坏数据具有容错性', () {
      // 缺字段
      final empty = DiceRecord.fromJson(<String, dynamic>{});
      expect(empty.isValid, isFalse);
      expect(empty.values, isEmpty);

      // 非法点数被过滤
      final filtered = DiceRecord.fromJson(<String, dynamic>{
        'id': 'r7',
        'values': <dynamic>[0, 3, 9, 5, 'x'],
        'timestamp': '2026-08-21T10:00:00.000',
      });
      expect(filtered.values, [3, 5]);

      // 时间非法时回退到默认值
      final badTime = DiceRecord.fromJson(<String, dynamic>{
        'id': 'r8',
        'values': <dynamic>[2],
        'timestamp': 'not-a-date',
      });
      expect(badTime.timestamp, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('isValid 校验', () {
      final noId = DiceRecord(id: '', values: const [1], timestamp: epoch);
      final emptyValues = DiceRecord(
        id: 'r',
        values: const [],
        timestamp: epoch,
      );
      final good = DiceRecord(id: 'r', values: const [1], timestamp: epoch);
      expect(noId.isValid, isFalse);
      expect(emptyValues.isValid, isFalse);
      expect(good.isValid, isTrue);
    });

    test('相等性基于 id', () {
      final a = DiceRecord(id: 'same', values: const [1], timestamp: epoch);
      final b = DiceRecord(id: 'same', values: const [6], timestamp: epoch);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
