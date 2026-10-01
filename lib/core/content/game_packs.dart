import 'dart:convert';

class ListeningItem {
  const ListeningItem({
    required this.id,
    required this.t,
    required this.en,
    required this.ja,
    required this.tip,
    required this.ans,
    required this.opts,
    this.q,
    this.voice,
  });

  final String id;
  final String t; // pic | text
  final String en;
  final String ja;
  final String tip;
  final String ans;
  final List<String> opts;
  final String? q;
  final String? voice;

  factory ListeningItem.fromJson(Map<String, dynamic> j) => ListeningItem(
        id: j['id'] as String,
        t: j['t'] as String? ?? 'pic',
        en: j['en'] as String? ?? '',
        ja: j['ja'] as String? ?? '',
        tip: j['tip'] as String? ?? '',
        ans: j['ans'] as String? ?? '',
        opts: (j['opts'] as List<dynamic>? ?? []).cast<String>(),
        q: j['q'] as String?,
        voice: j['voice'] as String?,
      );
}

class ListeningPack {
  const ListeningPack({
    required this.version,
    required this.qn,
    required this.winRatio,
    required this.timeByLevel,
    required this.livesByLevel,
    required this.grades,
  });

  final int version;
  final int qn;
  final double winRatio;
  final Map<int, int> timeByLevel;
  final Map<int, int> livesByLevel;
  final Map<String, Map<int, List<ListeningItem>>> grades;

