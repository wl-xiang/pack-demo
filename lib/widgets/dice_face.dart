import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 静态骰子面：象牙渐变面 + 立体点数。
class DiceFace extends StatelessWidget {
  const DiceFace({super.key, required this.value, required this.size});

  /// 点数（1-6）。
  final int value;

  /// 边长。
  final double size;

  /// 每个点数对应的点阵位置（3x3 网格上的 Alignment）。
  static const Map<int, List<Alignment>> _pipLayout = {
    1: [Alignment(0, 0)],
    2: [Alignment(-1, -1), Alignment(1, 1)],
    3: [Alignment(-1, -1), Alignment(0, 0), Alignment(1, 1)],
    4: [Alignment(-1, -1), Alignment(1, -1), Alignment(-1, 1), Alignment(1, 1)],
    5: [
      Alignment(-1, -1),
      Alignment(1, -1),
      Alignment(0, 0),
      Alignment(-1, 1),
      Alignment(1, 1),
    ],
    6: [
      Alignment(-1, -1),
      Alignment(0, -1),
      Alignment(1, -1),
      Alignment(-1, 1),
      Alignment(0, 1),
      Alignment(1, 1),
    ],
  };

  /// 点数越多点越小，保证布局均衡。
  static double _pipSizeFor(int value, double size) {
    switch (value) {
      case 1:
        return size * 0.21;
      case 2:
      case 3:
        return size * 0.17;
      case 4:
        return size * 0.155;
      default:
        return size * 0.145;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pips = _pipLayout[value] ?? _pipLayout[1]!;
    final pipSize = _pipSizeFor(value, size);
    final isAce = value == 1;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.diceFaceTop, AppTheme.diceFaceBottom],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: math.max(size * 0.018, 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A2038).withValues(alpha: 0.28),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: Stack(
          children: [
            for (final alignment in pips)
              Align(
                alignment: alignment,
                child: KeyedSubtree(
                  key: const ValueKey('pip'),
                  child: _Pip(size: pipSize, red: isAce),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 单个点数：径向渐变呈现内凹立体感；1 点为红色（东方骰子传统）。
class _Pip extends StatelessWidget {
  const _Pip({required this.size, required this.red});

  final double size;
  final bool red;

  @override
  Widget build(BuildContext context) {
    const base = AppTheme.pipDark;
    const highlight = Color(0xFF4A5080);
    const redBase = AppTheme.pipRed;
    const redHighlight = Color(0xFFF26D72);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: red ? [redHighlight, redBase] : [highlight, base],
        ),
        boxShadow: [
          BoxShadow(
            color: (red ? redBase : base).withValues(alpha: 0.35),
            blurRadius: size * 0.6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
