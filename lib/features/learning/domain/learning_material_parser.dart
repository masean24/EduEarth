/// Hasil parsing terstruktur dari konten Markdown materi (`content_md`)
/// agar seluruh modul pembelajaran dapat dirender dengan tata letak editorial interaktif.
class ParsedLearningMaterial {
  const ParsedLearningMaterial({
    required this.chapters,
    required this.references,
    this.keyTakeaway,
    this.introMd,
    this.referencesHeading = 'Referensi Belajar Lebih Lanjut',
  });

  final String? keyTakeaway;
  final String? introMd;
  final List<MaterialChapterContent> chapters;
  final List<MaterialReferenceItem> references;
  final String referencesHeading;
}

/// Representasi satu bagian (`## ...`) beserta blok visual terstruktur di dalamnya.
class MaterialChapterContent {
  const MaterialChapterContent({
    required this.numberLabel,
    required this.title,
    required this.navLabel,
    required this.rawBodyMd,
    this.leadMd,
    this.table,
    this.afterTableMd,
    this.segmentedTabs = const <MaterialSegmentedTab>[],
    this.proConPair,
  });

  final String numberLabel;
  final String title;
  final String navLabel;
  final String rawBodyMd;
  final String? leadMd;
  final MaterialTableData? table;
  final String? afterTableMd;
  final List<MaterialSegmentedTab> segmentedTabs;
  final MaterialProConPair? proConPair;
}

/// Data tabel Markdown untuk diubah menjadi grid komponen / kartu perbandingan.
class MaterialTableData {
  const MaterialTableData({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;
}

/// Tab konten segmented control (`### A.` vs `### B.` atau dua pendekatan utama).
class MaterialSegmentedTab {
  const MaterialSegmentedTab({
    required this.label,
    required this.bodyMd,
  });

  final String label;
  final String bodyMd;
}

/// Pasangan kartu Pro vs Tantangan pada bagian evaluasi teknologi.
class MaterialProConPair {
  const MaterialProConPair({
    required this.proTitle,
    required this.proBodyMd,
    required this.conTitle,
    required this.conBodyMd,
    this.extraMd,
  });

  final String proTitle;
  final String proBodyMd;
  final String conTitle;
  final String conBodyMd;
  final String? extraMd;
}

/// Item referensi di bagian bawah materi (tautan web maupun sitasi teks).
class MaterialReferenceItem {
  const MaterialReferenceItem({
    required this.label,
    this.subtitle,
    this.url,
  });

  final String label;
  final String? subtitle;
  final String? url;

  bool get isLink => url != null && url!.isNotEmpty;
}

/// Parser murni tanpa dependensi UI untuk memecah Markdown materi EduEarth
/// menjadi struktur Hero, Intisari, Bagian Editorial, Tabel Grid, Tab Segmented,
/// Pro/Tantangan, dan Daftar Referensi.
class LearningMaterialParser {
  const LearningMaterialParser._();

  static ParsedLearningMaterial parse(String rawMd) {
    var normalized = rawMd.replaceAll('\r\n', '\n').trim();
    var referencesHeading = 'Referensi Belajar Lebih Lanjut';
    var references = const <MaterialReferenceItem>[];

    // 1. Ekstrak blok referensi di akhir dokumen agar tidak tercampur ke isi bagian.
    final refMatch = RegExp(
      r'\n#{2,3}\s+(Referensi[^\n]*)\n([\s\S]*)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (refMatch != null) {
      referencesHeading = _cleanMarkdownInline(refMatch.group(1) ?? referencesHeading);
      final refBody = (refMatch.group(2) ?? '').trim();
      references = _parseReferences(refBody);
      normalized = normalized.substring(0, refMatch.start).trim();
      normalized = normalized.replaceFirst(RegExp(r'\n+---+\s*$'), '').trim();
    }

    // 2. Pisahkan menjadi pembuka + tiap bagian `## ...`
    final parts = normalized.split(RegExp(r'\n(?=##\s+)'));
    String? keyTakeaway;
    String? introMd;
    final chapters = <MaterialChapterContent>[];

    for (var i = 0; i < parts.length; i++) {
      final chunk = _stripTrailingHr(parts[i].trim());
      if (chunk.isEmpty) continue;

      if (i == 0 && !chunk.startsWith('## ')) {
        final lines = chunk.split('\n');
        final quoteLines = <String>[];
        final otherLines = <String>[];

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('>')) {
            quoteLines.add(trimmed.replaceFirst(RegExp(r'^>\s*'), ''));
          } else {
            otherLines.add(line);
          }
        }

        if (quoteLines.isNotEmpty) {
          keyTakeaway = quoteLines
              .join(' ')
              .replaceAll('**Intisari Konsep:**', '')
              .replaceAll('**Intisari Konsep**:', '')
              .replaceAll('Intisari Konsep:', '')
              .trim();
        }
        final remaining = _stripTrailingHr(otherLines.join('\n').trim());
        if (remaining.isNotEmpty) {
          introMd = remaining;
        }
      } else {
        final lines = chunk.split('\n');
        final rawHeading = lines.first.replaceFirst(RegExp(r'^##\s+'), '').trim();
        final numberMatch = RegExp(r'^(\d+)\.\s*(.+)$').firstMatch(rawHeading);
        final chapterIndex = chapters.length + 1;
        final numberLabel = numberMatch != null
            ? 'BAGIAN ${numberMatch.group(1)}'
            : 'BAGIAN $chapterIndex';
        final cleanTitle = _cleanMarkdownInline(
          numberMatch != null ? numberMatch.group(2)!.trim() : rawHeading,
        );
        final bodyMd = _stripTrailingHr(lines.skip(1).join('\n').trim());

        chapters.add(
          _parseChapter(
            numberLabel: numberLabel,
            title: cleanTitle,
            rawBodyMd: bodyMd,
          ),
        );
      }
    }

    return ParsedLearningMaterial(
      keyTakeaway: keyTakeaway,
      introMd: introMd,
      chapters: chapters,
      references: references,
      referencesHeading: referencesHeading,
    );
  }

