import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/content/game_packs.dart';
import '../core/content/vocab_pack.dart';

/// Loads question packs from cached remote updates, else bundled assets.
///
/// Remote URLs: assets/data/manifest.json → packs.*.url
class ContentRepository {
  ContentRepository._();
  static final ContentRepository instance = ContentRepository._();

  VocabPack? _vocab;
  ListeningPack? _listening;
  TalkPack? _talk;
  SentencePack? _sentence;
  Map<String, dynamic>? _manifest;

  VocabPack? get vocab => _vocab;
  ListeningPack? get listening => _listening;
  TalkPack? get talk => _talk;
  SentencePack? get sentence => _sentence;

  Future<void> init() async {
    await _loadManifest();
    _vocab = await loadVocab();
    _listening = await loadListening();
    _talk = await loadTalk();
    _sentence = await loadSentence();
  }

  Future<void> _loadManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/data/manifest.json');
      _manifest = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('manifest load failed: $e');
      _manifest = {};
    }
  }

  Future<VocabPack> loadVocab() async {
    final cached = await _readCachedJson('vocab.json');
    if (cached != null) {
      try {
        return VocabPack.fromJsonString(cached);
      } catch (e) {
        debugPrint('cached vocab corrupt: $e');
      }
    }
    final bundled = await rootBundle.loadString('assets/data/vocab.json');
    return VocabPack.fromJsonString(bundled);
  }

  Future<ListeningPack> loadListening() async {
    final cached = await _readCachedJson('listening.json');
    if (cached != null) {
      try {
        return ListeningPack.fromJsonString(cached);
      } catch (_) {}
    }
    final bundled = await rootBundle.loadString('assets/data/listening.json');
    return ListeningPack.fromJsonString(bundled);
  }

  Future<TalkPack> loadTalk() async {
    final cached = await _readCachedJson('talk.json');
    if (cached != null) {
      try {
        return TalkPack.fromJsonString(cached);
      } catch (_) {}
    }
    final bundled = await rootBundle.loadString('assets/data/talk.json');
    return TalkPack.fromJsonString(bundled);
  }

  Future<SentencePack> loadSentence() async {
    final cached = await _readCachedJson('sentence.json');
    if (cached != null) {
      try {
        return SentencePack.fromJsonString(cached);
      } catch (_) {}
    }
    final bundled = await rootBundle.loadString('assets/data/sentence.json');
    return SentencePack.fromJsonString(bundled);
  }

  /// Download packs that have a non-empty URL in the manifest.
  Future<bool> syncRemotePacks() async {
    await _loadManifest();
    final packs = _manifest?['packs'] as Map<String, dynamic>?;
    if (packs == null) return false;
    var any = false;
    for (final entry in packs.entries) {
      final meta = entry.value as Map<String, dynamic>;
      final url = meta['url'] as String? ?? '';
      if (url.isEmpty) continue;
      try {
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) continue;
        final body = utf8.decode(res.bodyBytes);
        final file = '${entry.key}.json';
        // validate by parsing
        switch (entry.key) {
          case 'vocab':
            _vocab = VocabPack.fromJsonString(body);
          case 'listening':
            _listening = ListeningPack.fromJsonString(body);
          case 'talk':
            _talk = TalkPack.fromJsonString(body);
          case 'sentence':
            _sentence = SentencePack.fromJsonString(body);
          default:
            continue;
        }
        await _writeCachedJson(file, body);
        any = true;
      } catch (e) {
        debugPrint('sync ${entry.key} failed: $e');
      }
    }
    return any;
  }

  Future<Directory> _cacheDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'content_packs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _readCachedJson(String name) async {
    try {
      final f = File(p.join((await _cacheDir()).path, name));
      if (await f.exists()) return await f.readAsString();
    } catch (_) {}
    return null;
  }

  Future<void> _writeCachedJson(String name, String body) async {
    final f = File(p.join((await _cacheDir()).path, name));
    await f.writeAsString(body);
  }
}
