import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Notifier global untuk mengatur apakah efek blur (Liquid Glass) dikurangi,
/// sekaligus mempersistensikan pilihannya ke `SharedPreferences`.
class ReduceGlassEffectNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSavedPreference();
    return false;
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(AppConstants.prefReduceMotionAndGlass) ?? false;
    if (state != saved) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    await setReduceEffect(!state);
  }

  Future<void> setReduceEffect(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefReduceMotionAndGlass, value);
  }
}

final reduceGlassEffectProvider =
    NotifierProvider<ReduceGlassEffectNotifier, bool>(
  ReduceGlassEffectNotifier.new,
);

/// Kontainer iOS Liquid Glass / Glassmorphism untuk penggunaan selektif
/// (search bar, filter chip di atas peta, bottom navigation, modal, bottom sheet).
///
/// Mendukung fallback tanpa `BackdropFilter` blur secara otomatis lewat
/// `reduceGlassEffectProvider` atau parameter eksplisit `enableBlur`.
class GlassContainer extends ConsumerWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppTheme.cardRadius,
    this.blur = 16.0,
    this.tintOpacity = 0.65,
    this.borderOpacity = 0.38,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.tintColor = AppColors.surfaceWhite,
    this.enableBlur,
    this.useRepaintBoundary = true,
  });

  final Widget child;
  final double borderRadius;
  final double blur;
  final double tintOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color tintColor;

  /// Bila `null`, mengikuti nilai global dari `reduceGlassEffectProvider`.
  final bool? enableBlur;

  /// Membungkus dengan `RepaintBoundary` agar performa tetap ringan di atas peta.
  final bool useRepaintBoundary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceEffectGlobal = ref.watch(reduceGlassEffectProvider);
    final shouldBlur = enableBlur ?? !reduceEffectGlobal;

    final effectiveOpacity = shouldBlur
        ? tintOpacity.clamp(0.0, 1.0)
        : (tintOpacity + 0.25).clamp(0.85, 0.96);

    final decoration = BoxDecoration(
      color: tintColor.withValues(alpha: effectiveOpacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: AppColors.surfaceWhite.withValues(
          alpha: shouldBlur ? borderOpacity.clamp(0.0, 1.0) : 0.7,
        ),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.forestGreen.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (shouldBlur && blur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (useRepaintBoundary) {
      return RepaintBoundary(child: content);
    }

    return content;
  }
}
