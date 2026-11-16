import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

/// Root widget aplikasi EduEarth yang mengikat `MaterialApp.router` dan tema.
class EduEarthApp extends ConsumerWidget {
  const EduEarthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        if (!kIsWeb) return child;
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 520) return child;
            final mq = MediaQuery.of(context);
            const mobileWidth = 430.0;
            return ColoredBox(
              color: const Color(0xFFE7F2EA),
              child: Center(
                child: Container(
                  width: mobileWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withValues(alpha: 0.14),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaQuery(
                    data: mq.copyWith(
                      size: Size(mobileWidth, constraints.maxHeight),
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

