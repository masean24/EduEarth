import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// State progres baca materi pembelajaran yang disimpan secara persisten.
///
/// Menggunakan prinsip *high-water mark* (progres maksimum yang pernah dicapai),
/// sehingga ketika pengguna menggulir (scroll) kembali ke atas atau menutup lalu
/// membuka ulang materi, persentase progres baca tidak pernah turun kembali ke 0%.
class ReadingProgressState {
  const ReadingProgressState({
    this.maxProgressBySlug = const <String, double>{},
    this.lastOffsetBySlug = const <String, double>{},
    this.lastReadSlug,
    this.isLoaded = false,
  });

  final Map<String, double> maxProgressBySlug;
  final Map<String, double> lastOffsetBySlug;
  final String? lastReadSlug;
  final bool isLoaded;

  /// Mengambil progres tertinggi (`0.0` s.d. `1.0`) untuk suatu `slug` materi.
  double progressFor(String slug) {
    final val = maxProgressBySlug[slug];
    if (val == null || val.isNaN) return 0.0;
    return val.clamp(0.0, 1.0);
  }

  /// Mengambil posisi scroll terakhir (piksel) untuk suatu `slug` materi.
  double lastOffsetFor(String slug) {
    final val = lastOffsetBySlug[slug];
    if (val == null || val.isNaN || val < 0) return 0.0;
    return val;
  }

  /// Jumlah materi yang sudah selesai dibaca (mencapai >= [threshold], default 85%).
  int completedCount({double threshold = 0.85}) {
    return maxProgressBySlug.values.where((v) => v >= threshold).length;
  }

  /// Jumlah materi yang sudah mulai dibaca (> 2%).
  int startedCount() {
    return maxProgressBySlug.values.where((v) => v > 0.02).length;
  }

  ReadingProgressState copyWith({
    Map<String, double>? maxProgressBySlug,
    Map<String, double>? lastOffsetBySlug,
    String? lastReadSlug,
    bool? isLoaded,
  }) {
    return ReadingProgressState(
      maxProgressBySlug: maxProgressBySlug ?? this.maxProgressBySlug,
      lastOffsetBySlug: lastOffsetBySlug ?? this.lastOffsetBySlug,
      lastReadSlug: lastReadSlug ?? this.lastReadSlug,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class ReadingProgressNotifier extends Notifier<ReadingProgressState> {
  static const String _maxProgressBaseKey = 'eduearth_reading_max_progress_v1';
  static const String _lastOffsetBaseKey = 'eduearth_reading_last_offset_v1';
  static const String _lastReadSlugBaseKey = 'eduearth_reading_last_slug_v1';

  bool _canPersist = true;
  String? _activeUserId;

  String _scopedKey(String baseKey, String? userId) {
    if (userId != null && userId.isNotEmpty) {
      return '${baseKey}_$userId';
    }
    return baseKey;
  }

  @override
  ReadingProgressState build() {
    final isSupabaseReady = ref.watch(isSupabaseInitializedProvider);
    final userId = ref.watch(currentSessionProvider)?.user.id;
    _activeUserId = userId;
    _canPersist = !(isSupabaseReady && userId == null);

    if (!_canPersist) {
      return const ReadingProgressState(isLoaded: true);
    }

    _loadFromPrefs(expectedUserId: userId);
    return const ReadingProgressState();
  }

  Future<void> _loadFromPrefs({required String? expectedUserId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || !_canPersist || _activeUserId != expectedUserId) {
        return;
      }
      final rawProgress = prefs.getString(
        _scopedKey(_maxProgressBaseKey, expectedUserId),
      );
      final rawOffsets = prefs.getString(
        _scopedKey(_lastOffsetBaseKey, expectedUserId),
      );
      final lastSlug = prefs.getString(
        _scopedKey(_lastReadSlugBaseKey, expectedUserId),
      );

      final parsedProgress = <String, double>{};
      if (rawProgress != null && rawProgress.isNotEmpty) {
        final decoded = jsonDecode(rawProgress);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value is num) {
              final nextVal = value.toDouble().clamp(0.0, 1.0);
              final currentVal = state.progressFor(key);
              parsedProgress[key] = math.max(currentVal, nextVal);
            }
          });
        }
      }

