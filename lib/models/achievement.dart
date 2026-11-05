/// Model immutable untuk tabel `achievements` dan `user_achievements`.
class Achievement {
  const Achievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    this.icon = 'emoji_events_rounded',
    this.points = 10,
    this.sortOrder = 0,
    this.unlockedAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final int points;
  final int sortOrder;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    DateTime? unlockedAtOverride,
  }) {
    return Achievement(
      id: (json['id'] as String?) ?? '',
      code: (json['code'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? 'emoji_events_rounded',
      points: (json['points'] as num?)?.toInt() ?? 10,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      unlockedAt: unlockedAtOverride ?? _parseDate(json['unlocked_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'sort_order': sortOrder,
      if (unlockedAt != null) 'unlocked_at': unlockedAt!.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? icon,
    int? points,
    int? sortOrder,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      points: points ?? this.points,
      sortOrder: sortOrder ?? this.sortOrder,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Hasil evaluasi RPC `check_and_award_achievements()`.
class AchievementAwardResult {
  const AchievementAwardResult({
    required this.newlyAwardedTitles,
    required this.totalUnlocked,
  });

  final List<String> newlyAwardedTitles;
  final int totalUnlocked;

  factory AchievementAwardResult.fromJson(Map<String, dynamic> json) {
    final rawNew = json['newly_awarded'];
    final titles = <String>[];
    if (rawNew is List) {
      for (final item in rawNew) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] as String?;
          if (title != null && title.isNotEmpty) {
            titles.add(title);
          }
        }
      }
    }
    return AchievementAwardResult(
      newlyAwardedTitles: titles,
      totalUnlocked: (json['total_unlocked'] as num?)?.toInt() ?? 0,
    );
  }
}

