import 'dart:async';

import 'package:ark_core/content.dart';
import 'package:flutter/foundation.dart';

import '../core/content/game_packs.dart';
import '../core/content/vocab_pack.dart';

/// Question packs for the four games.
///
/// Packs come from [ArkContent]: the copy last downloaded from the school's
/// Google Sheet if there is one, otherwise the JSON bundled in the app.
/// The sheet is configured in `assets/data/content_source.json`; see
/// `ark_core/doc/CONTENT_SHEETS.md` for how 藤井先生 edits questions.
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  /// Bump when a release changes the pack JSON format; sheets can then
  /// require it with the manifest's `minAppBuild` column.
  static const contentFormatBuild = 1;

  static const _packs = {
    'vocab': 'assets/data/vocab.json',
    'listening': 'assets/data/listening.json',
    'talk': 'assets/data/talk.json',
    'sentence': 'assets/data/sentence.json',
  };

  VocabPack? _vocab;
  ListeningPack? _listening;
  TalkPack? _talk;
  SentencePack? _sentence;

  VocabPack? get vocab => _vocab;
  ListeningPack? get listening => _listening;
  TalkPack? get talk => _talk;
  SentencePack? get sentence => _sentence;

  Future<void> init() async {
    await ArkContent.instance.configure(
      appId: 'kids',
      bundledPacks: _packs,
      source: await ArkContent.sourceFromAsset('assets/data/content_source.json'),
      appBuild: contentFormatBuild,
      // A downloaded pack is only used if the game can read it.
      validators: {
        'vocab': (j) => VocabPack.fromJsonString(j).items.length >= 10,
        'listening': (j) => ListeningPack.fromJsonString(j).grades.isNotEmpty,
        'talk': (j) => TalkPack.fromJsonString(j).grades.isNotEmpty,
        'sentence': (j) => SentencePack.fromJsonString(j).grades.isNotEmpty,
      },
    );
    await _loadAll();
  }

  Future<void> _loadAll() async {
    _vocab = await loadVocab();
    _listening = await loadListening();
    _talk = await loadTalk();
    _sentence = await loadSentence();
  }

  Future<VocabPack> loadVocab() async =>
      VocabPack.fromJsonString(await ArkContent.instance.loadPack('vocab'));

  Future<ListeningPack> loadListening() async =>
      ListeningPack.fromJsonString(await ArkContent.instance.loadPack('listening'));

  Future<TalkPack> loadTalk() async =>
      TalkPack.fromJsonString(await ArkContent.instance.loadPack('talk'));

  Future<SentencePack> loadSentence() async =>
      SentencePack.fromJsonString(await ArkContent.instance.loadPack('sentence'));

  /// Checks the sheet for newer questions (at most every 30 minutes unless
  /// [force]); new questions are used from the next game. Never throws.
  Future<ContentUpdateReport> checkForUpdates({bool force = false}) async {
    final report = await ArkContent.instance.checkForUpdates(force: force);
    if (report.updated.isNotEmpty) {
      try {
        await _loadAll();
      } catch (e) {
        debugPrint('reload after update failed: $e');
      }
    }
    return report;
  }
}
