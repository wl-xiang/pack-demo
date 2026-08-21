import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 骰子数量选择器（1-6），玻璃容器内的药丸按钮组。
class DiceCountSelector extends StatelessWidget {
  const DiceCountSelector({
    super.key,
    required this.count,
    required this.enabled,
    required this.onSelected,
  });

  final int count;
  final bool enabled;
  final ValueChanged<int> onSelected;

  static const int _min = 1;
  static const int _max = 6;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Row(
      children: [
        Text(
          '骰子数量',
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        for (var n = _min; n <= _max; n++) ...[
          if (n > _min) const SizedBox(width: 8),
          _CountPill(
            value: n,
            selected: n == count,
            enabled: enabled,
            onTap: () => onSelected(n),
          ),
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$value 颗骰子',
      child: GestureDetector(
        onTap: enabled && !selected ? onTap : null,
        child: AnimatedScale(
          scale: selected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: selected ? AppTheme.brandGradient : null,
              color: selected
                  ? null
                  : tokens.glassFill.withValues(alpha: enabled ? 1.0 : 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.35)
                    : tokens.glassBorder.withValues(alpha: enabled ? 1.0 : 0.4),
                width: 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.indigo.withValues(alpha: 0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : tokens.textSecondary.withValues(
                          alpha: enabled ? 1.0 : 0.5,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
