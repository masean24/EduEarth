import 'package:eduearth/features/learning/domain/learning_material_parser.dart';
import 'package:eduearth/features/learning/presentation/widgets/learning_detail_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningDetailSections widgets', () {
    testWidgets('MaterialFlipFlashcard toggles between question and answer on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: MaterialFlipFlashcard(
                question: 'Mengapa panel surya memerlukan inverter?',
                answer: 'Untuk mengubah arus DC menjadi arus AC jaringan.',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Mengapa panel surya memerlukan inverter?'),
        findsOneWidget,
      );

      await tester.tap(find.byType(MaterialFlipFlashcard));
      await tester.pumpAndSettle();

      expect(
        find.text('Untuk mengubah arus DC menjadi arus AC jaringan.'),
        findsOneWidget,
      );
    });

    testWidgets('MaterialFlowStepperCard advances stage via Lanjut and dots', (
      tester,
    ) async {
      var selected = 0;
      const stages = <MaterialWorkflowStage>[
        (
          shortTitle: 'Efek PV',
          icon: Icons.wb_sunny_rounded,
          headline: 'Tahap 1 — Penangkapan Foton',
          detail: 'Menghasilkan arus DC.',
          tag: 'Arus DC',
        ),
        (
          shortTitle: 'Inverter',
          icon: Icons.sync_alt_rounded,
          headline: 'Tahap 2 — Konversi Inverter',
          detail: 'Mengubah DC ke AC 50 Hz.',
          tag: '50 Hz AC',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MaterialFlowStepperCard(
                  stages: stages,
                  selectedIndex: selected,
                  onSelectIndex: (idx) => setState(() => selected = idx),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tahap 1 — Penangkapan Foton'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Tahap 2 — Konversi Inverter'), findsOneWidget);
    });

    testWidgets('MaterialSegmentedTabsCard switches tab body on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialSegmentedTabsCard(
              tabs: const [
                MaterialSegmentedTab(
                  label: 'PLTS Terapung',
                  bodyMd: 'Dipasang di permukaan waduk buatan.',
                ),
                MaterialSegmentedTab(
                  label: 'Agrivoltaik',
                  bodyMd: 'Memadukan panel surya dengan lahan tani.',
                ),
              ],
              markdownStyleSheet: MarkdownStyleSheet(),
              onTapLink: (_, _, _) {},
            ),
          ),
        ),
      );

      expect(
        find.text('Dipasang di permukaan waduk buatan.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Agrivoltaik'));
      await tester.pumpAndSettle();
      expect(
        find.text('Memadukan panel surya dengan lahan tani.'),
        findsOneWidget,
      );
    });
  });
}
