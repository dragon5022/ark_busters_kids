import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/content/vocab_pack.dart';
import '../../core/progress/progress_keys.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/content_repository.dart';
import '../../services/progress_service.dart';
import 'vocab_widgets.dart';

/// Vocabulary Busters (ボキャブラリーバスター) — port of
/// `ボキャブラリー_無料版/vocabulary-busters_無料版.html` (live version).
///
/// Start screen (grade 5/4/3 + 3 modes) → encounter pop → 10 questions
/// (lv1 picture 4-choice 5s, lv2 spelling 3-choice 7s, lv3 letter order 10s)
/// → end screen (rank S–F, befriend, S-rank cards, best score).

const _qn = 10; // web QN
const _timeByLevel = {1: 5, 2: 7, 3: 10}; // web TIME_BY_LEVEL
const _monKey = 'vocamon';

/// Where a battle route asks the start screen to go when it closes.
enum _Exit { start, hub }

class VocabHomeScreen extends StatefulWidget {
  const VocabHomeScreen({super.key});

  @override
  State<VocabHomeScreen> createState() => _VocabHomeScreenState();
}

class _VocabHomeScreenState extends State<VocabHomeScreen> {
  int _kyu = 5; // web curKyu
  bool _lock = false; // web __rgLock

  static const _grades = [5, 4, 3];

  @override
  void initState() {
    super.initState();
    // The web page plays the battle BGM from page load (start screen too).
    AudioService.instance.playBattleBgm();
  }

  Future<VocabPack> _pack() async {
    final repo = ContentRepository.instance;
    return repo.vocab ?? await repo.loadVocab();
  }

  void _selectKyu(int i) {
    AudioService.instance.playSfx('start');
    setState(() => _kyu = _grades[i]);
  }

  Future<void> _startGame(int level) async {
    if (_lock) return;
    _lock = true;
    try {
      final pack = await _pack();
      if (!mounted) return;
      // web: startGame() guard (never hit with the bundled data).
      if (vocaPool(pack, _kyu, level).length < 4) {
        await showArkNotice(context, 'この級はまだ単語が少ないよ（ほかの級でためしてね）');
        return;
      }
      // web: BGM ducks to .17 while the start screen is hidden.
      AudioService.instance.setBgmVolume(0.17);
      await showVocaEncounter(context);
      if (!mounted) return;
      final exit = await Navigator.of(context).push<_Exit>(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => _VocabBattleScreen(pack: pack, kyu: _kyu, level: level),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));
      AudioService.instance.setBgmVolume(AudioService.battleBgmVolume);
      if (exit == _Exit.hub && mounted) Navigator.of(context).pop();
    } finally {
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameStartLayout(
      keyVisual: 'assets/images/hub/voca-top.webp',
      onHome: () => Navigator.of(context).pop(),
      grades: const ['5級', '4級', '3級'],
      selectedGrade: _grades.indexOf(_kyu),
      onGrade: _selectKyu,
      modes: [
        for (var l = 1; l <= 3; l++)
          ModeCardButton(
            asset: 'assets/images/hub/tab-voca-$l.webp',
            shineDelay: Duration(milliseconds: 300 * l),
            onTap: () => _startGame(l),
          ),
      ],
    );
  }
}

/// web `poolFor(kyu, level)`.
List<VocabItem> vocaPool(VocabPack pack, int kyu, int level) {
  var p = pack.items.where((v) => v.lv == kyu);
  if (level == 3) {
    final re = RegExp(r'^[a-zA-Z]+$');
    p = p.where((v) => re.hasMatch(v.w) && v.w.length <= 8);
  }
  return p.toList();
}

// =================================================================== game

class _VocabBattleScreen extends StatefulWidget {
  const _VocabBattleScreen({required this.pack, required this.kyu, required this.level});

  final VocabPack pack;
  final int kyu;
  final int level;

  @override
  State<_VocabBattleScreen> createState() => _VocabBattleScreenState();
}

class _EndData {
  _EndData({
    required this.score,
    required this.correct,
    required this.win,
    required this.rank,
    required this.msg,
    required this.cards,
  });

  final int score;
  final int correct;
  final bool win;
  final String rank;
  final String msg;
  final List<int> cards;
}

