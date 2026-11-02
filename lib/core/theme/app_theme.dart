import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Konfigurasi `ThemeData` utama dan token gaya (Design Tokens) aplikasi EduEarth.
class AppTheme {
  const AppTheme._();

  // Token radius sesuai docs/03_DESIGN_SYSTEM.md
  static const double cardRadius = 20.0;
  static const double buttonRadius = 16.0;
  static const double bottomSheetRadius = 28.0;
  static const double pillRadius = 999.0;

  // Token border, padding, dan bayangan lembut untuk kartu & chip
  static const double cardBorderWidth = 1.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(14.0);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 10.0,
    vertical: 4.0,
  );

  /// Bayangan lembut standar untuk kartu di seluruh aplikasi.
  static final List<BoxShadow> softCardShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.forestGreen.withValues(alpha: 0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  /// Dekorasi kartu standar (radius 20, border tipis `divider`, bayangan lembut).
  static BoxDecoration cardDecoration({
    Color backgroundColor = AppColors.surfaceWhite,
    Color borderColor = AppColors.divider,
    double radius = cardRadius,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
        width: cardBorderWidth,
      ),
      boxShadow: withShadow ? softCardShadow : null,
    );
  }

  /// Dekorasi badge/chip kecil berbentuk pill.
  static BoxDecoration badgeDecoration({
    required Color backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(pillRadius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: 1.0)
          : null,
    );
  }

  // Konstanta dimensi & margin Bottom Navigation Glass
  static const double bottomNavHeight = 68.0;
  static const double bottomNavHorizontalMargin = 16.0;
  static const double bottomNavBottomMargin = 12.0;

  /// Jarak aman bawah untuk seluruh layar yang discroll di dalam shell 5 tab
  /// (`bottomNavHeight` + `bottomNavBottomMargin` + ruang ekstra 28 dp).
  static const double bottomNavScrollPadding =
      bottomNavHeight + bottomNavBottomMargin + 28.0;

  /// Jarak bawah untuk elemen apung di atas peta (`ExploreMapPage`) agar tepat
  /// berada di atas Bottom Navigation.
  static const double mapOverlayBottomPadding =
      bottomNavHeight + bottomNavBottomMargin + 8.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.offWhite,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.freshGreen,
        onPrimary: AppColors.surfaceWhite,
        primaryContainer: AppColors.mintGreen,
        onPrimaryContainer: AppColors.forestGreen,
        secondary: AppColors.forestGreen,
        onSecondary: AppColors.surfaceWhite,
        secondaryContainer: AppColors.mintGreen,
        onSecondaryContainer: AppColors.forestGreen,
        tertiary: AppColors.skyBlue,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        error: AppColors.errorRed,
        onError: AppColors.surfaceWhite,
        outline: AppColors.sageGreen,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.title,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.button,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        foregroundColor: AppColors.forestGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shadowColor: AppColors.forestGreen.withValues(alpha: 0.06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(
            color: AppColors.divider,
            width: cardBorderWidth,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.freshGreen,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestGreen,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: AppColors.sageGreen, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.forestGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.sageGreen),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(
            color: AppColors.freshGreen,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(bottomSheetRadius),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
