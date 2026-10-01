import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/content/game_packs.dart';
import '../../core/progress/progress_keys.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/content_repository.dart';
import '../../services/progress_service.dart';
import '../../widgets/page_background.dart';
import 'talk_play.dart';
import 'talk_encounter.dart';
import 'talk_speech.dart';

/// Talk Buster (トークバスター) — port of talk-buster_無料版.html.
///
/// One page with three phases like the web (`#startScreen`, the play area,
/// `#endScreen`). Modes keep the web numbering:
/// 2 = STEP1 聞いてマネする, 3 = STEP2 マイクで言う, 1 = STEP3 えらんで言う.
class TalkHomeScreen extends StatefulWidget {
  const TalkHomeScreen({super.key});

  @override
  State<TalkHomeScreen> createState() => _TalkHomeScreenState();
}

/// Hooks for dev builds / widget tests (no microphone in headless runs).
@visibleForTesting
class TalkDebugHooks {
  /// Completes the running mic attempt as if [text] had been heard.
  void Function(String text)? hear;

  /// Ends the running game with [cleared] correct answers.
  void Function(int cleared)? end;

  /// Starts [mode] (web numbering) as if its card had been tapped.
  void Function(int mode)? start;
}

@visibleForTesting
final talkDebug = TalkDebugHooks();

enum _Phase { start, play, end }

const _grades = ['g5', 'g4', 'g3'];
const _qn = 10; // web QN

class _TalkHomeScreenState extends State<TalkHomeScreen> {
  TalkPack? _pack;
  _Phase _phase = _Phase.start;
  int _gradeIdx = 0;
  int _mode = 1;
  bool _rgLock = false;

  // game
  List<TalkItem> _questions = [];
  int _qi = 0;
  int _score = 0;
  int _cleared = 0;
  bool _locked = false;
  int _gen = 0; // invalidates pending timers / mic results

  // per question view state
  List<String> _options = [];
  String? _picked;
  bool _showSol = false;
  String _micnote = '';
  bool _showOkBtn = false;
  bool _listening = false;
  int _hits = 0;

  // end
  TalkEndData? _end;

  final _react = ReactionController();
  final _feedback = FeedbackController();
  final _rec = TalkRecognizer();
  final _rng = math.Random();

  String get _grade => _grades[_gradeIdx];
  TalkItem get _q => _questions[_qi];

  @override
  void initState() {
    super.initState();
    // Web: bgm-battle.mp3 plays on this page from load (start screen too).
    AudioService.instance.playBattleBgm();
    _load();
    talkDebug.hear = (t) => _rec.debugHear(t);
    talkDebug.start = (m) => _startMode(m);
    talkDebug.end = (c) {
      if (_phase != _Phase.play) return;
      _cleared = c;
      _score = c * 100;
      _qi = _questions.length;
      _endGame();
    };
  }

  Future<void> _load() async {
    final repo = ContentRepository.instance;
    final pack = repo.talk ?? await repo.loadTalk();
    if (mounted) setState(() => _pack = pack);
  }

