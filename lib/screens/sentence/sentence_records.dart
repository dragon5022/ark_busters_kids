import 'package:shared_preferences/shared_preferences.dart';

import '../../core/progress/progress_keys.dart';
import '../../services/progress_service.dart';

/// Web `getBest(k)` / `setBest(k,v)`: per-grade endless records stored under
/// the same localStorage-style names the web uses (`eb2_g5_endless`, …).
class SentenceRecords {
  SentenceRecords._();

  static const grades = ['g5', 'g4', 'g3'];

  static String _key(String k) => 'eb2_$k';

  static Future<int> getBest(String k) async {
    final p = await SharedPreferences.getInstance();
    return int.tryParse(p.getString(_key(k)) ?? '0') ?? 0;
  }

  static Future<void> setBest(String k, int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key(k), '$v');
  }

  /// Web `showBests()`: endless best per grade.
  static Future<Map<String, int>> endlessBests() async => {
    for (final g in grades) g: await getBest('${g}_endless'),
  };

  /// Web `updateBest(sc)` → `ark_best_sentence` (shown in the Profile panel).
  static Future<void> updateBest(int score) => ProgressService.instance
      .setBestIfHigher(ProgressKeys.bestSentence, score);
}
