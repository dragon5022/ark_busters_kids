import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';

/// BGM, sound effects, recorded voice clips and English TTS for all games.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const hubBgmAsset = 'audio/bgm/bgm-top.mp3';
  static const battleBgmAsset = 'audio/bgm/bgm-battle.mp3';
  static const hubBgmVolume = 0.4;
  static const battleBgmVolume = 0.35;

  final AudioPlayer _bgm = AudioPlayer();
  final AudioPlayer _voice = AudioPlayer();

  /// One player per effect, like the web's `__sfx[name]` Audio cache, so a
  /// correct.mp3 and its synthesized chime can overlap.
  final Map<String, AudioPlayer> _sfx = {};

  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  bool _bgmOn = true;
  String? _bgmAsset;

  bool get isBgmOn => _bgmOn;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setPlayerMode(PlayerMode.mediaPlayer);
    await _voice.setPlayerMode(PlayerMode.mediaPlayer);
    final prefs = await SharedPreferences.getInstance();
    _bgmOn = prefs.getString('ark_bgm') != '0';
    await _initTts();
  }

  // ---------------------------------------------------------------- BGM

  Future<void> playHubBgm() => _playBgm(hubBgmAsset, hubBgmVolume);

  Future<void> playBattleBgm() => _playBgm(battleBgmAsset, battleBgmVolume);

  Future<void> _playBgm(String asset, double volume) async {
    await init();
    _bgmAsset = asset;
    if (!_bgmOn) return;
    try {
      await _bgm.stop();
      await _bgm.setVolume(volume);
      await _bgm.play(AssetSource(asset));
    } catch (e) {
      debugPrint('bgm $asset failed: $e');
    }
  }

  Future<void> toggleBgm() async {
    await init();
    _bgmOn = !_bgmOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ark_bgm', _bgmOn ? '1' : '0');
    if (_bgmOn) {
      await _playBgm(
        _bgmAsset ?? hubBgmAsset,
        _bgmAsset == battleBgmAsset ? battleBgmVolume : hubBgmVolume,
      );
    } else {
      await _bgm.stop();
    }
  }

  Future<void> stopBgm() async {
    await init();
    await _bgm.stop();
  }

  /// Web `bgm.volume = …`: e.g. duck the battle music to 0.17 during a
  /// round and restore [battleBgmVolume] afterwards.
  Future<void> setBgmVolume(double volume) async {
    await init();
    await _bgm.setVolume(volume.clamp(0.0, 1.0));
  }

  // ------------------------------------------------------ sound effects

  /// Web `sfxMp3(name, vol)`: music/{name}.mp3 — respects ark_se.
  Future<void> playSfx(String name, {double volume = 0.75}) =>
      _effect('audio/sfx/$name.mp3', volume);

  /// Synthesized web `tone()` chimes, pre-rendered by tools/gen_tones.py:
  /// tone_ok, tone_ok_sparkle, tone_ng, tone_wrong, tone_fanfare, tone_timeup.
  Future<void> playTone(String name) => _effect('audio/sfx/$name.wav', 1);

  Future<void> _effect(String asset, double volume) async {
    await init();
    if (!await ProgressService.instance.isSeOn()) return;
    try {
      final p = _sfx.putIfAbsent(asset, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await p.stop();
      await p.setVolume(volume);
      await p.play(AssetSource(asset));
    } catch (e) {
      debugPrint('sfx $asset failed: $e');
    }
  }

  /// Web `readyGo(onStart)`: plays "Are you ready? Go!" and completes one
  /// second after it ends (TTS fallback if the clip can't play). [onGo]
  /// fires when the voice finishes, at the start of that last second.
  Future<void> readyGo({VoidCallback? onGo}) async {
    await init();
    final done = Completer<void>();
    final p = AudioPlayer();
    StreamSubscription<void>? sub;
    sub = p.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await p.setVolume(1);
      await p.play(AssetSource('audio/sfx/ready-go.mp3'));
    } catch (_) {
      await speak('Are you ready? Go!', pitch: 1.6, rate: 1, force: true);
      if (!done.isCompleted) done.complete();
    }
    // Never hang the game if completion is not reported.
    await done.future.timeout(const Duration(milliseconds: 2600), onTimeout: () {});
    await sub.cancel();
    unawaited(p.dispose());
    onGo?.call();
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  // ------------------------------------------------------------- voice

  /// Recorded clip; asset path without the `assets/` prefix. Respects ark_voice.
  ///
  /// With [overlap], the clip plays on its own short-lived player without
  /// cutting off other voices (web `new Audio(src).play()` per tap).
  Future<void> playVoiceAsset(String? assetPath, {bool overlap = false}) async {
    if (assetPath == null || assetPath.isEmpty) return;
    await init();
    if (!await ProgressService.instance.isVoiceOn()) return;
    if (overlap) {
      final p = AudioPlayer();
      p.onPlayerComplete.first.then((_) => p.dispose());
      try {
        await p.play(AssetSource(assetPath));
      } catch (e) {
        debugPrint('voice $assetPath failed: $e');
        unawaited(p.dispose());
      }
      return;
    }
    try {
      await _tts.stop();
      await _voice.stop();
      await _voice.setVolume(1);
      await _voice.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('voice $assetPath failed: $e');
    }
  }

  Future<void> stopVoice() async {
    await _voice.stop();
    await _tts.stop();
  }

  /// Web `speak(t)`: en-US, rate .86, pitch 1.9, a female voice if available.
  /// Respects ark_voice unless [force] (used for the ready-go fallback).
  Future<void> speak(
    String text, {
    double rate = 0.86,
    double pitch = 1.9,
    bool force = false,
  }) async {
    if (text.isEmpty) return;
    await init();
    if (!force && !await ProgressService.instance.isVoiceOn()) return;
    try {
      await _voice.stop();
      await _tts.stop();
      await _tts.setSpeechRate(_normalRate * rate);
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
      await _tts.speak(text);
    } catch (e) {
      debugPrint('tts failed: $e');
    }
  }

  /// flutter_tts' "normal" speed differs by platform (web 1.0, mobile 0.5).
  double get _normalRate => kIsWeb ? 1.0 : 0.5;

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setVolume(1);
      // Web loadVoice(): prefer a female English voice.
      final voices = await _tts.getVoices;
      if (voices is List) {
        final en = voices
            .whereType<Map>()
            .where((v) => '${v['locale']}'.toLowerCase().startsWith('en'))
            .toList();
        final female = RegExp(
          'female|samantha|victoria|karen|moira|tessa|fiona|zira|susan|aria|jenny|google us english',
          caseSensitive: false,
        );
        final pick = en.firstWhere(
          (v) => female.hasMatch('${v['name']}'),
          orElse: () => en.firstWhere(
            (v) => '${v['locale']}'.toLowerCase().replaceAll('_', '-') == 'en-us',
            orElse: () => en.isEmpty ? const {} : en.first,
          ),
        );
        if (pick.isNotEmpty) {
          await _tts.setVoice({
            'name': '${pick['name']}',
            'locale': '${pick['locale']}',
          });
        }
      }
    } catch (e) {
      debugPrint('tts init failed: $e');
    }
  }
}