  static MaterialChapterContent _parseChapter({
    required String numberLabel,
    required String title,
    required String rawBodyMd,
  }) {
    final navLabel = _buildShortNavLabel(title);

    // Cek 1: apakah bagian memiliki tabel Markdown?
    final tableExtract = _extractMarkdownTable(rawBodyMd);
    if (tableExtract != null) {
      String? remainingAfterTable = tableExtract.afterMd;
      var tableTabs = const <MaterialSegmentedTab>[];

      if (remainingAfterTable != null && remainingAfterTable.isNotEmpty) {
        final subSections = _extractTwoSubsections(remainingAfterTable);
        if (subSections != null) {
          remainingAfterTable = subSections.leadMd;
          tableTabs = subSections.tabs;
        } else {
          final lowerTitle = title.toLowerCase();
          final lowerAfter = remainingAfterTable.toLowerCase();
          if (lowerTitle.contains('inovasi') ||
              lowerTitle.contains('pendekatan') ||
              lowerTitle.contains('penerapan') ||
              lowerAfter.contains('inovasi') ||
              lowerAfter.contains('pendekatan')) {
            final twoBullets = _extractTwoBoldBullets(remainingAfterTable);
            if (twoBullets != null) {
              remainingAfterTable = twoBullets.leadMd;
              tableTabs = twoBullets.tabs;
            }
          }
        }
      }

      return MaterialChapterContent(
        numberLabel: numberLabel,
        title: title,
        navLabel: navLabel,
        rawBodyMd: rawBodyMd,
        leadMd: tableExtract.beforeMd,
        table: tableExtract.table,
        afterTableMd: remainingAfterTable,
        segmentedTabs: tableTabs,
      );
    }

    // Cek 2: apakah bagian memiliki tepat 2 sub-bagian `### A.` dan `### B.`?
    final subSections = _extractTwoSubsections(rawBodyMd);
    if (subSections != null) {
      return MaterialChapterContent(
        numberLabel: numberLabel,
        title: title,
        navLabel: navLabel,
        rawBodyMd: rawBodyMd,
        leadMd: subSections.leadMd,
        segmentedTabs: subSections.tabs,
      );
    }

    // Cek 3: apakah bagian membandingkan Keunggulan vs Tantangan / Perhatian?
    final proCon = _extractProConPair(rawBodyMd);
    if (proCon != null) {
      return MaterialChapterContent(
        numberLabel: numberLabel,
        title: title,
        navLabel: 'Plus & minus',
        rawBodyMd: rawBodyMd,
        proConPair: proCon,
      );
    }

    // Cek 4: bagian inovasi/pendekatan dengan 2 bullet kontras utama (mis. PLTS Terapung vs Darat)
    if (title.toLowerCase().contains('inovasi') ||
        title.toLowerCase().contains('pendekatan')) {
      final twoBullets = _extractTwoBoldBullets(rawBodyMd);
      if (twoBullets != null) {
        return MaterialChapterContent(
          numberLabel: numberLabel,
          title: title,
          navLabel: navLabel,
          rawBodyMd: rawBodyMd,
          leadMd: twoBullets.leadMd,
          segmentedTabs: twoBullets.tabs,
        );
      }
    }

    return MaterialChapterContent(
      numberLabel: numberLabel,
      title: title,
      navLabel: navLabel,
      rawBodyMd: rawBodyMd,
      leadMd: rawBodyMd,
    );
  }