  @override
  void dispose() {
    _gen++;
    talkDebug
      ..hear = null
      ..start = null
      ..end = null;
    _rec.dispose();
    _react.dispose();
    _feedback.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  // ------------------------------------------------------------ sounds

  void _sndCorrect() {
    AudioService.instance.playSfx('correct');
    _react.show(true);
    AudioService.instance.playTone('tone_ok');
  }

  void _sndWrong() {
    _react.show(false);
    AudioService.instance.playTone('tone_wrong');
  }

  /// Web `playTalk()`: the recorded clip voice/talk/N.mp3, else TTS.
  void _playTalk() {
    final q = _q;
    if (q.voice != null && q.voice!.isNotEmpty) {
      AudioService.instance.playVoiceAsset(q.voice);
    } else {
      // Web speak(): rate .82, pitch 1.35, lone "I" read as "i".
      AudioService.instance.speak(
        q.en.replaceAll(RegExp(r'\bI\b'), 'i'),
        rate: 0.82,
        pitch: 1.35,
      );
    }
  }

  // -------------------------------------------------------------- flow

  void _selectGrade(int i) {
    AudioService.instance.playSfx('start');
    setState(() => _gradeIdx = i);
  }

  /// Web `startMode(m)`, wrapped by the live site's encounter `readyGo`.
  Future<void> _startMode(int m) async {
    if (_rgLock || _pack == null) return;
    _rgLock = true;
    _gen++;
    unawaited(_rec.cancel());
    await showTalkEncounter(context);
    _rgLock = false;
    if (!mounted) return;
    AudioService.instance.playSfx('start');
    _mode = m;
    final pool = _pack!.grades[_grade] ?? const <TalkItem>[];
    if (pool.length < 4) {
      await showArkNotice(context, 'この級はまだじゅんびちゅうだよ');
      return;
    }
    final sh = List<TalkItem>.of(pool)..shuffle(_rng);
    _questions = [for (var i = 0; i < _qn; i++) sh[i % sh.length]];
    _qi = 0;
    _score = 0;
    _cleared = 0;
    _end = null;
    setState(() => _phase = _Phase.play);
    // Live: BGM ducks to .17 whenever #startScreen is hidden.
    AudioService.instance.setBgmVolume(0.17);
    _showQ();
  }

  void _showQ() {
    final gen = ++_gen;
    unawaited(_rec.cancel());
    final q = _q;
    setState(() {
      _locked = false;
      _picked = null;
      _showSol = false;
      _listening = false;
      _showOkBtn = false;
      _micnote = '';
      if (_mode == 1) {
        final others = (_pack!.grades[_grade]!
                .where((x) => x.en != q.en)
                .toList()
              ..shuffle(_rng))
            .take(3)
            .map((x) => x.en);
        _options = [q.en, ...others]..shuffle(_rng);
      } else if (_mode == 3 && _rec.available == false) {
        // Web `!SR`: no recognizer on this device.
        _micnote = '※このきたいではマイクがつかえないよ。聞いてマネしてね！';
        _showOkBtn = true;
      }
    });
    if (_mode == 2) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted && gen == _gen) _playTalk();
      });
    }
  }

  void _answer(bool ok, {String? picked}) {
    if (_locked) return;
    _locked = true;
    final gen = _gen;
    if (ok) {
      _score += 100;
      _cleared++;
      _sndCorrect();
      setState(() {
        _picked = picked;
        _hits++;
      });
      _feedback.pop('⭕ いいね！', const Color(0xFFFFE45E));
      _playTalk();
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && gen == _gen) _next();
      });
    } else {
      _sndWrong();
      setState(() {
        _picked = picked;
        _showSol = true;
      });
      _feedback.pop('❌ おしい！', const Color(0xFFFF9AA2));
      _playTalk();
    }
  }

  void _next() {
    _qi++;
    if (_qi < _questions.length) {
      _showQ();
    } else {
      _endGame();
    }
  }

  /// Web `startRecog(q)`.
  Future<void> _startRecog() async {
    if (_locked || _listening || _rec.available == false) return;
    final gen = _gen;
    final q = _q;
    setState(() {
      _listening = true;
      _micnote = '🎤 きいてるよ…話してね！';
    });
    // Don't let the model voice leak into the microphone.
    await AudioService.instance.stopVoice();
    final out = await _rec.listen();
    if (!mounted || gen != _gen) return;
    setState(() => _listening = false);
    switch (out) {
      case Heard(:final heard):
        setState(() => _micnote = 'きこえた："${heard.trim()}"');
        _answer(talkMatches(q.en, heard));
      case HearError():
        setState(() {
          _micnote = 'うまく聞き取れなかったよ。もう一度どうぞ（「言えた！」でもOK）';
          _showOkBtn = true;
        });
      case HearUnavailable():
        setState(() {
          _micnote = '※このきたいではマイクがつかえないよ。聞いてマネしてね！';
          _showOkBtn = true;
        });
    }
  }

  Future<void> _endGame() async {
    _gen++;
    unawaited(_rec.cancel());
    final total = _questions.length;
    final ratio = total > 0 ? _cleared / total : 0.0;
    final win = _cleared >= (total * 0.6).ceil();
    final String rank, msg;
    if (_cleared >= total) {
      rank = 'S';
      msg = 'ぜんぶ言えた！かんぺき！🎉';
    } else if (ratio >= .9) {
      rank = 'A';
      msg = 'すごい！よく話せたね！';
    } else if (ratio >= .8) {
      rank = 'B';
      msg = 'いいね！その調子！';
    } else if (ratio >= .6) {
      rank = 'C';
      msg = 'がんばったね！次はもっと！';
    } else if (ratio >= .4) {
      rank = 'D';
      msg = 'おしい！もう一回チャレンジ！';
    } else if (ratio >= .2) {
      rank = 'E';
      msg = 'だいじょうぶ、れんしゅうしよう！';
    } else {
      rank = 'F';
      msg = 'いっしょに 話してみよう！';
    }
    final data = TalkEndData(
      win: win,
      rank: rank,
      msg: msg,
      cleared: _cleared,
      total: total,
      score: _score,
    );
    setState(() {
      _end = data;
      _phase = _Phase.end;
    });
    win
        ? AudioService.instance.playSfx('clear')
        : AudioService.instance.playSfx('gameover');
    final p = ProgressService.instance;
    if (rank == 'S') await p.addSRank('talkmon');
    if (win) await p.befriend('talkmon');
    var cards = const <int>[];
    if (rank == 'S') cards = await p.awardCards('talkmon');
    await p.setBestIfHigher(ProgressKeys.bestTalk, _score);
    if (mounted && identical(_end, data) && cards.isNotEmpty) {
      setState(() => data.newCards = cards);
    }
  }

  void _backToSelect() {
    _gen++;
    unawaited(_rec.cancel());
    AudioService.instance.stopVoice();
    setState(() => _phase = _Phase.start);
    AudioService.instance.setBgmVolume(AudioService.battleBgmVolume);
  }

  Future<void> _confirmQuit() async {
    if (await showArkConfirm(context, 'とちゅうでやめる？　いまのスコアはきえるよ')) {
      if (mounted && _phase == _Phase.play) _backToSelect();
    }
  }

  /// Web `homeMenu()`: asks first while a game is running.
  Future<void> _home() async {
    if (_phase == _Phase.play &&
        !await showArkConfirm(context, 'TOPにもどる？　いまのスコアはきえるよ')) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final Widget body;
    switch (_phase) {
      case _Phase.start:
        body = GameStartLayout(
          key: const ValueKey('start'),
          keyVisual: 'assets/images/hub/talk-top.webp',
          onHome: _home,
          grades: const ['5級', '4級', '3級'],
          selectedGrade: _gradeIdx,
          onGrade: _selectGrade,
          // Web .modecard.m2 / m3 / m1 → tab-talk-1 / 2 / 3.
          modes: [
            ModeCardButton(
              asset: 'assets/images/hub/tab-talk-1.webp',
              onTap: () => _startMode(2),
            ),
            ModeCardButton(
              asset: 'assets/images/hub/tab-talk-2.webp',
              shineDelay: const Duration(milliseconds: 400),
              onTap: () => _startMode(3),
            ),
            ModeCardButton(
              asset: 'assets/images/hub/tab-talk-3.webp',
              shineDelay: const Duration(milliseconds: 800),
              onTap: () => _startMode(1),
            ),
          ],
        );
      case _Phase.play:
        body = _buildPlay(context);
      case _Phase.end:
        body = TalkEndView(
          key: ValueKey(_end),
          data: _end!,
          onHome: _home,
          onRetry: () => _startMode(_mode),
          onReselect: _backToSelect,
        );
    }
    return PopScope(
      canPop: _phase != _Phase.play,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: body,
      ),
    );
  }

  Widget _buildPlay(BuildContext context) {
    final q = _q;
    return Scaffold(
      key: const ValueKey('play'),
      backgroundColor: const Color(0xFF120C33),
      body: PageBackground(
        child: TalkPlayView(
          qi: _qi,
          total: _questions.length,
          score: _score,
          mode: _mode,
          ja: q.ja,
          en: q.en,
          options: _options,
          picked: _picked,
          showSol: _showSol,
          micnote: _micnote,
          showOkBtn: _showOkBtn,
          listening: _listening,
          level: _rec.level,
          hits: _hits,
          react: _react,
          feedback: _feedback,
          onHome: _home,
          onQuit: _confirmQuit,
          onChoice: (w) => _answer(w == q.en, picked: w),
          onListen: _playTalk,
          onSaid: () => _answer(true),
          onMic: _startRecog,
          onNext: _next,
        ),
      ),
    );
  }
}
