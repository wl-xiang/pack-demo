import 'package:flutter/material.dart';

import 'controller/app_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_background.dart' show BackgroundAnimationScope;

/// 应用根组件：主题（浅色 / 深色 / 跟随系统）随 [controller] 变化。
class DiceRollApp extends StatelessWidget {
  const DiceRollApp({
    super.key,
    required this.controller,
    this.animatedBackground = true,
  });

  final AppController controller;

  /// 是否启用背景光斑漂移动画（测试中可关闭以便 pumpAndSettle）。
  final bool animatedBackground;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: '灵动骰子',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.themeMode,
          home: HomeScreen(controller: controller),
          builder: (context, child) {
            return BackgroundAnimationScope(
              animated: animatedBackground,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