class _VocabBattleScreenState extends State<_VocabBattleScreen>
    with TickerProviderStateMixin {
  final _rng = math.Random();
  final _reaction = ReactionController();
  final _feedback = FeedbackController();

  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late int _time = _timeByLevel[widget.level] ?? 5;
  List<VocabItem> _questions = [];
  int _qi = 0, _score = 0, _correct = 0;
  bool _locked = false;
  bool _playing = false; // HUD/stage visible
  final _frac = ValueNotifier<double>(1);
  double _tleftAtStart = 0; // remaining when the ticker (re)started
  double _tleft = 0;

  // lv1/lv2
  List<String> _choices = [];
  final Map<int, ChoiceState> _choiceState = {};
  // lv3
  String _spellTarget = '', _spellGot = '';
  List<String> _tiles = [];
  final List<bool> _tileUsed = [];

  // explain panel
  bool _explain = false, _explainTimeup = false;

  _EndData? _end;

  VocabItem get _q => _questions[_qi];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hit.dispose();
    _frac.dispose();
    _reaction.dispose();
    _feedback.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  // ------------------------------------------------------------- flow

  /// web `startGame(level)` (after the encounter pop).
  void _startGame() {
    AudioService.instance.playSfx('start');
    _time = _timeByLevel[widget.level] ?? 5;
    final pool = vocaPool(widget.pack, widget.kyu, widget.level)..shuffle(_rng);
    _questions = pool.take(math.min(_qn, pool.length)).toList();
    _qi = 0;
    _score = 0;
    _correct = 0;
    _end = null;
    _explain = false;
    _playing = true;
    _showQuestion();
  }

  void _showQuestion() {
    _locked = false;
    final q = _q;
    _choiceState.clear();
    if (widget.level == 1) {
      // renderChoices: 3 other words of the same grade.
      final others = (vocaPool(widget.pack, widget.kyu, 1).where((v) => v.w != q.w).toList()
            ..shuffle(_rng))
          .take(3)
          .map((v) => v.w);
      _choices = [q.w, ...others]..shuffle(_rng);
    } else if (widget.level == 2) {
      _choices = [q.w, ..._misspell(q.w, 2)]..shuffle(_rng);
    } else {
      _spellTarget = q.w;
      _spellGot = '';
      _tiles = q.w.split('')..shuffle(_rng);
      _tileUsed
        ..clear()
        ..addAll(List.filled(_tiles.length, false));
    }
    // Pre-decode the next picture so it appears without a flash.
    if (_qi + 1 < _questions.length && _questions[_qi + 1].img != null) {
      precacheImage(AssetImage('assets/${_questions[_qi + 1].img}'), context);
    }
    setState(() {});
    _startTimer();
  }

  /// web `misspell(w, n)`.
  List<String> _misspell(String w, int n) {
    const vowels = 'aeiou';
    final res = <String>{};
    var guard = 0;
    while (res.length < n && guard++ < 60) {
      final a = w.split('');
      final i = _rng.nextInt(a.length);
      final mode = _rng.nextInt(3);
      if (mode == 0 && i < a.length - 1) {
        final t = a[i];
        a[i] = a[i + 1];
        a[i + 1] = t;
      } else if (mode == 1 && vowels.contains(a[i])) {
        a[i] = vowels[(vowels.indexOf(a[i]) + 1 + _rng.nextInt(4)) % 5];
      } else {
        a[i] = a[i] + a[i];
      }
      final cand = a.join();
      if (cand != w) res.add(cand);
    }
    return res.take(n).toList();
  }

  // ------------------------------------------------------------ timer

  void _startTimer() {
    _ticker.stop();
    _tleftAtStart = _time.toDouble();
    _tleft = _tleftAtStart;
    _frac.value = 1;
    _ticker.start();
  }

  void _pauseTimer() {
    if (!_ticker.isActive) return;
    _ticker.stop();
    _tleftAtStart = _tleft;
  }

  void _resumeTimer() {
    if (_locked || _ticker.isActive || !_playing) return;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _tleft = _tleftAtStart - elapsed.inMicroseconds / 1e6;
    _frac.value = math.max(0, _tleft / _time);
    if (_tleft <= 0) {
      _ticker.stop();
      _answer(false, timeup: true);
    }
  }

  // ----------------------------------------------------------- answer

  void _playVoca() {
    final q = _q;
    if (q.voice != null) {
      AudioService.instance.playVoiceAsset(q.voice);
    } else {
      AudioService.instance.speak(q.w);
    }
  }

  void _answer(bool ok, {int? choice, bool timeup = false}) {
    if (_locked) return;
    _locked = true;
    _ticker.stop();
    _playVoca();
    final q = _q;
    final qi = _qi;
    if (ok) {
      _score += 100;
      _correct++;
      AudioService.instance.playSfx('correct'); // sndOK
      AudioService.instance.playTone('tone_ok');
      _reaction.show(true);
      if (choice != null) _choiceState[choice] = ChoiceState.correct;
      _feedback.pop('⭕ せいかい！', const Color(0xFFFFE45E));
      _hit.forward(from: 0); // extra: the enemy flinches
      setState(() {});
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted || _qi != qi || !_playing) return;
        _next();
      });
    } else {
      AudioService.instance.playTone('tone_ng'); // sndNG
      _reaction.show(false);
      if (choice != null) _choiceState[choice] = ChoiceState.wrong;
      for (var i = 0; i < _choices.length && widget.level != 3; i++) {
        if (_choices[i] == q.w) _choiceState[i] = ChoiceState.correct;
      }
      setState(() {});
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _qi != qi || !_playing) return;
        setState(() {
          _explain = true;
          _explainTimeup = timeup;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _explain && _qi == qi) _playVoca();
        });
      });
    }
  }

  void _nextAfterExplain() {
    if (!mounted || !_explain) return;
    setState(() => _explain = false);
    _next();
  }

  void _next() {
    _qi++;
    if (_qi < _questions.length) {
      _showQuestion();
    } else {
      _qi = _questions.length - 1;
      _endGame();
    }
  }

  // ---------------------------------------------------------- spelling

  void _spellTap(int i) {
    if (_locked || _tileUsed[i]) return;
    setState(() {
      _spellGot += _tiles[i];
      _tileUsed[i] = true;
    });
    if (_spellGot.length == _spellTarget.length) {
      _answer(_spellGot == _spellTarget);
    }
  }

  void _spellDel() {
    if (_locked || _spellGot.isEmpty) return;
    final ch = _spellGot[_spellGot.length - 1];
    setState(() {
      _spellGot = _spellGot.substring(0, _spellGot.length - 1);
      for (var i = _tiles.length - 1; i >= 0; i--) {
        if (_tileUsed[i] && _tiles[i] == ch) {
          _tileUsed[i] = false;
          break;
        }
      }
    });
  }

  // --------------------------------------------------------------- end

  Future<void> _endGame() async {
    _ticker.stop();
    final score = _score, correct = _correct;
    final win = correct >= (_qn * 0.6).ceil();
    AudioService.instance.playSfx(win ? 'clear' : 'gameover');
    final String rank, msg;
    if (correct >= 10) {
      rank = 'S';
      msg = 'すごい！かんぺき！この調子でがんばって🎉';
    } else if (correct >= 9) {
      rank = 'A';
      msg = 'すごい！よくできたね！この調子でがんばろう！';
    } else if (correct >= 8) {
      rank = 'B';
      msg = 'いいね！その調子でがんばろう！';
    } else if (correct >= 6) {
      rank = 'C';
      msg = 'がんばったね！次はもっといけるよ！';
    } else if (correct >= 4) {
      rank = 'D';
      msg = 'おしい！もう一回チャレンジしよう！';
    } else if (correct >= 2) {
      rank = 'E';
      msg = 'だいじょうぶ、れんしゅうすればできるよ！';
    } else {
      rank = 'F';
      msg = 'いっしょにがんばろう！もう一回チャレンジ！';
    }
    final ps = ProgressService.instance;
    if (rank == 'S') await ps.addSRank(_monKey);
    if (win) await ps.befriend(_monKey);
    var cards = <int>[];
    if (rank == 'S') cards = await ps.awardCards(_monKey);
    await ps.setBestIfHigher(ProgressKeys.bestVocabulary, score);
    AudioService.instance.playTone(win ? 'tone_fanfare' : 'tone_ng');
    if (!mounted) return;
    setState(() {
      _playing = false;
      _explain = false;
      _end = _EndData(
        score: score,
        correct: correct,
        win: win,
        rank: rank,
        msg: msg,
        cards: cards,
      );
    });
  }

  Future<void> _retry() async {
    setState(() => _end = null);
    await showVocaEncounter(context);
    if (mounted) setState(_startGame);
  }

  // ------------------------------------------------------------ quit

  /// web `confirmQuit()`: stops the timer; "no" restarts it from full.
  Future<void> _confirmQuit() async {
    if (!_playing) return;
    _ticker.stop();
    final yes = await showArkConfirm(context, 'とちゅうでやめる？　いまのスコアはきえるよ');
    if (!mounted) return;
    if (yes) {
      _playing = false;
      Navigator.of(context).pop(_Exit.start);
    } else if (!_locked) {
      _startTimer();
    }
  }

  /// web `homeMenu()`: asks only while playing.
  Future<void> _homeMenu() async {
    if (_playing) {
      _pauseTimer();
      final yes = await showArkConfirm(context, 'TOPにもどる？　いまのスコアはきえるよ');
      if (!mounted) return;
      if (!yes) {
        _resumeTimer();
        return;
      }
      _playing = false;
    }
    if (mounted) Navigator.of(context).pop(_Exit.hub);
  }

  // ============================================================= build

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: _end != null && !_playing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1340),
        body: VocaGameBackground(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            final gameupH = w * 267 / 800;
            final stageTop = pad.top + math.max(210.0, 44 + gameupH + 30);
            return Stack(
              children: [
                if (_playing) ...[
                  // .gameup banner (enemy) under the HUD
                  Positioned(
                    top: pad.top + 44,
                    left: 0,
                    right: 0,
                    child: _GameUp(hit: _hit),
                  ),
                  Positioned(
                    top: stageTop,
                    left: 22,
                    right: 22,
                    bottom: 30 + pad.bottom,
                    child: _stage(w - 44),
                  ),
                  _hud(pad),
                ],
                // .brand
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8 + pad.bottom,
                  child: IgnorePointer(
                    child: Text(
                      'ARK総合学院 ／ Vocabulary Busters',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Zen Maru Gothic',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(child: FeedbackPop(controller: _feedback)),
                Positioned.fill(child: _explainLayer()),
                if (_end != null) Positioned.fill(child: _endScreen(_end!, pad)),
                // Fixed #arkHomeBtn / #bgmBtn (top-left, above everything).
                Positioned(
                  top: pad.top + 8,
                  left: 8,
                  child: Row(
                    children: [
                      ArkHomeButton(onTap: _homeMenu),
                      const SizedBox(width: 10),
                      const BgmButton(size: 38),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: ReactionLayer(
                    controller: _reaction,
                    happyAsset: '$kVocaDir/vocamon-happy.webp',
                    sadAsset: '$kVocaDir/vocamon-sad.webp',
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// `.hud`: dark gradient bar with 第n/10 ⭐score and やめる.
  Widget _hud(EdgeInsets pad) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(150, pad.top + 12, 18, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF20D1A33), Color(0x000D1A33)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: HudInfo(qnum: _qi + 1, total: _qn, score: _score),
              ),
            ),
            const SizedBox(width: 10),
            QuitButton(onTap: _confirmQuit),
          ],
        ),
      ),
    );
  }

  /// `.stage`: question card, timer, answer area — centered, gap 26.
  Widget _stage(double width) {
    final q = _q;
    final vw = MediaQuery.sizeOf(context).width;
    Widget card;
    if (q.img != null) {
      final iw = math.min(vw * 0.42, 170.0); // mobileFit: min(42vw,170px)
      card = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          'assets/${q.img}',
          width: iw,
          fit: BoxFit.fitWidth,
          gaplessPlayback: true,
        ),
      );
    } else {
      card = SizedBox(
        width: math.min(vw * 0.7, 300.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            q.ja,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w900,
              fontSize: 21,
              height: 1.4,
              color: kNavy,
            ),
          ),
        ),
      );
    }
    final qcard = Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kGold, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 10), blurRadius: 26),
        ],
      ),
      child: card,
    );

    Widget answers;
    if (widget.level == 1) {
      final cw = width * 0.46;
      answers = Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _choices.length; i++)
            _stagger(i, ChoiceButton(
              width: cw,
              label: _choices[i],
              state: _choiceState[i] ?? ChoiceState.idle,
              onTap: () => _answer(_choices[i] == q.w, choice: i),
            )),
        ],
      );
    } else if (widget.level == 2) {
      answers = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _choices.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _stagger(i, ChoiceButton(
              label: _choices[i],
              state: _choiceState[i] ?? ChoiceState.idle,
              onTap: () => _answer(_choices[i] == q.w, choice: i),
            )),
          ],
        ],
      );
    } else {
      answers = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _spellTarget.length; i++)
                SpellSlot(ch: i < _spellGot.length ? _spellGot[i] : null),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _tiles.length; i++)
                _stagger(i, SpellTile(
                  ch: _tiles[i],
                  used: _tileUsed[i],
                  onTap: () => _spellTap(i),
                )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiniButton(label: '← けす', onTap: _spellDel),
              const SizedBox(width: 12),
              MiniButton(
                label: '🔊 きく',
                onTap: () => AudioService.instance.speak(_spellTarget),
              ),
            ],
          ),
        ],
      );
    }

    final column = SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Reveal(
            key: ValueKey('card$_qi'),
            fromScale: 0.9,
            dy: 0,
            duration: const Duration(milliseconds: 320),
            child: qcard,
          ),
          const SizedBox(height: 26),
          ValueListenableBuilder<double>(
            valueListenable: _frac,
            builder: (_, f, _) => TimerBar(fraction: f),
          ),
          const SizedBox(height: 26),
          KeyedSubtree(key: ValueKey('ans$_qi'), child: answers),
        ],
      ),
    );
    // Never overflow on short screens: shrink the whole stage instead.
    return Center(
      child: FittedBox(fit: BoxFit.scaleDown, child: column),
    );
  }

  /// Extra polish: answers slide in one after another for each question.
  Widget _stagger(int i, Widget child) => Reveal(
        delay: Duration(milliseconds: 40 * i),
        duration: const Duration(milliseconds: 280),
        dy: 12,
        child: child,
      );

  Widget _explainLayer() {
    final show = _explain && _playing;
    return IgnorePointer(
      ignoring: !show,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: show ? 1 : 0,
        child: ColoredBox(
          color: const Color(0xB80A081E), // rgba(10,8,30,.72)
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                scale: show ? 1 : 0.86,
                child: _questions.isEmpty
                    ? const SizedBox.shrink()
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: math.min(380, MediaQuery.sizeOf(context).width - 52),
                          child: ExplainCard(
                            timeup: _explainTimeup,
                            word: _q.w,
                            ja: _q.ja,
                            image: _q.img == null ? null : 'assets/${_q.img}',
                            onListen: _playVoca,
                            onNext: _nextAfterExplain,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `#endScreen` overlay.
  Widget _endScreen(_EndData d, EdgeInsets pad) {
    var i = 0;
    Duration next() => Duration(milliseconds: 250 + 110 * i++);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFA3A1F8A), Color(0xFA1A1340)],
        ),
      ),
      child: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              0,
              pad.top + 48,
              0,
              ArkBottomNav.heightFor(compact: true) + pad.bottom + 16,
            ),
            children: [
              const SizedBox(height: 16),
              Center(
                child: ResultImage(
                  asset: '$kVocaDir/${d.win ? 'voca-win' : 'voca-lose'}.webp',
                ),
              ),
              const SizedBox(height: 6),
              Center(child: RankLetter(rank: d.rank)),
              Reveal(
                delay: next(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _BigScore(score: d.score, correct: d.correct),
                ),
              ),
              Reveal(
                delay: next(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
                  child: Text(
                    d.msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Zen Maru Gothic',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x66000000)),
                      ],
                    ),
                  ),
                ),
              ),
              if (d.win || d.cards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Column(
                    children: [
                      if (d.win)
                        const Center(
                          child: BefriendBanner(
                            image: '$kVocaDir/vocamon-friend.webp',
                            name: 'ボキャモン',
                          ),
                        ),
                      NewCardsReveal(poseBase: '$kVocaDir/vocamon-pose', cards: d.cards),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              Reveal(
                delay: next(),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    GameButton(label: 'もう一回 ↻', onTap: _retry, shine: true),
                    GameButton(
                      label: 'えらびなおす',
                      white: true,
                      onTap: () => Navigator.of(context).pop(_Exit.start),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: ArkBottomNav(compact: true)),
        ],
      ),
    );
  }
}

