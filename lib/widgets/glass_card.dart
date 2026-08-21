import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 玻璃拟态卡片。
///
/// [blurred] 为 true 时对背后内容做实时高斯模糊（用于主界面少量关键卡片）；
/// 为 false 时使用半透明填充（用于列表项，性能更友好）。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
    this.blurred = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool blurred;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final radius = BorderRadius.circular(borderRadius);
    final fill = blurred ? tokens.cardFill : tokens.glassFill;
    final border = blurred ? tokens.cardBorder : tokens.glassBorder;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!blurred) {
      return card;
    }
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: card,
      ),
    );
  }
}
