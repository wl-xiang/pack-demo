import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_dice.dart';
import '../widgets/dice_count_selector.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/roll_button.dart';
import 'history_screen.dart';

/// 主界面：摇骰舞台 + 骰子数量选择 + 总和展示。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final math.Random _random = math.Random();

  /// 当前展示的骰子点数（摇骰结束后与记录一致）。
  List<int> _displayValues = const <int>[6];

  /// 摇骰序号，自增触发所有骰子的翻滚动画。
  int _rollId = 0;

  bool _rolling = false;
  int _settledCount = 0;
  List<int> _pendingValues = const <int>[];

  /// 按骰子数量决定单颗骰子的尺寸，保证多颗时排版均衡。
  static const Map<int, double> _diceSizeByCount = {
    1: 138,
    2: 122,
    3: 106,
    4: 96,
    5: 88,
    6: 82,
  };

  void _roll() {
    if (_rolling) {
      return;
    }
    final diceCount = widget.controller.diceCount;
    setState(() {
      _rolling = true;
      _settledCount = 0;
      _pendingValues = List<int>.generate(
        diceCount,
        (_) => 1 + _random.nextInt(6),
      );
      _rollId += 1;
    });
    HapticFeedback.mediumImpact();
  }

  void _onDiceSettled() {
    _settledCount += 1;
    HapticFeedback.selectionClick();
    if (_settledCount >= _pendingValues.length) {
      final values = _pendingValues;
      setState(() {
        _rolling = false;
        _displayValues = values;
      });
      HapticFeedback.lightImpact();
      widget.controller.addRecord(values);
    }
  }

  Future<void> _changeDiceCount(int count) async {
    if (_rolling) {
      return;
    }
    setState(() {
      _displayValues = List<int>.generate(count, (_) => 1 + _random.nextInt(6));
    });
    HapticFeedback.selectionClick();
    await widget.controller.setDiceCount(count);
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final diceCount = controller.diceCount;
              final diceSize = _diceSizeByCount[diceCount] ?? 96;
              final diceWidgets = <Widget>[
                for (var i = 0; i < diceCount; i++)
                  AnimatedDice(
                    key: ValueKey('dice-$i'),
                    value: _displayValues.length == diceCount
                        ? _displayValues[i]
                        : 6,
                    rollId: _rollId,
                    size: diceSize,
                    duration: Duration(milliseconds: 1450 + i * 130),
                    onSettled: _onDiceSettled,
                  ),
              ];

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, controller),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 22,
                              runSpacing: 26,
                              children: diceWidgets,
                            ),
                            const SizedBox(height: 30),
                            _SumDisplay(sum: _sumOf(_displayValues)),
                          ],
                        ),
                      ),
                    ),
                    GlassCard(
                      blurred: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: DiceCountSelector(
                        count: diceCount,
                        enabled: !_rolling,
                        onSelected: _changeDiceCount,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RollButton(onTap: _roll, rolling: _rolling),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppController controller) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.brandGradient.createShader(bounds),
                child: const Text(
                  '灵动骰子',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'LIVELY DICE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: GlassTokens.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
        _GlassIconButton(
          icon: switch (controller.themeMode) {
            ThemeMode.system => Icons.brightness_auto_rounded,
            ThemeMode.light => Icons.light_mode_rounded,
            ThemeMode.dark => Icons.dark_mode_rounded,
          },
          tooltip: '切换主题',
          onTap: controller.cycleThemeMode,
        ),
        const SizedBox(width: 10),
        _GlassIconButton(
          icon: Icons.history_rounded,
          tooltip: '历史记录',
          badge: controller.hasRecords ? '${controller.recordCount}' : null,
          onTap: _openHistory,
        ),
      ],
    );
  }

  int? _sumOf(List<int> values) {
    if (_rolling) {
      return null;
    }
    return values.isEmpty ? null : values.fold<int>(0, (a, b) => a + b);
  }
}

/// 总和展示：渐变大数字 + 切换动效。
class _SumDisplay extends StatelessWidget {
  const _SumDisplay({required this.sum});

  final int? sum;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      children: [
        Text(
          '总和',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: SizedBox(
            key: ValueKey<int?>(sum),
            height: 64,
            child: Center(
              child: sum == null
                  ? Text(
                      '—',
                      key: const ValueKey('sum-value'),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: tokens.textSecondary.withValues(alpha: 0.6),
                      ),
                    )
                  : ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.brandGradient.createShader(bounds),
                      child: Text(
                        '$sum',
                        key: const ValueKey('sum-value'),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 玻璃质感圆形图标按钮，可带角标。
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: tokens.glassBorder, width: 1),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, size: 22, color: tokens.textPrimary)),
              if (badge != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 15),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