      // Pertahankan nilai yang mungkin sudah di-set secara sinkron sebelum prefs selesai dimuat
      state.maxProgressBySlug.forEach((key, value) {
        parsedProgress[key] = math.max(parsedProgress[key] ?? 0.0, value);
      });

      final parsedOffsets = <String, double>{
        ...state.lastOffsetBySlug,
      };
      if (rawOffsets != null && rawOffsets.isNotEmpty) {
        final decoded = jsonDecode(rawOffsets);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            if (value is num && value >= 0 && !parsedOffsets.containsKey(key)) {
              parsedOffsets[key] = value.toDouble();
            }
          });
        }
      }

      state = ReadingProgressState(
        maxProgressBySlug: parsedProgress,
        lastOffsetBySlug: parsedOffsets,
        lastReadSlug: state.lastReadSlug ??
            ((lastSlug != null && lastSlug.trim().isNotEmpty)
                ? lastSlug.trim()
                : null),
        isLoaded: true,
      );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(isLoaded: true);
      }
    }
  }

  /// Mencatat bahwa materi [slug] baru dibuka tanpa menurunkan progres sebelumnya.
  Future<void> markMaterialOpened(String slug) async {
    if (!_canPersist) return;
    final cleanSlug = slug.trim();
    if (cleanSlug.isEmpty) return;

    final prevMax = state.progressFor(cleanSlug);
    final nextMax = math.max(prevMax, 0.05);

    if (prevMax == nextMax && state.lastReadSlug == cleanSlug) return;

    final updatedProgress = Map<String, double>.from(state.maxProgressBySlug)
      ..[cleanSlug] = nextMax;

    state = state.copyWith(
      maxProgressBySlug: updatedProgress,
      lastReadSlug: cleanSlug,
    );
    await _persist();
  }

  /// Memperbarui progres baca dengan prinsip *high-water mark* (hanya naik, tidak pernah turun saat scroll ke atas).
  Future<void> updateReadingProgress({
    required String slug,
    required double scrollFraction,
    required double scrollOffset,
  }) async {
    if (!_canPersist) return;
    final cleanSlug = slug.trim();
    if (cleanSlug.isEmpty) return;

    final normalizedFraction = scrollFraction >= 0.96
        ? 1.0
        : scrollFraction.clamp(0.05, 1.0);
    final prevMax = state.progressFor(cleanSlug);
    final nextMax = math.max(prevMax, normalizedFraction);

    final prevOffset = state.lastOffsetFor(cleanSlug);
    final safeOffset = scrollOffset < 0 ? 0.0 : scrollOffset;

    final progressChanged = (nextMax - prevMax).abs() >= 0.01 ||
        (nextMax == 1.0 && prevMax < 1.0);
    final offsetChanged = (safeOffset - prevOffset).abs() >= 48.0;
    final slugChanged = state.lastReadSlug != cleanSlug;

    if (!progressChanged && !offsetChanged && !slugChanged) return;

    final updatedProgress = Map<String, double>.from(state.maxProgressBySlug)
      ..[cleanSlug] = nextMax;
    final updatedOffsets = Map<String, double>.from(state.lastOffsetBySlug)
      ..[cleanSlug] = safeOffset;

    state = state.copyWith(
      maxProgressBySlug: updatedProgress,
      lastOffsetBySlug: updatedOffsets,
      lastReadSlug: cleanSlug,
    );

    await _persist();
  }

  Future<void> _persist() async {
    if (!_canPersist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _activeUserId;
      await prefs.setString(
        _scopedKey(_maxProgressBaseKey, userId),
        jsonEncode(state.maxProgressBySlug),
      );
      await prefs.setString(
        _scopedKey(_lastOffsetBaseKey, userId),
        jsonEncode(state.lastOffsetBySlug),
      );
      if (state.lastReadSlug != null) {
        await prefs.setString(
          _scopedKey(_lastReadSlugBaseKey, userId),
          state.lastReadSlug!,
        );
      }
    } catch (_) {
      // Abaikan kegagalan I/O lokal agar pengalaman membaca tetap mulus.
    }
  }
}

final readingProgressProvider =
    NotifierProvider<ReadingProgressNotifier, ReadingProgressState>(
  ReadingProgressNotifier.new,
);
