import 'package:eduearth/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash redirects new user to Onboarding screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      const ProviderScope(
        child: EduEarthApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(
      find.text('Jelajahi Peta & Studi Kasus Pembangkit Indonesia'),
      findsOneWidget,
    );
    expect(find.text('1 • Explore Nusantara'), findsOneWidget);
  });

  testWidgets('Completed onboarding navigates cleanly to Home & Comparison', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_completed': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: EduEarthApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Alur Belajar EduEarth (4 Pilar)'), findsOneWidget);
    final comparisonBtn = find.text('Perbandingan & Dampak');
    await tester.ensureVisible(comparisonBtn);
    await tester.tap(comparisonBtn);
    await tester.pumpAndSettle();

    expect(find.text('Perbandingan & Dampak Energi'), findsOneWidget);
  });
}
