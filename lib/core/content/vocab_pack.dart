import 'dart:convert';

/// One vocabulary word — editable via JSON (client can change later).
class VocabItem {
  const VocabItem({
    required this.id,
    required this.w,
    required this.ja,
    required this.lv,
    this.img,
    this.voice,
  });

  final int id;
  final String w;
  final String ja;
  final int lv; // 5 / 4 / 3
  final String? img; // relative asset path without "assets/"
  final String? voice;

  factory VocabItem.fromJson(Map<String, dynamic> j) => VocabItem(
        id: j['id'] as int,
        w: j['w'] as String,
        ja: j['ja'] as String,
        lv: j['lv'] as int,
        img: j['img'] as String?,
        voice: j['voice'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'w': w,
        'ja': ja,
        'lv': lv,
        if (img != null) 'img': img,
        if (voice != null) 'voice': voice,
      };
}

class VocabPack {
  const VocabPack({
    required this.version,
    required this.qn,
    required this.timeByLevel,
    required this.winRatio,
    required this.items,
  });

  final int version;
  final int qn;
  final Map<int, int> timeByLevel;
  final double winRatio;
  final List<VocabItem> items;

  factory VocabPack.fromJson(Map<String, dynamic> j) {
    final tb = j['timeByLevel'] as Map<String, dynamic>? ?? {};
    return VocabPack(
      version: j['version'] as int? ?? 1,
      qn: j['qn'] as int? ?? 10,
      timeByLevel: {
        for (final e in tb.entries) int.parse(e.key): e.value as int,
      },
      winRatio: (j['winRatio'] as num?)?.toDouble() ?? 0.6,
      items: (j['items'] as List<dynamic>)
          .map((e) => VocabItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<VocabItem> forGrade(int kyu) =>
      items.where((e) => e.lv == kyu).toList();

  static VocabPack fromJsonString(String s) =>
      VocabPack.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