  static String _buildShortNavLabel(String title) {
    final lower = _cleanMarkdownInline(title).toLowerCase();
    if (lower.startsWith('mengapa')) return 'Mengapa EBT';
    if (lower.contains('alur') || lower.contains('komponen & tahapan')) {
      return 'Cara kerja';
    }
    if (lower.contains('teknologi utama') || lower.contains('anatomi')) {
      return 'Teknologi';
    }
    if (lower.contains('dua jalur') || lower.contains('dua teknologi')) {
      return 'Teknologi';
    }
    if (lower.contains('sumur injeksi')) return 'Reinjeksi';
    if (lower.contains('inovasi')) return 'Inovasi';
    if (lower.contains('keunggulan') ||
        lower.contains('kelebihan') ||
        lower.contains('trade-off')) {
      return 'Plus & minus';
    }
    if (lower.contains('peta ') ||
        lower.contains('sebaran') ||
        lower.contains('peran plta') ||
        lower.contains('studi kasus')) {
      return 'Di Indonesia';
    }
    if (lower.contains('kurva bebek')) return 'Kurva Bebek';
    if (lower.contains('sinergi')) return 'Sinergi 5 EBT';
    if (lower.contains('kesimpulan')) return 'Kesimpulan';

    final clean = _cleanMarkdownInline(title);
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 2) return clean;
    return '${words[0]} ${words[1]}';
  }

  static ({String? beforeMd, MaterialTableData table, String? afterMd})?
  _extractMarkdownTable(String md) {
    final lines = md.split('\n');
    int? startIdx;
    int? endIdx;

    for (var i = 0; i < lines.length - 1; i++) {
      final curr = lines[i].trim();
      final next = lines[i + 1].trim();
      if (curr.startsWith('|') &&
          curr.endsWith('|') &&
          RegExp(r'^\|[\s:\-\|]+\|$').hasMatch(next)) {
        startIdx = i;
        endIdx = i + 1;
        for (var j = i + 2; j < lines.length; j++) {
          final rowLine = lines[j].trim();
          if (rowLine.startsWith('|') && rowLine.contains('|')) {
            endIdx = j;
          } else {
            break;
          }
        }
        break;
      }
    }

    if (startIdx == null || endIdx == null || endIdx <= startIdx + 1) {
      return null;
    }

    List<String> splitRow(String line) {
      var s = line.trim();
      if (s.startsWith('|')) s = s.substring(1);
      if (s.endsWith('|')) s = s.substring(0, s.length - 1);
      return s.split('|').map((c) => _cleanMarkdownInline(c.trim())).toList();
    }

    final headers = splitRow(lines[startIdx]);
    final rows = <List<String>>[];
    for (var k = startIdx + 2; k <= endIdx; k++) {
      final cells = splitRow(lines[k]);
      if (cells.isNotEmpty) rows.add(cells);
    }
    if (headers.isEmpty || rows.isEmpty) return null;

    final before = _stripTrailingHr(lines.take(startIdx).join('\n').trim());
    final after = _stripTrailingHr(lines.skip(endIdx + 1).join('\n').trim());

    return (
      beforeMd: before.isEmpty ? null : before,
      table: MaterialTableData(headers: headers, rows: rows),
      afterMd: after.isEmpty ? null : after,
    );
  }

  static ({String? leadMd, List<MaterialSegmentedTab> tabs})?
  _extractTwoSubsections(String md) {
    final parts = md.split(RegExp(r'\n(?=###\s+)'));
    final subChunks = parts.where((p) => p.trim().startsWith('### ')).toList();
    if (subChunks.length != 2) return null;

    final lead = !parts.first.trim().startsWith('### ')
        ? _stripTrailingHr(parts.first.trim())
        : null;

    final tabs = subChunks.map((chunk) {
      final lines = chunk.trim().split('\n');
      final rawTitle = lines.first.replaceFirst(RegExp(r'^###\s+'), '').trim();
      final shortLabel = _shortSubsectionTabLabel(rawTitle);
      final body = lines.skip(1).join('\n').trim();
      return MaterialSegmentedTab(
        label: shortLabel,
        bodyMd: '**$rawTitle**\n\n$body',
      );
    }).toList();

    return (
      leadMd: (lead != null && lead.isNotEmpty) ? lead : null,
      tabs: tabs,
    );
  }

  static String _shortSubsectionTabLabel(String rawHeading) {
    var s = _cleanMarkdownInline(rawHeading);
    s = s.replaceFirst(RegExp(r'^[A-Z]\.\s*'), '');
    final dashIdx = s.indexOf('—');
    if (dashIdx > 0) {
      s = s.substring(0, dashIdx).trim();
    }
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(s);
    if (s.length > 24 && parenMatch != null) {
      final abbr = parenMatch.group(1)!.trim();
      if (abbr.length >= 2 && abbr.length <= 12) {
        final beforeParen = s.split('(').first.trim();
        final firstWord = beforeParen.split(' ').first;
        return '$abbr ($firstWord)';
      }
    }
    if (s.length > 24) {
      return s.split('(').first.trim();
    }
    return s;
  }

  static MaterialProConPair? _extractProConPair(String md) {
    final lines = md
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;

    ({String label, String body})? parseBullet(String line) {
      final match = RegExp(
        r'^-\s+\*\*([^*]+?)\*\*:?\s*(.+)$',
      ).firstMatch(line);
      if (match == null) return null;
      final label = _cleanMarkdownInline(match.group(1)!.replaceAll(':', '').trim());
      final body = match.group(2)!.trim();
      return (label: label, body: body);
    }

    final first = parseBullet(lines[0]);
    final second = parseBullet(lines[1]);
    if (first == null || second == null) return null;

    final l1 = first.label.toLowerCase();
    final l2 = second.label.toLowerCase();
    final isPro1 = l1.contains('keunggulan') || l1.contains('kelebihan');
    final isCon2 =
        l2.contains('tantangan') ||
        l2.contains('perhatian') ||
        l2.contains('risiko');
    if (!isPro1 || !isCon2) return null;

    final extraLines = lines.skip(2).join('\n\n').trim();
    return MaterialProConPair(
      proTitle: first.label,
      proBodyMd: first.body,
      conTitle: second.label,
      conBodyMd: second.body,
      extraMd: extraLines.isEmpty ? null : extraLines,
    );
  }

  static ({String? leadMd, List<MaterialSegmentedTab> tabs})?
  _extractTwoBoldBullets(String md) {
    final lines = md.split('\n');
    final bulletLines = <int>[];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('- **')) {
        bulletLines.add(i);
      }
    }
    if (bulletLines.length != 2) return null;
    if (bulletLines.last != lines.length - 1 ||
        bulletLines[1] - bulletLines[0] > 2) {
      return null;
    }

    final tabs = <MaterialSegmentedTab>[];
    for (final idx in bulletLines) {
      final match = RegExp(
        r'^-\s+\*\*([^*]+?)\*\*:?\s*(.+)$',
      ).firstMatch(lines[idx].trim());
      if (match == null) return null;
      final fullTitle = _cleanMarkdownInline(
        match.group(1)!.replaceAll(':', '').trim(),
      );
      final shortTab = fullTitle
          .replaceFirst(RegExp(r'\s*\([^)]*\).*$'), '')
          .split('&')
          .first
          .trim();
      final body = match.group(2)!.trim();
      tabs.add(
        MaterialSegmentedTab(
          label: shortTab.isEmpty ? fullTitle : shortTab,
          bodyMd: '**$fullTitle:** $body',
        ),
      );
    }

    final lead = _stripTrailingHr(
      lines.take(bulletLines.first).join('\n').trim(),
    );
    return (leadMd: lead.isEmpty ? null : lead, tabs: tabs);
  }

  static List<MaterialReferenceItem> _parseReferences(String refBody) {
    final items = <MaterialReferenceItem>[];
    for (final rawLine in refBody.split('\n')) {
      final line = rawLine.trim();
      if (!line.startsWith('-')) continue;
      final content = line.replaceFirst(RegExp(r'^-\s*'), '').trim();

      // Format: [Label](url) atau [Label](url): deskripsi
      final linkMatch = RegExp(
        r'\[([^\]]+)\]\((https?://[^)\s]+)\)(.*)',
      ).firstMatch(content);
      if (linkMatch != null) {
        final label = _cleanMarkdownInline(linkMatch.group(1)!.trim());
        final url = linkMatch.group(2)!.trim();
        final tail = _cleanMarkdownInline(
          (linkMatch.group(3) ?? '').replaceFirst(RegExp(r'^[:\s—-]+'), '').trim(),
        );
        items.add(
          MaterialReferenceItem(
            label: tail.isNotEmpty ? '$label — $tail' : label,
            url: url,
          ),
        );
      } else {
        items.add(
          MaterialReferenceItem(label: _cleanMarkdownInline(content)),
        );
      }
    }
    return items;
  }

  static String _cleanMarkdownInline(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static String _stripTrailingHr(String text) {
    return text.replaceFirst(RegExp(r'(\n---+\s*)+$'), '').trim();
  }
}
