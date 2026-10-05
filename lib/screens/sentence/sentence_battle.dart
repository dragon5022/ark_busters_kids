import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/content/game_packs.dart';
import '../../core/theme/app_colors.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/deco_stars.dart';
import '../../widgets/web_sparkle_background.dart';
import 'sentence_records.dart';
import 'sentence_widgets.dart';

enum SenCourse { ten, endless }

const _lvName = {'g5': '英検5級', 'g4': '英検4級', 'g3': '英検3級'};
const _timeByGrade = {'g5': 6, 'g4': 9, 'g3': 12};

/// The web `#game` while playing (`beginCourse` → `loadQuestion` → `shoot`
/// → `questionClear` / `wrongAnswer` → `showExplain` → `endGame`), plus the
/// `#endScreen`. Pops `true` when the player chose 🏠 (go back to the hub).
class SentenceBattleScreen extends StatefulWidget {
  const SentenceBattleScreen({
    super.key,
    required this.pack,
    required this.grade,
    required this.course,
  });

  final SentencePack pack;
  final String grade;
  final SenCourse course;

  @override
  State<SentenceBattleScreen> createState() => _SentenceBattleScreenState();
}

class _EndResult {
  _EndResult({
    required this.win,
    required this.rank,
    required this.msg,
    required this.total,
  });

  final bool win;
  final String rank;
  final String msg;
  final int total;
  List<int> newCards = const [];
}

class _Boom {
  _Boom(this.id, this.center, this.color);

  final int id;
  final Offset center;
  final Color color;
}

class _SentenceBattleScreenState extends State<SentenceBattleScreen> {
  final _rng = math.Random();
  final _react = ReactionController();
  final _feedback = FeedbackController();
  final _stackKey = GlobalKey();

  // ---- web globals
  List<SentenceItem> _questions = [];
  int _qIndex = 0, _score = 0, _step = 0;
  Timer? _timer;
  double _timeLeft = 0;
  bool _locked = false;
  int _lives = 3, _maxLives = 3, _combo = 0, _maxCombo = 0, _cleared = 0;
  int _time = 6;
  String _curSentence = '';

  // ---- per question view state
  int _qSerial = 0;
  String _label = '';

  /// Web `updateLives()` snapshot of `cleared` for the endless HUD.
  int _hudCleared = 0;
  List<int> _order = []; // shuffled answer indices in field order
  List<Color> _colors = [];
  List<(double, double)> _jitter = []; // (dy px, rotate deg)
  final Set<int> _shot = {};
  List<Color?> _slotColors = [];
  List<GlobalKey> _wordKeys = [];
  GramonState _gramon = GramonState.idle;
  int _hitSerial = 0;
  bool _comboVisible = false;
  int _comboSerial = 0;
  final List<_Boom> _booms = [];
  int _boomId = 0;

  bool? _explainTimeup; // non-null while the explain panel is open
  _EndResult? _end;
  bool _started = false;
  bool _dialogOpen = false;

  /// Bumped whenever a run starts or the screen is left, so delayed
  /// callbacks (web setTimeout) from an old run never fire.
  int _gen = 0;

  bool get _endless => widget.course == SenCourse.endless;
  SentenceItem get _q => _questions[_qIndex];
  bool get _playing => _started && _end == null;

  @override
  void initState() {
    super.initState();
    _beginCourse();
  }

