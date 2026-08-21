import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 主摇骰按钮：品牌渐变、辉光阴影、按压反馈与摇骰中状态。
class RollButton extends StatefulWidget {
  const RollButton({super.key, required this.onTap, required this.rolling});

  final VoidCallback onTap;
  final bool rolling;

  @override
  State<RollButton> createState() => _RollButtonState();
}

class _RollButtonState extends State<RollButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.rolling ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.rolling ? 0.85 : 1.0,
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.indigo.withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: widget.rolling
                    ? Row(
                        key: const ValueKey('rolling'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('骰运中…', style: _labelStyle(context)),
                        ],
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.casino_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text('摇一摇', style: _labelStyle(context)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: 8,
    );
  }
}
