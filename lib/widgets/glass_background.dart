import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 向子树传递「背景是否启用漂移动画」。
/// 测试中置为 false，避免无限动画阻塞 pumpAndSettle。
class BackgroundAnimationScope extends InheritedWidget {
  const BackgroundAnimationScope({
    super.key,
    required this.animated,
    required super.child,
  });

  final bool animated;

  static bool isEnabled(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BackgroundAnimationScope>();
    return scope?.animated ?? true;
  }

  @override
  bool updateShouldNotify(BackgroundAnimationScope oldWidget) =>
      animated != oldWidget.animated;
}

/// 全局背景：柔和渐变底 + 缓慢漂移的光斑，营造高级氛围感。
class GlassBackground extends StatefulWidget {
  const GlassBackground({super.key, required this.child, this.animate});

  final Widget child;

  /// 是否启用漂移动画；为 null 时继承 [BackgroundAnimationScope]。
  final bool? animate;

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant GlassBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  bool get _effectiveAnimate =>
      widget.animate ?? BackgroundAnimationScope.isEnabled(context);

  void _syncAnimation() {
    if (!mounted) {
      return;
    }
    if (_effectiveAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tokens.backgroundTop, tokens.backgroundBottom],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value * 2 * math.pi;
            return Stack(
              fit: StackFit.expand,
              children: [
                _Blob(
                  alignment: Alignment(
                    -1.15 + 0.10 * math.sin(t),
                    -1.05 + 0.08 * math.cos(t * 0.9),
                  ),
                  diameter: 460,
                  color: tokens.blobA,
                  opacity: isDark ? 0.55 : 0.45,
                ),
                _Blob(
                  alignment: Alignment(
                    1.15 + 0.09 * math.cos(t * 0.8),
                    -0.35 + 0.10 * math.sin(t * 1.1),
                  ),
                  diameter: 380,
                  color: tokens.blobB,
                  opacity: isDark ? 0.42 : 0.40,
                ),
                _Blob(
                  alignment: Alignment(
                    -0.75 + 0.11 * math.sin(t * 1.2),
                    1.2 + 0.07 * math.cos(t),
                  ),
                  diameter: 420,
                  color: tokens.blobC,
                  opacity: isDark ? 0.40 : 0.35,
                ),
                _Blob(
                  alignment: Alignment(
                    0.9 + 0.08 * math.sin(t * 0.7),
                    1.15 + 0.09 * math.cos(t * 1.3),
                  ),
                  diameter: 340,
                  color: tokens.blobA,
                  opacity: isDark ? 0.30 : 0.28,
                ),
                ?child,
              ],
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// 柔和径向光斑。
class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.diameter,
    required this.color,
    required this.opacity,
  });

  final Alignment alignment;
  final double diameter;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.55),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
