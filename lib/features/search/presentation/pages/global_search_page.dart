import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common/empty_view.dart';
import '../../../../core/widgets/common/error_view.dart';
import '../../../../core/widgets/common/loading_view.dart';
import '../../../../core/widgets/common/material_card.dart';
import '../../../../core/widgets/common/plant_card.dart';
import '../../../../core/widgets/glass/glass_container.dart';
import '../providers/search_providers.dart';

/// Halaman Pencarian Global (Global Search) Fase 5.
///
/// Mencari pembangkit energi (`power_plants`) dan materi pembelajaran
/// (`learning_materials`) dengan search bar ber-efek Liquid Glass dan debounce.
class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(searchQueryProvider),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).setQuery(value);
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(globalSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Global'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: GlassContainer(
                borderRadius: AppTheme.buttonRadius,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, textValue, _) {
                    return TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) {
                        _debounceTimer?.cancel();
                        ref.read(searchQueryProvider.notifier).setQuery(value);
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Cari nama pembangkit, provinsi, atau materi...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.forestGreen,
                        ),
                        suffixIcon: textValue.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Bersihkan pencarian',
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: _clearSearch,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: query.trim().isEmpty
                  ? const EmptyView(
                      icon: Icons.manage_search_rounded,
                      title: 'Cari Pembangkit & Materi Energi',
                      description:
                          'Ketik kata kunci seperti "PLTS", "Surya", "Air", atau nama wilayah untuk menemukan konten terkait.',
                    )
                  : resultsAsync.when(
                      loading: () => const LoadingView(
                        message: 'Mencari materi dan pembangkit...',
                      ),
                      error: (error, _) => ErrorView(
                        message: error.toString(),
                        onRetry: () =>
                            ref.invalidate(globalSearchResultsProvider),
                      ),
                      data: (results) {
                        if (results.isEmpty) {
                          return EmptyView(
                            icon: Icons.search_off_rounded,
                            title: 'Tidak Ditemukan Hasil',
                            description:
                                'Tidak ada pembangkit atau materi pembelajaran yang cocok dengan kata kunci "$query".',
                            actionLabel: 'Hapus Kata Kunci',
                            onAction: _clearSearch,
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                          children: [
                            if (results.materials.isNotEmpty) ...[
                              Text(
                                'Materi Pembelajaran (${results.materials.length})',
                                style: AppTextStyles.title,
                              ),
                              const SizedBox(height: 12),
                              ...results.materials.map((mat) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: MaterialCard(
                                    material: mat,
                                    onTap: () => context.push(
                                      '/learning/material/${mat.slug}',
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ],
                            if (results.plants.isNotEmpty) ...[
                              Text(
                                'Pembangkit Energi (${results.plants.length})',
                                style: AppTextStyles.title,
                              ),
                              const SizedBox(height: 12),
                              ...results.plants.map((plant) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: PlantCard(
                                    plant: plant,
                                    onTap: () =>
                                        context.push('/plants/${plant.id}'),
                                  ),
                                );
                              }),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
