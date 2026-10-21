import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central design tokens for ZLOY.AI.
///
/// The palette is a deliberately dark, high-contrast "night classroom" theme
/// with a single hot accent (ember red) and a cool secondary (violet) so the
/// angry-teacher brand reads clearly without becoming noisy.
class ZloyColors {
  ZloyColors._();

  // Surfaces (dark -> light)
  static const Color background = Color(0xFF0A0D13);
  static const Color surface = Color(0xFF121821);
  static const Color surfaceAlt = Color(0xFF1A222E);
  static const Color surfaceHigh = Color(0xFF232D3C);
  static const Color outline = Color(0xFF2E3A4C);

  // Brand
  static const Color ember = Color(0xFFFF5A3C);
  static const Color emberDeep = Color(0xFFD93A20);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetDeep = Color(0xFF6438D6);

  // Semantic
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4757);
  static const Color info = Color(0xFF3FB6FF);

  // Text
  static const Color textPrimary = Color(0xFFF3F6FB);
  static const Color textSecondary = Color(0xFFA6B4C9);
  static const Color textMuted = Color(0xFF71809A);

  static const LinearGradient emberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ember, Color(0xFFFF8A3C)],
  );

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, Color(0xFF4F8CFF)],
  );

  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2430), Color(0xFF141A24)],
  );

  static const RadialGradient heroGlow = RadialGradient(
    colors: [Color(0x33FF5A3C), Color(0x000A0D13)],
    radius: 0.95,
  );
}

/// Type scale. Roboto is bundled with Android, so no font download is needed
/// and the app stays fully offline-capable.
class ZloyType {
  ZloyType._();

  static const TextStyle display = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: ZloyColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: ZloyColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: ZloyColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: ZloyColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: ZloyColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
    color: ZloyColors.textMuted,
  );

  static const TextStyle mono = TextStyle(
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
    fontFamily: 'monospace',
    color: ZloyColors.textPrimary,
  );
}

class ZloySpacing {
  ZloySpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class ZloyTheme {
  ZloyTheme._();

  static const double radius = 20;

  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: ZloyColors.ember,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF3A1A12),
      onPrimaryContainer: Color(0xFFFFD9D0),
      secondary: ZloyColors.violet,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF241B45),
      onSecondaryContainer: Color(0xFFDCD2FF),
      surface: ZloyColors.surface,
      onSurface: ZloyColors.textPrimary,
      surfaceContainerHighest: ZloyColors.surfaceAlt,
      error: ZloyColors.danger,
      onError: Colors.white,
      outline: ZloyColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ZloyColors.background,
      canvasColor: ZloyColors.background,
      fontFamily: 'Roboto',
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: ZloyColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: ZloyType.title,
        iconTheme: IconThemeData(color: ZloyColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: ZloyColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: ZloyColors.outline, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ZloyColors.ember,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZloyColors.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: ZloyColors.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ZloyColors.ember,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZloyColors.surfaceAlt,
        hintStyle: const TextStyle(color: ZloyColors.textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: ZloyColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZloyColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZloyColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZloyColors.ember, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ZloyColors.danger),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : ZloyColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? ZloyColors.ember
              : ZloyColors.surfaceHigh,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: ZloyColors.ember,
        inactiveTrackColor: ZloyColors.surfaceHigh,
        thumbColor: Colors.white,
        overlayColor: Color(0x33FF5A3C),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ZloyColors.surfaceHigh,
        contentTextStyle: const TextStyle(color: ZloyColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: ZloyColors.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ZloyColors.ember,
        linearTrackColor: ZloyColors.surfaceHigh,
        circularTrackColor: ZloyColors.surfaceHigh,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ZloyColors.surface,
        indicatorColor: const Color(0x2EFF5A3C),
        height: 68,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: states.contains(WidgetState.selected)
                ? ZloyColors.ember
                : ZloyColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? ZloyColors.ember
                : ZloyColors.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ZloyColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ZloyColors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ZloyColors.ember,
        selectionColor: Color(0x55FF5A3C),
        selectionHandleColor: ZloyColors.ember,
      ),
    );
  }
}
