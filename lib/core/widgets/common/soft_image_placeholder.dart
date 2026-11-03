import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Komponen slot gambar/ilustrasi yang menampilkan gambar dari `networkImageUrl`
/// atau `assetPath` bila sudah tersedia, dan jatuh ke placeholder berwarna lembut
/// dengan ikon secara bersih bila aset belum ditambahkan.
///
/// Lihat `docs/design/ASSETS.md` untuk daftar lengkap nama file aset.
class SoftImagePlaceholder extends StatelessWidget {
  const SoftImagePlaceholder({
    super.key,
    required this.fallbackIcon,
    this.assetPath,
    this.networkImageUrl,
    this.backgroundColor = AppColors.mintGreen,
    this.iconColor = AppColors.forestGreen,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.iconSize = 32,
    this.fit = BoxFit.cover,
  });

  final IconData fallbackIcon;
  final String? assetPath;
  final String? networkImageUrl;
  final Color backgroundColor;
  final Color iconColor;
  final double borderRadius;
  final double? width;
  final double? height;
  final double iconSize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final trimmedNetwork = networkImageUrl?.trim() ?? '';
    final trimmedAsset = assetPath?.trim() ?? '';

    Widget content = _buildFallback();

    if (trimmedNetwork.isNotEmpty) {
      content = Container(
        width: width,
        height: height,
        color: backgroundColor,
        child: Image.network(
          trimmedNetwork,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    } else if (trimmedAsset.isNotEmpty) {
      final isSticker = trimmedAsset.contains('/mascot/') ||
          trimmedAsset.contains('logo_eduearth') ||
          trimmedAsset.contains('/cat_');
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final int? targetCacheWidth =
          (width != null && width!.isFinite && width! > 0)
              ? (width! * dpr).round().clamp(64, 1024)
              : null;
      content = Container(
        width: width,
        height: height,
        color: backgroundColor,
        padding: isSticker && backgroundColor.a > 0
            ? const EdgeInsets.all(6)
            : EdgeInsets.zero,
        alignment: Alignment.center,
        child: Image.asset(
          trimmedAsset,
          width: width,
          height: height,
          cacheWidth: targetCacheWidth,
          filterQuality: FilterQuality.medium,
          fit: isSticker ? BoxFit.contain : fit,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: content,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Container(
              width: iconSize * 1.6,
              height: iconSize * 1.6,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(
            fallbackIcon,
            size: iconSize,
            color: iconColor,
          ),
        ],
      ),
    );
  }
}

