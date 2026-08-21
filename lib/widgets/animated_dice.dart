import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dice_face.dart';

/// 带翻滚动效的骰子。
///
/// [rollId] 每次自增即触发一次新的摇骰动画：多轴 3D 翻滚 + 抛起落定 +
/// 弹性回弹，结束后通过 [onSettled] 通知父级。
class AnimatedDice extends StatefulWidget {
  const AnimatedDice({
    super.key,
    required this.value,
    required this.rollId,
    this.size = 96,
    this.duration = const Duration(milliseconds: 1500),
    this.onSettled,
  });

  /// 目标点数（1-6）。
  final int value;

  /// 摇骰序号，自增触发摇骰。
  final int rollId;

  /// 骰子边长。
  final double size;

  /// 单次摇骰动画总时长（含落定回弹）。
  final Duration duration;

  /// 动画结束回调。
  final VoidCallback? onSettled;

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _shownValue;
  Timer? _flickerTimer;
  bool _flickering = false;
  double _rotateX = 0;
  double _rotateY = 0;
  double _rotateZ = 0;
  final math.Random _random = math.Random();

  /// 翻滚阶段占动画总时长的比例，其余为落定回弹。
  static const double _tumbleRatio = 0.78;

  @override
  void initState() {
    super.initState();
    _shownValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rollId > oldWidget.rollId) {
      _beginRoll();
    } else if (widget.value != oldWidget.value && !_controller.isAnimating) {
      // 未处于摇骰中，直接切换静止展示的面。
      setState(() => _shownValue = widget.value);
    }
  }

  @override
  void dispose() {
    _flickerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _beginRoll() {
    _rotateX = _randomAngle(3, 5);
    _rotateY = _randomAngle(3, 5);
    _rotateZ = _randomAngle(1, 3);
    _flickering = true;
    _flickerTimer?.cancel();
    _flickerTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (mounted) {
        setState(() => _shownValue = 1 + _random.nextInt(6));
      }
    });
    _controller.forward(from: 0);
  }

  double _randomAngle(int minTurns, int maxTurns) {
    final turns = minTurns + _random.nextInt(maxTurns - minTurns + 1);
    return turns * math.pi * (_random.nextBool() ? 1 : -1);
  }

  void _onTick() {
    // 翻滚接近尾声时锁定最终点数。
    if (_flickering && _controller.value >= _tumbleRatio) {
      _flickerTimer?.cancel();
      _flickerTimer = null;
      _flickering = false;
      if (mounted) {
        setState(() => _shownValue = widget.value);
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_shownValue != widget.value) {
        setState(() => _shownValue = widget.value);
      }
      widget.onSettled?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final tumbleT = (t / _tumbleRatio).clamp(0.0, 1.0);
        final rotEased = Curves.easeOutCubic.transform(tumbleT);
        final hop = -math.sin(tumbleT * math.pi) * size * 0.55;
        final hopFraction = -hop / (size * 0.55);

        // 落定阶段的挤压回弹。
        final landT = ((t - _tumbleRatio) / (1 - _tumbleRatio)).clamp(0.0, 1.0);
        final bounce = Curves.elasticOut.transform(landT);
        final scaleY = t > _tumbleRatio ? 0.86 + 0.14 * bounce : 1.0;
        final scaleX = t > _tumbleRatio ? 1.10 - 0.10 * bounce : 1.0;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateX(_rotateX * rotEased)
          ..rotateY(_rotateY * rotEased)
          ..rotateZ(_rotateZ * rotEased);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: Transform.translate(
                offset: Offset(0, hop),
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: matrix,
                    child: DiceFace(value: _shownValue, size: size),
                  ),
                ),
              ),
            ),
            SizedBox(height: size * 0.10),
            // 地面投影：骰子跳得越高，投影越小越淡。
            Container(
              width: size * (1.0 - 0.30 * hopFraction),
              height: size * 0.11,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(size * 0.055),
                  right: Radius.circular(size * 0.055),
                ),
                color: Colors.black.withValues(
                  alpha: 0.20 - 0.13 * hopFraction,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
