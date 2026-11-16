import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final initialGuestMode = prefs.getBool(AppConstants.prefGuestMode) ?? false;

  runApp(
    ProviderScope(
      // Batasi retry otomatis Riverpod agar ErrorView cepat tampil saat offline.
      retry: (_, _) => null,
      overrides: [
        initialGuestModeProvider.overrideWithValue(initialGuestMode),
      ],
      child: const EduEarthApp(),
    ),
  );
}
