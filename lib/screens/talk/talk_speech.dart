import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Web `norm(s)`: lower-case, keep only a–z, apostrophes and spaces,
/// collapse whitespace.
String talkNorm(String? s) => (s ?? '')
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z' ]"), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Web `r.onresult` judgement: the target phrase appears in what was heard,
/// or at least 60% of its words appear (substring test, like `indexOf`).
bool talkMatches(String target, String heard) {
  final t = talkNorm(target);
  final h = talkNorm(heard);
  final tw = t.split(' ');
  var hit = 0;
  for (final w in tw) {
    if (h.contains(w)) hit++;
  }
  return h.contains(t) || (tw.isNotEmpty && hit / tw.length >= 0.6);
}

/// Outcome of one listening attempt.
sealed class HearOutcome {
  const HearOutcome();
}

/// Web `onresult`: [heard] is the web's joined alternatives (max 3).
class Heard extends HearOutcome {
  const Heard(this.heard);
  final String heard;
}

/// Web `onerror` (no speech, denied permission, network…).
class HearError extends HearOutcome {
  const HearError();
}

/// Web `!SR`: this device has no speech recognizer at all.
class HearUnavailable extends HearOutcome {
  const HearUnavailable();
}

/// Thin wrapper over [SpeechToText] that behaves like one web
/// `new SpeechRecognition()` session: en-US, final results only, up to three
/// alternatives, exactly one outcome per [listen].
class TalkRecognizer {
  TalkRecognizer();

  final SpeechToText _stt = SpeechToText();
  bool? _available;
  Completer<HearOutcome>? _pending;

  /// Mic input level, 0‥1 (auto-ranged per platform), for the UI pulse.
  final ValueNotifier<double> level = ValueNotifier(0);
  double _lo = double.infinity;
  double _hi = double.negativeInfinity;

  /// `false` once initialisation has reported no recognizer.
  bool? get available => _available;

  /// Debug hook (dev builds / tests): completes the running attempt as if
  /// [text] had been recognised.
  void debugHear(String text) => _finish(Heard(text));

  /// Dev builds without a microphone: [listen] waits for [debugHear] and
  /// feeds a synthetic input level instead of opening the recognizer.
  @visibleForTesting
  static bool debugFakeMic = false;
  Timer? _fakeLevel;

  Future<bool> _init() async {
    if (_available == true) return true;
    try {
      _available = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
    } catch (e) {
      debugPrint('speech init failed: $e');
      _available = false;
    }
    return _available!;
  }

  /// One listening attempt. Completes with exactly one [HearOutcome].
  Future<HearOutcome> listen() async {
    await cancel();
    final c = Completer<HearOutcome>();
    _pending = c;
    _lo = double.infinity;
    _hi = double.negativeInfinity;
    level.value = 0;
    if (debugFakeMic) {
      var t = 0.0;
      _fakeLevel = Timer.periodic(const Duration(milliseconds: 50), (_) {
        t += 0.05;
        _onLevel(5 + 5 * math.sin(t * 7) * math.sin(t * 2.3));
      });
      return c.future;
    }
    if (!await _init()) {
      _finish(const HearUnavailable());
      return c.future;
    }
    if (!identical(_pending, c)) return c.future;
    try {
      await _stt.listen(
        onResult: _onResult,
        onSoundLevelChange: _onLevel,
        listenOptions: SpeechListenOptions(
          localeId: 'en_US',
          partialResults: false, // web interimResults=false
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('speech listen failed: $e');
      _finish(const HearError());
    }
    return c.future;
  }

  void _onResult(SpeechRecognitionResult r) {
    if (!r.finalResult) return;
    // Web: heard += ' ' + each of up to 3 alternatives' transcripts.
    final alts = r.alternates.take(3).map((a) => a.recognizedWords);
    // iOS may send typographic apostrophes; Chrome sends plain ones.
    final heard = alts.map((a) => ' $a').join().replaceAll('’', "'");
    if (heard.trim().isEmpty) {
      _finish(const HearError());
    } else {
      _finish(Heard(heard));
    }
  }

  void _onError(SpeechRecognitionError e) {
    debugPrint('speech error: ${e.errorMsg}');
    _finish(const HearError());
  }

  void _onStatus(String status) {
    // Finished without a final result → treat like Chrome's "no-speech".
    final c = _pending;
    if (status == SpeechToText.doneStatus && c != null) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (identical(_pending, c)) _finish(const HearError());
      });
    }
  }

  void _onLevel(double v) {
    _lo = math.min(_lo, v);
    _hi = math.max(_hi, v);
    final span = _hi - _lo;
    final n = span < 1e-3 ? 0.0 : ((v - _lo) / span).clamp(0.0, 1.0);
    // Smooth so the pulse glides instead of flickering.
    level.value = level.value * 0.55 + n * 0.45;
  }

  void _finish(HearOutcome o) {
    final c = _pending;
    if (c == null || c.isCompleted) return;
    _pending = null;
    _fakeLevel?.cancel();
    level.value = 0;
    c.complete(o);
    if (_stt.isListening) unawaited(_stt.stop());
  }

  bool get isBusy => _pending != null;

  /// Abandons the running attempt without reporting an outcome.
  Future<void> cancel() async {
    _pending = null;
    _fakeLevel?.cancel();
    level.value = 0;
    try {
      if (_stt.isListening) await _stt.cancel();
    } catch (_) {}
  }

  void dispose() {
    unawaited(cancel());
    level.dispose();
  }
}
