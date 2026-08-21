import 'package:flutter/material.dart';

/// 全局设计令牌：颜色、渐变与主题。
class AppTheme {
  AppTheme._();

  // 品牌色
  static const Color indigo = Color(0xFF6366F1);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color danger = Color(0xFFE5484D);

  /// 主渐变（按钮、选中态、标题）。
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet],
  );

  /// 骰子面与点数颜色。
  static const Color diceFaceTop = Color(0xFFFFFFFF);
  static const Color diceFaceBottom = Color(0xFFE4E7F4);
  static const Color pipDark = Color(0xFF2A2F55);
  static const Color pipRed = Color(0xFFE5484D);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: indigo,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF262B44)
            : const Color(0xFF20243C),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF181C30) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1A1D33),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white70 : const Color(0xFF4A4F6A),
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 玻璃拟态相关的随主题变化令牌。
class GlassTokens {
  const GlassTokens({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.cardFill,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.glassFill,
    required this.glassBorder,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color blobA;
  final Color blobB;
  final Color blobC;

  /// 玻璃卡片填充与描边（带模糊）。
  final Color cardFill;
  final Color cardBorder;

  /// 轻量玻璃填充与描边（无模糊，用于列表项）。
  final Color glassFill;
  final Color glassBorder;

  final Color textPrimary;
  final Color textSecondary;

  static GlassTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _dark : _light;
  }

  static const GlassTokens _light = GlassTokens(
    backgroundTop: Color(0xFFF2F4FB),
    backgroundBottom: Color(0xFFE3E7F6),
    blobA: Color(0xFF8B93F8),
    blobB: Color(0xFFF6A8C3),
    blobC: Color(0xFF7DD8E0),
    cardFill: Color(0x66FFFFFF),
    cardBorder: Color(0x99FFFFFF),
    glassFill: Color(0x3DFFFFFF),
    glassBorder: Color(0x59FFFFFF),
    textPrimary: Color(0xFF1A1D33),
    textSecondary: Color(0xFF6A7090),
  );

  static const GlassTokens _dark = GlassTokens(
    backgroundTop: Color(0xFF111629),
    backgroundBottom: Color(0xFF0A0E1A),
    blobA: Color(0xFF4F46E5),
    blobB: Color(0xFF7C3AED),
    blobC: Color(0xFF0E7490),
    cardFill: Color(0x1AFFFFFF),
    cardBorder: Color(0x2EFFFFFF),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x24FFFFFF),
    textPrimary: Color(0xFFF2F4FF),
    textSecondary: Color(0xFF9AA1C0),
  );
}
