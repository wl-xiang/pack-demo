import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dice_roll/utils/time_format.dart';
import 'package:dice_roll/widgets/dice_face.dart';

void main() {
  group('DiceFace 点数布局', () {
    for (var value = 1; value <= 6; value++) {
      testWidgets('点数 $value 渲染 $value 个点', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: DiceFace(value: value, size: 120)),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(DiceFace),
            matching: find.byKey(const ValueKey('pip')),
          ),
          findsNWidgets(value),
        );
      });
    }

    testWidgets('非法点数回退为 1 点', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: DiceFace(value: 9, size: 120))),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(DiceFace),
          matching: find.byKey(const ValueKey('pip')),
        ),
        findsOneWidget,
      );
    });
  });

  group('formatRecordTime', () {
    final now = DateTime(2026, 8, 21, 15, 0, 0);

    test('今天', () {
      final time = DateTime(2026, 8, 21, 9, 5, 3);
      expect(formatRecordTime(time, now: now), '今天 09:05:03');
    });

    test('昨天', () {
      final time = DateTime(2026, 8, 20, 23, 59, 59);
      expect(formatRecordTime(time, now: now), '昨天 23:59:59');
    });

    test('同年其他日期', () {
      final time = DateTime(2026, 5, 1, 8, 30);
      expect(formatRecordTime(time, now: now), '5月1日 08:30:00');
    });

    test('跨年显示年份', () {
      final time = DateTime(2025, 12, 31, 20, 15);
      expect(formatRecordTime(time, now: now), '2025年12月31日 20:15:00');
    });

    test('不传 now 时使用当前时间', () {
      final time = DateTime.now();
      expect(formatRecordTime(time), startsWith('今天 '));
    });
  });
}
