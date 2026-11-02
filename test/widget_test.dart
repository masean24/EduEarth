import 'package:eduearth/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('EduEarth Fase 0 smoke test renders Home Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EduEarthApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Dashboard'), findsWidgets);
    expect(find.text('Buka Demo Komponen & Glass UI'), findsOneWidget);
  });
}