  @override
  void dispose() {
    _gen++;
    _timer?.cancel();
    _react.dispose();
    _feedback.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  void _later(int ms, VoidCallback fn) {
    final g = _gen;
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (mounted && g == _gen) fn();
    });
  }

  List<T> _shuffle<T>(List<T> a) => List<T>.of(a)..shuffle(_rng);

  // ------------------------------------------------------------ flow

  void _beginCourse() {
    _gen++;
    AudioService.instance.playSfx('start');
    final all = widget.pack.grades[widget.grade] ?? const <SentenceItem>[];
    if (!_endless) {
      _questions = _shuffle(all).take(widget.pack.qn).toList();
      _maxLives = 3;
    } else {
      _questions = _shuffle(all);
      _maxLives = 1;
    }
    _time =
        widget.pack.timeByGrade[widget.grade] ??
        _timeByGrade[widget.grade] ??
        8;
    _qIndex = 0;
    _score = 0;
    _lives = _maxLives;
    _combo = 0;
    _maxCombo = 0;
    _cleared = 0;
    _hudCleared = 0;
    _comboVisible = false;
    _explainTimeup = null;
    _end = null;
    _started = true;
    _loadQuestion();
  }

  void _loadQuestion() {
    final q = _q;
    final n = q.answer.length;
    setState(() {
      _step = 0;
      _locked = false;
      _gramon = GramonState.idle;
      _qSerial++;
      _order = _shuffle(List<int>.generate(n, (i) => i));
      _colors = _shuffle(SenColors.palette);
      _jitter = List.generate(
        n,
        (_) => (
          (_rng.nextDouble() * 16 - 8).roundToDouble(),
          ((_rng.nextDouble() * 8 - 4) * 10).round() / 10,
        ),
      );
      // Web sets #qlabel only here (HTML collapses the double spaces).
      _label = !_endless
          ? '${_lvName[widget.grade]} 第${_qIndex + 1}問/${_questions.length}'
          : '${_lvName[widget.grade]} エンドレス ${_cleared + 1}問目';
      _shot.clear();
      _slotColors = List<Color?>.filled(n, null);
      _wordKeys = List.generate(n, (_) => GlobalKey());
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = _time.toDouble());
    _runTimer();
  }

  /// setInterval(…, 100) body; also used to resume after a paused dialog.
  void _runTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return t.cancel();
      setState(() => _timeLeft -= 0.1);
      if (_timeLeft <= 0) {
        t.cancel();
        _wrongAnswer(true);
      }
    });
  }

  void _shoot(int ansIdx) {
    if (_locked || _shot.contains(ansIdx) || !_playing) return;
    final q = _q;
    _playPart(q.answer[ansIdx].w);
    if (ansIdx == _step) {
      final k = _order.indexOf(ansIdx);
      final color = _colors[k % _colors.length];
      _boom(ansIdx, color);
      setState(() {
        _shot.add(ansIdx);
        _slotColors[_step] = color;
        _step++;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        _score += 10 + (_combo >= 2 ? (_combo - 1) * 5 : 0);
        _showCombo();
        _gramon = GramonState.hit;
        _hitSerial++;
      });
      // sndCorrect()
      AudioService.instance.playSfx('correct');
      AudioService.instance.playTone('tone_ok');
      HapticFeedback.lightImpact();
      final serial = _hitSerial;
      _later(400, () {
        if (_gramon == GramonState.hit && serial == _hitSerial) {
          setState(() => _gramon = GramonState.idle);
        }
      });
      if (_step == q.answer.length) {
        _timer?.cancel();
        _later(500, _questionClear);
      }
    } else {
      _wrongAnswer(false);
    }
  }

  void _showCombo() {
    if (_combo >= 2) {
      _comboVisible = true;
      _comboSerial++;
    } else {
      _comboVisible = false;
    }
  }

  void _questionClear() {
    setState(() {
      _locked = true;
      _score += 20;
      _cleared++;
      _gramon = GramonState.flee;
    });
    AudioService.instance.playTone('tone_ok_sparkle'); // sndClear()
    _react.show(true);
    _feedback.pop('⭕ 完成！', const Color(0xFFFFD84D));
    _curSentence = _q.answer.map((a) => a.w).join(' ');
    final item = _q;
    _later(600, () => _playGram(item));
    _later(2200, () {
      _qIndex++;
      if (_endless) {
        if (_qIndex >= _questions.length) {
          _questions = _shuffle(widget.pack.grades[widget.grade] ?? const []);
          _qIndex = 0;
        }
        _hudCleared = _cleared; // updateLives()
        _loadQuestion();
      } else {
        if (_qIndex < _questions.length) {
          _loadQuestion();
        } else {
          _endGame(true);
        }
      }
    });
  }

  void _wrongAnswer(bool timeup) {
    if (_locked) return;
    _timer?.cancel();
    setState(() {
      _locked = true;
      _combo = 0;
      _comboVisible = false;
    });
    // sndWrong()
    _react.show(false);
    AudioService.instance.playTone('tone_wrong');
    AnswerFx.wrong(context);
    _showExplain(timeup);
  }

  void _showExplain(bool timeup) {
    _curSentence = _q.answer.map((a) => a.w).join(' ');
    setState(() => _explainTimeup = timeup);
    final item = _q;
    _later(350, () => _playGram(item));
  }

  void _nextAfterExplain() {
    setState(() => _explainTimeup = null);
    if (_endless) {
      _endGame(false);
      return;
    }
    setState(() => _lives--);
    if (_lives <= 0) {
      _endGame(false);
      return;
    }
    _qIndex++;
    if (_qIndex < _questions.length) {
      _loadQuestion();
    } else {
      _endGame(true);
    }
  }

  Future<void> _endGame(bool win) async {
    _timer?.cancel();
    String rank, msg;
    if (!_endless) {
      final total = _questions.length;
      final ratio = total > 0 ? _cleared / total : 0.0;
      if (_cleared >= total) {
        rank = 'S';
        msg = '全問クリア！かんぺき！🎉';
      } else if (ratio >= 0.9) {
        rank = 'A';
        msg = 'すごい！よくできたね！';
      } else if (ratio >= 0.8) {
        rank = 'B';
        msg = 'いいね！その調子！';
      } else if (ratio >= 0.6) {
        rank = 'C';
        msg = 'がんばったね！次はもっといけるよ！';
      } else if (ratio >= 0.4) {
        rank = 'D';
        msg = 'おしい！もう一回チャレンジ！';
      } else if (ratio >= 0.2) {
        rank = 'E';
        msg = 'だいじょうぶ、れんしゅうすればできる！';
      } else {
        rank = 'F';
        msg = 'いっしょにがんばろう！';
      }
    } else {
      final n = _cleared;
      if (n >= 20) {
        rank = 'S';
        msg = 'レジェンド級！止まらない！🎉';
      } else if (n >= 15) {
        rank = 'A';
        msg = 'すごい！集中力ばつぐん！';
      } else if (n >= 10) {
        rank = 'B';
        msg = '二けた達成！お見事！';
      } else if (n >= 6) {
        rank = 'C';
        msg = 'いい調子！次はもっと続くよ！';
      } else if (n >= 3) {
        rank = 'D';
        msg = 'ナイス！コツがつかめてきたね！';
      } else if (n >= 1) {
        rank = 'E';
        msg = 'まずは1問！次はもっといこう！';
      } else {
        rank = 'F';
        msg = 'だいじょうぶ、ゆっくりやってみよう！';
      }
    }
    final result = _EndResult(
      win: win,
      rank: rank,
      msg: msg,
      total: _questions.length,
    );
    setState(() {
      _comboVisible = false;
      _explainTimeup = null;
      _end = result;
    });
    if (win) {
      // sndFanfare()
      AudioService.instance.playSfx('clear');
      AudioService.instance.playTone('tone_fanfare');
    } else {
      AudioService.instance.playSfx('gameover'); // sndGameOver()
    }

    final g = _gen;
    final score = _score;
    if (_endless) {
      final k = '${widget.grade}_endless';
      final prev = await SentenceRecords.getBest(k);
      if (_cleared > prev) await SentenceRecords.setBest(k, _cleared);
    }
    final progress = ProgressService.instance;
    if (rank == 'S') await progress.addSRank('gramon');
    if (win) await progress.befriend('gramon');
    var cards = const <int>[];
    if (rank == 'S') cards = await progress.awardCards('gramon');
    await SentenceRecords.updateBest(score);
    if (mounted && g == _gen && cards.isNotEmpty) {
      setState(() => result.newCards = cards);
    }
  }

  // ------------------------------------------------------------ audio

  /// Web `playGram()`: recorded sentence (voice/gram/N.mp3), else TTS.
  void _playGram(SentenceItem item) {
    final v = item.voice;
    if (v != null && v.isNotEmpty) {
      AudioService.instance.playVoiceAsset(v);
    } else {
      _speak(_curSentence);
    }
  }

  /// Web `playPart(t)`: voice/gramparts/N.mp3 via GRAMPARTS, else TTS.
  void _playPart(String t) {
    final n = widget.pack.gramParts[t];
    if (n != null) {
      AudioService.instance.playVoiceAsset(
        'audio/voice/gramparts/$n.mp3',
        overlap: true,
      );
    } else {
      _speak(t);
    }
  }

  void _speak(String t) =>
      AudioService.instance.speak(t.replaceAll(RegExp(r'\bI\b'), 'i'));

  // --------------------------------------------------------- effects

  void _boom(int ansIdx, Color color) {
    final box =
        _wordKeys[ansIdx].currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.attached) return;
    final c = box.localToGlobal(box.size.center(Offset.zero), ancestor: stack);
    final b = _Boom(_boomId++, c, color);
    setState(() => _booms.add(b));
    _later(560, () => setState(() => _booms.remove(b)));
  }

  // ------------------------------------------------------ navigation

  /// Web `confirmQuit()`: stop the timer, ask; 「いいえ」 restarts it.
  Future<void> _confirmQuit() async {
    if (_dialogOpen) return;
    _timer?.cancel();
    _dialogOpen = true;
    final yes = await showArkConfirm(context, 'とちゅうでやめる？　いまのスコアはきえるよ');
    _dialogOpen = false;
    if (!mounted) return;
    if (yes) {
      _backToSelect();
    } else if (!_locked && _end == null) {
      _startTimer();
    }
  }

  /// Web `homeMenu()`: confirm while playing, then back to the hub.
  /// (The blocking web confirm() freezes the timer; we pause and resume.)
  Future<void> _homeMenu() async {
    if (_dialogOpen) return;
    if (_playing) {
      final running = _timer?.isActive ?? false;
      _timer?.cancel();
      _dialogOpen = true;
      final yes = await showArkConfirm(context, 'TOPにもどる？　いまのスコアはきえるよ');
      _dialogOpen = false;
      if (!mounted) return;
      if (!yes) {
        if (running && !_locked && _end == null) _runTimer();
        return;
      }
    }
    _gen++;
    _timer?.cancel();
    Navigator.of(context).pop(true);
  }

  void _backToSelect() {
    _gen++;
    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  bool _retrying = false;

  /// Web `retrySame()` → wrapped `beginCourse` (encounter pop-up first).
  Future<void> _retrySame() async {
    if (_retrying) return;
    _retrying = true;
    setState(() {
      _end = null;
      _started = false;
    });
    await AnswerFx.battleFlash(context);
    if (!mounted) return;
    await showGramEncounter(context);
    _retrying = false;
    if (!mounted) return;
    _beginCourse();
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_playing) {
          _confirmQuit();
        } else if (_end != null) {
          _backToSelect();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg4,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.background),
              ),
            ),
            const Positioned.fill(child: DecoStars()),
            Positioned.fill(
              top: pad.top,
              bottom: pad.bottom,
              child: LayoutBuilder(
                builder: (context, c) => _battle(c.maxWidth, c.maxHeight),
              ),
            ),
            if (_explainTimeup != null) Positioned.fill(child: _explain()),
            if (_end != null) Positioned.fill(child: _endScreen(_end!)),
            Positioned.fill(
              child: ReactionLayer(
                controller: _react,
                happyAsset: SenAssets.happy,
                sadAsset: SenAssets.sad,
              ),
            ),
            // #arkHomeBtn (8,8) and #bgmBtn (118,8), fixed on top.
            Positioned(
              top: pad.top + 8,
              left: 8,
              child: ArkHomeButton(onTap: _homeMenu),
            ),
            Positioned(
              top: pad.top + 8,
              left: 118,
              child: const BgmButton(size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _battle(double w, double h) {
    final small = h <= 740; // @media (max-height:740px)
    final showPlay = _started && _end == null;
    final monSize = small ? 120.0 : 175.0;
    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        if (showPlay) ...[
          // .gramon
          Positioned(
            top: small ? 185 : 225,
            left: 0,
            right: 0,
            child: Center(
              child: GramonCoin(
                key: ValueKey('mon$_qSerial'),
                state: _gramon,
                size: monSize,
                hitSerial: _hitSerial,
              ),
            ),
          ),
          // .prompt
          Positioned(top: 106, left: 16, right: 16, child: _prompt()),
          // .combo
          if (_comboVisible)
            Positioned(
              top: 190,
              left: 0,
              right: 0,
              child: Center(
                child: ComboBadge(combo: _combo, serial: _comboSerial),
              ),
            ),
          // .field
          Positioned(
            top: h * (small ? 0.38 : 0.45),
            bottom: small ? 185 : 205,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Center(child: _field(small)),
            ),
          ),
          // .slots
          Positioned(
            bottom: 70,
            left: 12,
            right: 12,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 14,
              children: [
                for (var i = 0; i < _slotColors.length; i++)
                  AnswerSlot(
                    number: i + 1,
                    text: _slotColors[i] == null ? null : _q.answer[i].w,
                    color: _slotColors[i],
                    small: small,
                  ),
              ],
            ),
          ),
          for (final b in _booms)
            Positioned(
              key: ValueKey('boom${b.id}'),
              left: b.center.dx - 60,
              top: b.center.dy - 60,
              child: BoomBurst(color: b.color),
            ),
        ],
        // .feedback (top:240px) — kit FeedbackPop centres at 46% of its box.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 563,
          child: FeedbackPop(controller: _feedback, fontSize: 32),
        ),
        // .brand
        const Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Text(
            'ARK総合学院 ／ English Busters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0x73FFFFFF),
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _hud()),
        if (showPlay) ...[
          // .timer-wrap / .timer-bar
          Positioned(top: 0, left: 0, right: 0, child: _timerBar()),
          // .countdown
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(child: _countdown()),
          ),
        ],
      ],
    );
  }

  Widget _prompt() {
    final q = _q;
    final label = _label;
    const shadow = [
      Shadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x80000000)),
    ];
    final spans = <InlineSpan>[];
    for (var i = 0; i < q.ja.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: ' '));
      final p = q.ja[i];
      spans.add(
        TextSpan(
          text: p.t,
          style: p.pick ? const TextStyle(color: SenColors.gold) : null,
        ),
      );
    }
    return Reveal(
      key: ValueKey('prompt$_qSerial'),
      dy: -8,
      duration: const Duration(milliseconds: 360),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: SenColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Zen Maru Gothic',
                fontWeight: FontWeight.w900,
                fontSize: 13,
                height: 1.45,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w900,
              fontSize: 19,
              height: 1.3,
              color: Colors.white,
              shadows: shadow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(bool small) {
    final q = _q;
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 12,
      children: [
        for (var k = 0; k < _order.length; k++)
          _wordAt(k, q.answer[_order[k]].w, small),
      ],
    );
  }

  Widget _wordAt(int k, String text, bool small) {
    final ansIdx = _order[k];
    final shot = _shot.contains(ansIdx);
    final (dy, rot) = _jitter[k];
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: rot * math.pi / 180,
        child: Reveal(
          key: ValueKey('w$_qSerial-$k'),
          delay: Duration(milliseconds: 40 + 60 * k),
          duration: const Duration(milliseconds: 380),
          dy: 14,
          fromScale: 0.7,
          child: AnimatedOpacity(
            // @keyframes shot{to{opacity:0}} .45s
            opacity: shot ? 0 : 1,
            duration: const Duration(milliseconds: 450),
            child: AnimatedScale(
              scale: shot ? 1.15 : 1,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: shot,
                child: WordChip(
                  key: _wordKeys[ansIdx],
                  text: text,
                  color: _colors[k % _colors.length],
                  fontSize: small ? 18 : 21,
                  onTap: () => _shoot(ansIdx),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF20D1A33), Color(0x000D1A33)],
        ),
      ),
      child: Row(
        children: [
          // Web .hud .logo sits under the 🏠 / BGM buttons (only a clipped
          // '…sters' shows); hidden here but kept for the row layout.
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: const Text.rich(
              TextSpan(
                text: 'English',
                children: [
                  TextSpan(
                    text: 'Busters',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: SenColors.gold,
              ),
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: 18, child: _livesView()),
              const SizedBox(height: 2),
              _scoreView(),
            ],
          ),
          const SizedBox(width: 10),
          QuitButton(
            onTap: () {
              if (_playing) {
                _confirmQuit();
              } else {
                _backToSelect();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _livesView() {
    if (_endless) {
      return Text(
        '$_hudCleared問クリア',
        style: const TextStyle(
          fontFamily: 'Zen Maru Gothic',
          fontWeight: FontWeight.w900,
          fontSize: 14,
          height: 1.25,
          color: SenColors.gold,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _maxLives; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: AnimatedScale(
              scale: i < _lives ? 1 : 0.82,
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  end: i < _lives
                      ? const Color(0xFFFF4D6D)
                      : const Color(0x47FFFFFF),
                ),
                duration: const Duration(milliseconds: 300),
                builder: (context, c, _) => Icon(
                  Icons.favorite,
                  size: 19,
                  color: c,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Color(0x4D000000),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _scoreView() {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _score.toDouble()),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      builder: (context, v, _) => Text.rich(
        TextSpan(
          text: 'SCORE ',
          children: [
            TextSpan(
              text: '${v.round()}',
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SenColors.gold,
              ),
            ),
          ],
        ),
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _timerBar() {
    final f = (_timeLeft / _time).clamp(0.0, 1.0);
    return Container(
      height: 8,
      color: Colors.white.withValues(alpha: 0.15),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 100),
        widthFactor: f,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF6A), SenColors.gold, SenColors.c1],
            ),
            boxShadow: f < 0.3
                ? const [BoxShadow(color: Color(0x99FF5E8A), blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _countdown() {
    final n = math.max(0, _timeLeft.ceil());
    final hurry = n <= 2 && !_locked;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, a) => ScaleTransition(
        scale: Tween(
          begin: 1.5,
          end: 1.0,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Text(
        '$n',
        key: ValueKey(n),
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          height: 1.2,
          color: hurry ? const Color(0xFFFFD0DC) : Colors.white,
          shadows: [
            const Shadow(
              offset: Offset(0, 2),
              blurRadius: 6,
              color: Color(0x80000000),
            ),
            if (hurry) const Shadow(blurRadius: 12, color: Color(0xCCFF5E8A)),
          ],
        ),
      ),
    );
  }

  Widget _explain() {
    final q = _q;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: DimBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Reveal(
                fromScale: 0.9,
                dy: 20,
                duration: const Duration(milliseconds: 380),
                child: ExplainCard(
                  timeup: _explainTimeup!,
                  english: _curSentence,
                  japanese: q.ja.map((p) => p.t).join(),
                  parts: [for (final a in q.answer) (a.label, a.w)],
                  tip: q.tip,
                  onListen: () => _playGram(q),
                  onNext: _nextAfterExplain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _endScreen(_EndResult r) {
    final pad = MediaQuery.paddingOf(context);
    const white = Colors.white;
    const bigStyle = TextStyle(
      fontFamily: 'Zen Maru Gothic',
      fontWeight: FontWeight.w900,
      fontSize: 26,
      color: white,
    );
    const gold = TextStyle(color: SenColors.gold);
    final big = _endless
        ? TextSpan(
            children: [
              const TextSpan(text: 'れんぞく '),
              TextSpan(text: '$_cleared', style: gold),
              const TextSpan(text: ' 問クリア！　SCORE '),
              TextSpan(text: '$_score', style: gold),
            ],
          )
        : TextSpan(
            children: [
              TextSpan(text: 'クリア $_cleared / ${r.total}　SCORE '),
              TextSpan(text: '$_score', style: gold),
            ],
          );
    var i = 0;
    Duration next() => Duration(milliseconds: 250 + 90 * i++);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.background),
        child: WebSparkleBackground(
          child: Stack(
            children: [
              if (r.win)
                const Positioned.fill(
                  child: IgnorePointer(child: ConfettiBurst(count: 44)),
                ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      pad.top + 56,
                      22,
                      ArkBottomNav.heightFor(compact: true) + pad.bottom + 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            c.maxHeight -
                            pad.top -
                            56 -
                            ArkBottomNav.heightFor(compact: true) -
                            pad.bottom -
                            20,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RankLetter(rank: r.rank, fontSize: 84),
                              Reveal(
                                delay: next(),
                                child: Column(
                                  children: [
                                    Text(
                                      r.win ? 'クリア！' : 'おつかれさま！',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontFamilyFallback: [
                                          'M PLUS Rounded 1c',
                                        ],
                                        fontWeight: FontWeight.w700,
                                        fontSize: 34,
                                        height: 1.1,
                                        color: white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.win ? 'よくできました🌸' : '記録はのこったよ',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Fredoka',
                                        fontFamilyFallback: [
                                          'M PLUS Rounded 1c',
                                        ],
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        height: 1.1,
                                        color: SenColors.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              ResultImage(
                                asset: r.win ? SenAssets.win : SenAssets.lose,
                              ),
                              const SizedBox(height: 10),
                              Reveal(
                                delay: next(),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text.rich(big, style: bigStyle),
                                ),
                              ),
                              if (r.win) ...[
                                const SizedBox(height: 12),
                                const BefriendBanner(
                                  image: SenAssets.friend,
                                  name: 'グラモン',
                                ),
                              ],
                              NewCardsReveal(
                                poseBase: SenAssets.poseBase,
                                cards: r.newCards,
                              ),
                              if (_maxCombo >= 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Reveal(
                                    delay: next(),
                                    child: Text(
                                      '🔥 最大 $_maxCombo れんぞく！',
                                      style: const TextStyle(
                                        fontFamily: 'Zen Maru Gothic',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: SenColors.gold,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Reveal(
                                delay: next(),
                                child: Text(
                                  r.msg,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Zen Maru Gothic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    height: 1.6,
                                    color: white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Reveal(
                                delay: next(),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    GameButton(
                                      label: 'もう一回 ↻',
                                      onTap: _retrySame,
                                      fontSize: 16,
                                      shine: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                        vertical: 12,
                                      ),
                                    ),
                                    GameButton(
                                      label: 'えらびなおす',
                                      white: true,
                                      onTap: _backToSelect,
                                      fontSize: 16,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 26,
                                        vertical: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ArkBottomNav(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
