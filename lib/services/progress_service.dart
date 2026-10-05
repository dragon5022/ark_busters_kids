import 'dart:convert';
import 'dart:math';

import 'package:ark_core/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/progress/progress_keys.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  SharedPreferences? _prefs;
  final _rng = Random();

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Bumps when progress changed outside the current screen (e.g. pulled
  /// from the cloud on another device); screens can listen and reload.
  final ValueNotifier<int> changes = ValueNotifier(0);

  void notifyExternalChange() => changes.value++;

  /// Saved progress changed: schedule a cloud sync (no-op when logged out).
  void _changed() => ArkAuth.instance.notifyProgressChanged();

  Future<String> getPlayerName() async =>
      (await _p).getString(ProgressKeys.playerName) ?? '';

  Future<void> setPlayerName(String name) async {
    final n = name.trim();
    await (await _p).setString(
      ProgressKeys.playerName,
      n.length > 12 ? n.substring(0, 12) : n,
    );
    _changed();
  }

  Future<bool> isSeOn() async =>
      (await _p).getString(ProgressKeys.seEnabled) != '0';

  Future<void> setSeOn(bool on) async =>
      (await _p).setString(ProgressKeys.seEnabled, on ? '1' : '0');

  Future<bool> isVoiceOn() async =>
      (await _p).getString(ProgressKeys.voiceEnabled) != '0';

  Future<void> setVoiceOn(bool on) async =>
      (await _p).setString(ProgressKeys.voiceEnabled, on ? '1' : '0');

  /// Web `ark_story_seen`: the intro story opens automatically until closed.
  Future<bool> isStorySeen() async =>
      (await _p).getString(ProgressKeys.storySeen) == '1';

  Future<void> setStorySeen() async {
    await (await _p).setString(ProgressKeys.storySeen, '1');
    _changed();
  }

  Future<bool> isStory2Seen() async =>
      (await _p).getString(ProgressKeys.story2Seen) == '1';

  Future<void> setStory2Seen() async {
    await (await _p).setString(ProgressKeys.story2Seen, '1');
    _changed();
  }

  static const monsterKeys = ['vocamon', 'lismon', 'gramon', 'talkmon'];

  /// Web `STORY2_NEED`: half of 4 monsters × 30 pose cards.
  static const story2Need = 60;

  /// Web `arkCardCount()`: pose cards collected across all monsters.
  Future<int> totalCards() async {
    var n = 0;
    for (final k in monsterKeys) {
      n += (await cards(k)).length;
    }
    return n;
  }

  Future<int> bestScore(String key) async => (await _p).getInt(key) ?? 0;

  Future<void> setBestIfHigher(String key, int score) async {
    final cur = await bestScore(key);
    if (score > cur) {
      await (await _p).setInt(key, score);
      _changed();
    }
  }

  Future<List<String>> friends() async {
    final raw = (await _p).getString(ProgressKeys.friends);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> befriend(String monsterKey) async {
    final list = await friends();
    if (list.contains(monsterKey)) return;
    list.add(monsterKey);
    await (await _p).setString(ProgressKeys.friends, jsonEncode(list));
    _changed();
  }

  Future<int> sRankCount(String monsterKey) async =>
      (await _p).getInt(ProgressKeys.sRankCount(monsterKey)) ?? 0;

  /// Web `arkSet('ark_s_'+key, getS(key)+1)` after an S rank.
  Future<void> addSRank(String monsterKey) async {
    final n = await sRankCount(monsterKey);
    await (await _p).setInt(ProgressKeys.sRankCount(monsterKey), n + 1);
    _changed();
  }

  /// Web `awardCards(key)`: one pose card per 10 S ranks (max 30). Returns
  /// the newly drawn card numbers so the result screen can show them.
  Future<List<int>> awardCards(String monsterKey) async {
    final earned = ((await sRankCount(monsterKey)) ~/ 10).clamp(0, 30);
    final owned = await cards(monsterKey);
    final got = <int>[];
    while (owned.length < earned) {
      final c = _drawCard(owned);
      if (c == null) break;
      owned.add(c);
      got.add(c);
    }
    if (got.isNotEmpty) {
      await (await _p).setString(
        ProgressKeys.cards(monsterKey),
        jsonEncode(owned),
      );
      _changed();
    }
    return got;
  }

  /// Web `drawCard`: weighted pick of an unowned card — #29–30 (SR) weight 1,
  /// #26–28 (レア) weight 3, others 10.
  int? _drawCard(List<int> owned) {
    final pool = <int>[];
    for (var i = 1; i <= 30; i++) {
      if (owned.contains(i)) continue;
      final w = i >= 29 ? 1 : (i >= 26 ? 3 : 10);
      for (var k = 0; k < w; k++) {
        pool.add(i);
      }
    }
    if (pool.isEmpty) return null;
    return pool[_rng.nextInt(pool.length)];
  }

  /// Rarity label shown on new cards (web showNewCards).
  static String rarity(int card) => card >= 29 ? 'SR' : (card >= 26 ? 'レア' : '');

  Future<List<int>> cards(String monsterKey) async {
    final raw = (await _p).getString(ProgressKeys.cards(monsterKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) => e as int).toList();
    } catch (_) {
      return [];
    }
  }
}