/// `.gameup`: the enemy banner; flinches when hit (extra polish).
class _GameUp extends StatelessWidget {
  const _GameUp({required this.hit});

  final Animation<double> hit;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: hit,
      builder: (context, child) {
        final t = hit.value;
        if (t == 0 || t == 1) return child!;
        final dx = math.sin(t * math.pi * 7) * 7 * (1 - t);
        final flash = (1 - t) * 0.55;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              1, 0, 0, 0, 255 * flash, //
              0, 1, 0, 0, 255 * flash * 0.9,
              0, 0, 1, 0, 255 * flash * 0.6,
              0, 0, 0, 1, 0,
            ]),
            child: child,
          ),
        );
      },
      child: Image.asset(
        '$kVocaDir/voca-gameup.webp',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

/// `.bigscore`: SCORE <b>1000</b>　（10/10） — the score counts up.
class _BigScore extends StatelessWidget {
  const _BigScore({required this.score, required this.correct});

  final int score;
  final int correct;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: 'Zen Maru Gothic',
            fontWeight: FontWeight.w900,
            fontSize: 27,
            color: Colors.white,
          ),
          children: [
            const TextSpan(text: 'SCORE '),
            TextSpan(text: '${v.round()}', style: const TextStyle(color: kGold)),
            TextSpan(text: '　（$correct/$_qn）'),
          ],
        ),
      ),
    );
  }
}