  factory ListeningPack.fromJson(Map<String, dynamic> j) {
    final grades = <String, Map<int, List<ListeningItem>>>{};
    final g = j['grades'] as Map<String, dynamic>? ?? {};
    for (final ge in g.entries) {
      final levels = <int, List<ListeningItem>>{};
      final lvMap = (ge.value as Map<String, dynamic>)['levels'] as Map<String, dynamic>? ?? {};
      for (final le in lvMap.entries) {
        levels[int.parse(le.key)] = (le.value as List<dynamic>)
            .map((e) => ListeningItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      grades[ge.key] = levels;
    }
    Map<int, int> asIntMap(dynamic raw) {
      final m = raw as Map<String, dynamic>? ?? {};
      return {for (final e in m.entries) int.parse(e.key): e.value as int};
    }

    return ListeningPack(
      version: j['version'] as int? ?? 1,
      qn: j['qn'] as int? ?? 10,
      winRatio: (j['winRatio'] as num?)?.toDouble() ?? 0.6,
      timeByLevel: asIntMap(j['timeByLevel']),
      livesByLevel: asIntMap(j['livesByLevel']),
      grades: grades,
    );
  }

  static ListeningPack fromJsonString(String s) =>
      ListeningPack.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class TalkItem {
  const TalkItem({
    required this.id,
    required this.ja,
    required this.en,
    this.voice,
  });

  final String id;
  final String ja;
  final String en;
  final String? voice;

  factory TalkItem.fromJson(Map<String, dynamic> j) => TalkItem(
        id: j['id'] as String,
        ja: j['ja'] as String? ?? '',
        en: j['en'] as String? ?? '',
        voice: j['voice'] as String?,
      );
}

class TalkPack {
  const TalkPack({
    required this.version,
    required this.qn,
    required this.winRatio,
    required this.grades,
  });

  final int version;
  final int qn;
  final double winRatio;
  final Map<String, List<TalkItem>> grades;

  factory TalkPack.fromJson(Map<String, dynamic> j) {
    final grades = <String, List<TalkItem>>{};
    final g = j['grades'] as Map<String, dynamic>? ?? {};
    for (final e in g.entries) {
      grades[e.key] = (e.value as List<dynamic>)
          .map((x) => TalkItem.fromJson(x as Map<String, dynamic>))
          .toList();
    }
    return TalkPack(
      version: j['version'] as int? ?? 1,
      qn: j['qn'] as int? ?? 10,
      winRatio: (j['winRatio'] as num?)?.toDouble() ?? 0.6,
      grades: grades,
    );
  }

  static TalkPack fromJsonString(String s) =>
      TalkPack.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class SentenceJaPart {
  const SentenceJaPart({required this.t, required this.pick});
  final String t;
  final bool pick;
  factory SentenceJaPart.fromJson(Map<String, dynamic> j) => SentenceJaPart(
        t: j['t'] as String? ?? '',
        pick: j['pick'] as bool? ?? false,
      );
}

class SentenceWord {
  const SentenceWord({required this.w, required this.label, this.c});
  final String w;
  final String label;
  final String? c;
  factory SentenceWord.fromJson(Map<String, dynamic> j) => SentenceWord(
        w: j['w'] as String? ?? '',
        label: j['label'] as String? ?? '',
        c: j['c'] as String?,
      );
}

class SentenceItem {
  const SentenceItem({
    required this.id,
    required this.ja,
    required this.answer,
    required this.tip,
    this.voice,
  });

  final String id;
  final List<SentenceJaPart> ja;
  final List<SentenceWord> answer;
  final String tip;
  final String? voice;

  factory SentenceItem.fromJson(Map<String, dynamic> j) => SentenceItem(
        id: j['id'] as String,
        ja: (j['ja'] as List<dynamic>? ?? [])
            .map((e) => SentenceJaPart.fromJson(e as Map<String, dynamic>))
            .toList(),
        answer: (j['answer'] as List<dynamic>? ?? [])
            .map((e) => SentenceWord.fromJson(e as Map<String, dynamic>))
            .toList(),
        tip: j['tip'] as String? ?? '',
        voice: j['voice'] as String?,
      );
}

class SentencePack {
  const SentencePack({
    required this.version,
    required this.qn,
    required this.winRatio,
    required this.timeByGrade,
    required this.gramParts,
    required this.grades,
  });

  final int version;
  final int qn;
  final double winRatio;
  final Map<String, int> timeByGrade;
  final Map<String, int> gramParts;
  final Map<String, List<SentenceItem>> grades;

  factory SentencePack.fromJson(Map<String, dynamic> j) {
    final grades = <String, List<SentenceItem>>{};
    final g = j['grades'] as Map<String, dynamic>? ?? {};
    for (final e in g.entries) {
      grades[e.key] = (e.value as List<dynamic>)
          .map((x) => SentenceItem.fromJson(x as Map<String, dynamic>))
          .toList();
    }
    final tb = j['timeByGrade'] as Map<String, dynamic>? ?? {};
    final gp = j['gramParts'] as Map<String, dynamic>? ?? {};
    return SentencePack(
      version: j['version'] as int? ?? 1,
      qn: j['qn'] as int? ?? 10,
      winRatio: (j['winRatio'] as num?)?.toDouble() ?? 0.6,
      timeByGrade: {for (final e in tb.entries) e.key: e.value as int},
      gramParts: {for (final e in gp.entries) e.key: e.value as int},
      grades: grades,
    );
  }

  static SentencePack fromJsonString(String s) =>
      SentencePack.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// Shared S–F rank from clear ratio (10-Q modes).
String rankFromRatio(int cleared, int total) {
  if (total <= 0) return 'F';
  if (cleared >= total) return 'S';
  final r = cleared / total;
  if (r >= 0.9) return 'A';
  if (r >= 0.8) return 'B';
  if (r >= 0.6) return 'C';
  if (r >= 0.4) return 'D';
  if (r >= 0.2) return 'E';
  return 'F';
}

String rankFromEndless(int cleared) {
  if (cleared >= 20) return 'S';
  if (cleared >= 15) return 'A';
  if (cleared >= 10) return 'B';
  if (cleared >= 6) return 'C';
  if (cleared >= 3) return 'D';
  if (cleared >= 1) return 'E';
  return 'F';
}
