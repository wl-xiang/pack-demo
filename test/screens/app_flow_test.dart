import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dice_roll/app.dart';
import 'package:dice_roll/controller/app_controller.dart';
import 'package:dice_roll/widgets/animated_dice.dart';
import 'package:dice_roll/widgets/dice_count_selector.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<AppController> bootstrap(WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AppController(prefs);
    await controller.load();
    await tester.pumpWidget(
      DiceRollApp(controller: controller, animatedBackground: false),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// 读取总和数字文本（带 Key，避免与骰子数量按钮的数字冲突）。
  String sumText(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(const ValueKey('sum-value')));
    return text.data ?? '';
  }

  group('主界面', () {
    testWidgets('初始渲染：标题、骰子、按钮与初始总和', (tester) async {
      final controller = await bootstrap(tester);

      expect(find.text('灵动骰子'), findsOneWidget);
      expect(find.text('摇一摇'), findsOneWidget);
      expect(find.byType(AnimatedDice), findsOneWidget);
      expect(sumText(tester), '6');
      expect(controller.recordCount, 0);
    });

    testWidgets('点击摇一摇：动画结束后生成一条记录并显示总和', (tester) async {
      final controller = await bootstrap(tester);

      await tester.tap(find.text('摇一摇'));
      await tester.pump();
      expect(find.text('骰运中…'), findsOneWidget);

      // 等待全部骰子动画完成（1 颗骰子 1450ms，留足余量）。
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(controller.recordCount, 1);
      final record = controller.records.first;
      expect(record.values.length, 1);
      expect(sumText(tester), '${record.sum}');
      expect(find.text('骰运中…'), findsNothing);
      expect(find.text('摇一摇'), findsOneWidget);
    });

    testWidgets('摇骰过程中按钮防抖：重复点击不产生多条记录', (tester) async {
      final controller = await bootstrap(tester);

      await tester.tap(find.text('摇一摇'));
      await tester.pump(const Duration(milliseconds: 200));
      // 动画未结束时按钮不可再次触发。
      await tester.tap(find.text('骰运中…'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(controller.recordCount, 1);
    });

    testWidgets('切换骰子数量到 3：显示 3 颗骰子并按 3 颗记录', (tester) async {
      final controller = await bootstrap(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(DiceCountSelector),
          matching: find.text('3'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedDice), findsNWidgets(3));
      expect(controller.diceCount, 3);

      await tester.tap(find.text('摇一摇'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(controller.recordCount, 1);
      expect(controller.records.first.values.length, 3);
      expect(controller.records.first.diceCount, 3);
    });

    testWidgets('主题循环切换：跟随系统 → 浅色 → 深色 → 跟随系统', (tester) async {
      final controller = await bootstrap(tester);

      expect(controller.themeMode, ThemeMode.system);
      expect(find.byIcon(Icons.brightness_auto_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.brightness_auto_rounded));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.light);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.light_mode_rounded));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.dark);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pumpAndSettle();
      expect(controller.themeMode, ThemeMode.system);
    });
  });

  group('历史记录', () {
    testWidgets('空状态展示', (tester) async {
      await bootstrap(tester);

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      expect(find.text('历史记录'), findsOneWidget);
      expect(find.text('还没有记录'), findsOneWidget);
      expect(find.text('摇一把骰子，结果会出现在这里'), findsOneWidget);
    });

    testWidgets('展示记录：迷你骰子、精确时间与总和', (tester) async {
      final controller = await bootstrap(tester);
      await controller.addRecord(const [4, 6]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      expect(find.text('1 条'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('总和'), findsOneWidget);
      expect(find.textContaining('今天 '), findsOneWidget);
    });

    testWidgets('左滑删除记录并支持撤销', (tester) async {
      final controller = await bootstrap(tester);
      await controller.addRecord(const [2, 5]);
      await controller.addRecord(const [6]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();
      expect(controller.recordCount, 2);

      // 左滑最新的记录。
      await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.recordCount, 1);
      expect(find.text('已删除一条记录'), findsOneWidget);

      // 点击撤销，记录恢复。
      await tester.tap(find.text('撤销'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(controller.recordCount, 2);
    });

    testWidgets('清空全部记录（带确认对话框）', (tester) async {
      final controller = await bootstrap(tester);
      await controller.addRecord(const [1]);
      await controller.addRecord(const [2]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
      await tester.pumpAndSettle();

      expect(find.text('清空历史记录'), findsOneWidget);
      expect(find.textContaining('确定要删除全部 2 条记录'), findsOneWidget);

      // 先取消，记录保留。
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(controller.recordCount, 2);

      // 再确认清空。
      await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部清空'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.recordCount, 0);
      expect(find.text('还没有记录'), findsOneWidget);
      expect(find.text('历史记录已清空'), findsOneWidget);
    });
  });
}
