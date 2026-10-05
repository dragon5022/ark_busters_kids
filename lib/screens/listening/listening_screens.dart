import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/content/game_packs.dart';
import '../../core/progress/progress_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/content_repository.dart';
import '../../services/progress_service.dart';
import '../../widgets/page_background.dart';
import 'listening_widgets.dart';

/// Listening Buster (リスニングバスター) — port of the live web page
/// `リスニングアプリ_無料版200問/listening-buster_無料版.html`.
///
/// One screen with the web's three layers: `#startScreen` (grade + level),
/// `#game` (battle + `#review`) and `#endScreen`.
class ListeningHomeScreen extends StatefulWidget {
  const ListeningHomeScreen({super.key});

  @override
  State<ListeningHomeScreen> createState() => _ListeningHomeScreenState();
}

enum _Phase { start, play, end }

/// Web `LV_META`.
class _LvMeta {
  const _LvMeta(this.short, this.instruct, this.time);

  final String short;
  final String instruct;
  final int time;
}

const _lvMeta = {
  0: _LvMeta('Lv0', 'ゆっくりきいて、絵をえらぼう', 0),
  1: _LvMeta('Lv1', 'きいて、絵をえらぼう', 8),
  2: _LvMeta('Lv2', 'あう返事をえらぼう', 12),
  3: _LvMeta('Lv3', '会話をきいて、答えよう', 14),
};
const _lvName = {'g5': '英検5級', 'g4': '英検4級', 'g3': '英検3級'};
const _grades = ['g5', 'g4', 'g3'];
const _pickCount = 10; // PICK_COUNT

class _ListeningHomeScreenState extends State<ListeningHomeScreen> {
  final _rng = math.Random();
  final _react = ReactionController();
  final _feedback = FeedbackController();

  ListeningPack? _pack;
  _Phase _phase = _Phase.start;
  String _grade = 'g5';
  int _level = 1;
  bool _starting = false; // window.__rgLock

  // ---- game state (web globals)
  List<ListeningItem> _questions = [];
  int _qIndex = 0;
  int _score = 0;
  int _lives = 3;
  int _maxLives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _correct = 0;
  int _time = 8;
  double _timeLeft = 0;
  bool _locked = false;
  Timer? _timer;
  final List<Timer> _pending = [];

  // ---- per-question view state
  List<String> _items = [];
  List<Color> _colors = [];
  int _qSerial = 0;
  int _picked = -1;
  bool _pickedOk = false;
  int _pulse = 0;
  bool _flee = false;
  bool _showCombo = false;
  bool _timerOn = false;
  String? _reviewHead;

  // ---- end screen
  _EndData? _end;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBattleBgm();
    _load();
  }

  Future<void> _load() async {
    final pack = ContentRepository.instance.listening ??
        await ContentRepository.instance.loadListening();
    if (mounted) setState(() => _pack = pack);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final t in _pending) {
      t.cancel();
    }
    _react.dispose();
    _feedback.dispose();
    AudioService.instance.stopVoice();
    super.dispose();
  }

  /// setTimeout that dies with the screen / the next game.
  void _later(int ms, VoidCallback fn) {
    late final Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _pending.remove(t);
      if (mounted) fn();
    });
    _pending.add(t);
  }

  void _clearPending() {
    for (final t in _pending) {
      t.cancel();
    }
    _pending.clear();
  }

  ListeningItem get _q => _questions[_qIndex];

  // ------------------------------------------------------------ start

  void _selectGrade(int i) {
    AudioService.instance.playSfx('start');
    setState(() => _grade = _grades[i]);
  }

  /// Wrapped web `startGame(level)`: encounter pop → real startGame.
  Future<void> _startGame(int level) async {
    if (_starting) return;
    final set = _pack?.grades[_grade]?[level];
    if (set == null || set.isEmpty) {
      await showArkNotice(context, 'このレベルはまだじゅんび中です');
      return;
    }
    _starting = true;
    await AnswerFx.battleFlash(context);
    if (!mounted) return;
    await showLisEncounter(context);
    _starting = false;
    if (!mounted) return;
    AudioService.instance.playSfx('start');
    // Live MutationObserver: BGM .17 while #startScreen is hidden.
    AudioService.instance.setBgmVolume(0.17);
    _clearPending();
    _timer?.cancel();
    final pool = List<ListeningItem>.of(set)..shuffle(_rng);
    setState(() {
      _level = level;
      _questions = pool.take(_pickCount).toList();
      _time = _lvMeta[level]!.time;
      _maxLives = level == 0 ? 5 : 3;
      _phase = _Phase.play;
      _reviewHead = null;
      _end = null;
      _qIndex = 0;
      _score = 0;
      _lives = _maxLives;
      _combo = 0;
      _maxCombo = 0;
      _correct = 0;
      _showCombo = false;
    });
    _loadQuestion();
  }

  void _loadQuestion() {
    final q = _q;
    final items = [q.ans, ...q.opts]..shuffle(_rng);
    final colors = List<Color>.of(LisColors.palette)..shuffle(_rng);
    setState(() {
      _locked = false;
      _items = items;
      _colors = colors;
      _qSerial++;
      _picked = -1;
      _flee = false;
    });
    _later(450, () {
      setState(() => _pulse++);
      _playLis(_level == 0);
    });
    _startTimer();
  }

  /// Web `playLis(slow)`: recorded clip (lisOK), else TTS.
  void _playLis(bool slow) {
    if (_questions.isEmpty) return;
    final q = _q;
    if (q.voice != null) {
      AudioService.instance.playVoiceAsset(q.voice);
    } else {
      AudioService.instance.speak(q.en, rate: slow ? 0.7 : 0.82);
    }
  }

  void _replay() {
    if (_locked) return;
    setState(() => _pulse++);
    _playLis(_level == 0);
  }

  void _startTimer() {
    _timer?.cancel();
    if (_time <= 0) {
      setState(() => _timerOn = false);
      return;
    }
    setState(() {
      _timerOn = true;
      _timeLeft = _time.toDouble();
    });
    _resumeTimer();
  }

  void _resumeTimer() {
    _timer?.cancel();
    // Web ticks -0.1 every 100ms; measure real time so a busy frame
    // never stretches the limit.
    final base = _timeLeft;
    final sw = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return t.cancel();
      setState(() => _timeLeft = base - sw.elapsedMilliseconds / 1000);
      if (_timeLeft <= 0) {
        t.cancel();
        _timeUp();
      }
    });
  }

  void _choose(int index) {
    if (_locked) return;
    final ok = _items[index] == _q.ans;
    _locked = true;
    _timer?.cancel();
    if (ok) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      _correct++;
      final bonus = _combo >= 2 ? (_combo - 1) * 5 : 0;
      setState(() {
        _picked = index;
        _pickedOk = true;
        _flee = true;
        _score += 10 + bonus;
        _showCombo = _combo >= 2;
      });
      // sndCorrect()
      AudioService.instance.playSfx('correct');
      AudioService.instance.playTone('tone_ok_sparkle');
      _react.show(true);
      HapticFeedback.lightImpact();
      _feedback.pop('⭕ せいかい！', const Color(0xFFFFD84D));
      _later(1100, _advance);
    } else {
      // sndWrong()
      _react.show(false);
      AudioService.instance.playTone('tone_wrong');
      AnswerFx.wrong(context, shaker: _shakeKey.currentState);
      setState(() {
        _picked = index;
        _pickedOk = false;
        _combo = 0;
        _showCombo = false;
        _lives--;
      });
      _later(500, () => _showReview('❌ おしい！'));
    }
  }

  void _timeUp() {
    if (_locked) return;
    _locked = true;
    setState(() {
      _combo = 0;
      _showCombo = false;
      _lives--;
    });
    AudioService.instance.playTone('tone_timeup');
    AnswerFx.wrong(context, shaker: _shakeKey.currentState);
    _later(300, () => _showReview('⏰ 時間切れ！'));
  }

  void _showReview(String head) {
    setState(() => _reviewHead = head + (_lives > 0 ? '　のこり♥$_lives' : ''));
    _later(350, () => _playLis(false));
  }

  void _nextAfterReview() {
    setState(() => _reviewHead = null);
    if (_lives <= 0) {
      _endGame();
      return;
    }
    _advance();
  }

  void _advance() {
    _qIndex++;
    if (_qIndex < _questions.length) {
      _loadQuestion();
    } else {
      _endGame();
    }
  }

  // ------------------------------------------------------------ end

  Future<void> _endGame() async {
    _timer?.cancel();
    final total = _questions.length;
    final ratio = total > 0 ? _correct / total : 0.0;
    final win = _correct >= (total * 0.6).ceil();
    String rank, msg;
    if (_correct >= total) {
      rank = 'S';
      msg = 'かんぺき！すごい！🎉';
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
    final progress = ProgressService.instance;
    if (rank == 'S') await progress.addSRank('lismon');
    if (win) await progress.befriend('lismon');
    var cards = <int>[];
    if (rank == 'S') cards = await progress.awardCards('lismon');
    await progress.setBestIfHigher(ProgressKeys.bestListening, _score);
    // Per grade/level best: localStorage 'lb2_<g>_<lv>'.
    final prefs = await SharedPreferences.getInstance();
    final key = 'lb2_${_grade}_$_level';
    final prev = int.tryParse(prefs.getString(key) ?? '0') ?? 0;
    var record = false;
    if (_score > prev && _score > 0) {
      await prefs.setString(key, '$_score');
      record = true;
    }
    if (!mounted) return;
    if (win) {
      AudioService.instance.playSfx('clear');
      AudioService.instance.playTone('tone_fanfare');
    } else {
      AudioService.instance.playSfx('gameover');
    }
    setState(() {
      _end = _EndData(
        win: win,
        rank: rank,
        score: _score,
        msg: '正解 $_correct / $total　$msg',
        maxCombo: _maxCombo,
        record: record,
        cards: cards,
      );
      _phase = _Phase.end;
      _reviewHead = null;
    });
  }

  void _retrySame() {
    // Web hides #endScreen, then the wrapped startGame shows the encounter
    // over the (empty) battle field.
    setState(() {
      _phase = _Phase.play;
      _questions = [];
    });
    _startGame(_level);
  }

  void _backToSelect() {
    _timer?.cancel();
    _clearPending();
    AudioService.instance.stopVoice();
    AudioService.instance.setBgmVolume(AudioService.battleBgmVolume);
    setState(() {
      _phase = _Phase.start;
      _reviewHead = null;
      _questions = [];
    });
  }

  Future<void> _confirmQuit() async {
    _timer?.cancel();
    final yes = await showArkConfirm(context, 'とちゅうでやめる？　いまのスコアはきえるよ');
    if (!mounted) return;
    if (yes) {
      _backToSelect();
    } else if (!_locked && _time > 0 && _phase == _Phase.play) {
      _startTimer(); // web restarts the full time
    }
  }

  final _shakeKey = GlobalKey<ShakeScopeState>();

  bool get _playing => _phase == _Phase.play;

  /// Web `homeMenu()`: confirm only while playing (confirm() also freezes
  /// the timer, so it resumes where it was).
  Future<void> _home() async {
    if (_playing && _questions.isNotEmpty) {
      final wasRunning = _timer?.isActive ?? false;
      _timer?.cancel();
      final yes = await showArkConfirm(context, 'TOPにもどる？　いまのスコアはきえるよ');
      if (!mounted) return;
      if (!yes) {
        if (wasRunning && !_locked) _resumeTimer();
        return;
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_phase) {
      _Phase.start => _buildStart(),
      _Phase.play => ShakeScope(key: _shakeKey, child: _buildGame(context)),
      _Phase.end => _buildEnd(context),
    };
    return PopScope(
      canPop: !_playing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(key: ValueKey(_phase), child: body),
      ),
    );
  }

  Widget _buildStart() {
    return GameStartLayout(
      keyVisual: 'assets/images/hub/lis-top.webp',
      onHome: _home,
      selectedGrade: _grades.indexOf(_grade),
      onGrade: _selectGrade,
      modes: [
        for (var lv = 0; lv <= 3; lv++)
          ModeCardButton(
            asset: 'assets/images/hub/tab-lis-$lv.webp',
            shineDelay: Duration(milliseconds: 220 * lv),
            onTap: _pack == null ? null : () => _startGame(lv),
            lockPack: 'listening',
            lockIndex: lv,
            lockGroup: _grade,
          ),
      ],
    );
  }

  Widget _topButtons(EdgeInsets pad) {
    return Positioned(
      top: pad.top + 8,
      left: 8,
      child: SizedBox(
        width: 160,
        height: 40,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, child: ArkHomeButton(onTap: _home)),
            // web #bgmBtn: fixed at left 118
            const Positioned(left: 110, top: 0, child: BgmButton(size: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    final size = mq.size;
    final compact = size.height < 780; // @media (max-height:780px)
    final hasQ = _questions.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg4,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.background),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    const Positioned.fill(child: LisStarField()),
                    // .brand
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: pad.bottom + 10,
                      child: const Text(
                        'ARK総合学院 ／ Listening Busters',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Zen Maru Gothic',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0x73FFFFFF),
                        ),
                      ),
                    ),
                    // .stage
                    Positioned(
                      top: pad.top + 52,
                      bottom: pad.bottom + 16,
                      left: 0,
                      right: 0,
                      child: hasQ ? _stage(w, compact) : const SizedBox.shrink(),
                    ),
                    // .feedback (top 250px inside the stage)
                    Positioned(
                      top: pad.top,
                      left: 0,
                      right: 0,
                      height: (52 + 250 + 21) / 0.46,
                      child: FeedbackPop(controller: _feedback, fontSize: 34),
                    ),
                    _hud(pad),
                    if (_reviewHead != null && hasQ)
                      Positioned.fill(child: _review()),
                    ReactionLayer(
                      controller: _react,
                      happyAsset: '$kLisDir/lismon-happy.webp',
                      sadAsset: '$kLisDir/lismon-sad.webp',
                      bottom: 84 + pad.bottom,
                    ),
                    _topButtons(pad),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _hud(EdgeInsets pad) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, pad.top + 12, 14, 12),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                LisHearts(lives: _lives, max: _maxLives),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'SCORE ',
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _ScoreText(score: _score),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontFamily: 'Zen Maru Gothic',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            QuitButton(onTap: _confirmQuit),
          ],
        ),
      ),
    );
  }

  Widget _stage(double w, bool compact) {
    final q = _q;
    final meta = _lvMeta[_level]!;
    final isPic = q.t == 'pic';
    final instruct = (_level == 3 && q.q != null) ? 'しつもん: ${q.q}' : meta.instruct;
    final gap = compact ? 8.0 : 12.0;
    // mobileFit: .lismon img{width:min(46vw,180px)}
    final imgW = math.min(w * 0.46, 180.0);
    final choiceW = math.min(360.0, w - 32 - 28);

    final choices = <Widget>[
      for (var i = 0; i < _items.length; i++)
        LisChoice(
          key: ValueKey('$_qSerial-$i'),
          label: _items[i],
          color: _colors[i % _colors.length],
          emoji: isPic,
          compact: compact,
          width: choiceW,
          fx: _picked != i
              ? ChoiceFx.idle
              : (_pickedOk ? ChoiceFx.shot : ChoiceFx.wrong),
          onTap: () => _choose(i),
        ),
    ];

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // .qlabel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: LisColors.gold,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_lvName[_grade]}  ${meta.short}  第${_qIndex + 1}問/${_questions.length}',
            style: const TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: gap),
        LisMonster(
          imageWidth: imgW,
          instruct: instruct,
          instructSize: compact ? 13 : 15,
          pulse: _pulse,
          flee: _flee,
          onTap: _replay,
        ),
        if (_showCombo) ...[
          SizedBox(height: gap),
          LisCombo(combo: _combo),
        ],
        if (_timerOn) ...[
          SizedBox(height: gap),
          TimerBar(fraction: _timeLeft / _time, width: 200),
        ],
        SizedBox(height: gap),
        // .choices (gap 9 / padding 0 14 from mobileFit)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: isPic
              ? Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 9,
                  runSpacing: 9,
                  children: choices,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < choices.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      choices[i],
                    ],
                  ],
                ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(width: w - 32, child: column),
        ),
      ),
    );
  }

  Widget _review() {
    final q = _q;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: child,
      ),
      child: ColoredBox(
        color: const Color(0xB8081028), // rgba(8,16,40,.72)
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (context, s, child) => Transform.scale(scale: s, child: child),
                child: LisReviewCard(
                  head: _reviewHead!,
                  answer: q.ans,
                  en: q.en,
                  ja: q.ja,
                  tip: q.tip,
                  onListen: () => _playLis(false),
                  onNext: _nextAfterReview,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnd(BuildContext context) {
    final e = _end!;
    final pad = MediaQuery.paddingOf(context);
    var i = 0;
    Duration next() => Duration(milliseconds: 120 + 90 * i++);
    const white = TextStyle(
      fontFamily: 'Zen Maru Gothic',
      color: Colors.white,
      fontWeight: FontWeight.w900,
    );
    return Scaffold(
      backgroundColor: AppColors.bg4,
      body: PageBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  pad.top + 30,
                  22,
                  ArkBottomNav.heightFor(compact: true) + pad.bottom + 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 436),
                    child: Column(
                      children: [
                        // .resultimg: 80% (max 330) of the 346px column
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 4),
                          child: FractionallySizedBox(
                            widthFactor: 0.8 / 0.88,
                            child: ResultImage(
                              asset: e.win ? '$kLisDir/lis-win.webp' : '$kLisDir/lis-lose.webp',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        RankLetter(rank: e.rank, fontSize: 84),
                        const SizedBox(height: 4),
                        Reveal(
                          delay: next(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text.rich(
                              TextSpan(
                                text: 'SCORE ',
                                children: [
                                  TextSpan(
                                    text: '${e.score}',
                                    style: const TextStyle(color: LisColors.gold),
                                  ),
                                ],
                              ),
                              style: white.copyWith(fontSize: 26),
                            ),
                          ),
                        ),
                        if (e.win)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Column(
                              children: [
                                const BefriendBanner(
                                  image: '$kLisDir/リス友.webp',
                                  name: 'リスモン',
                                ),
                                NewCardsReveal(
                                  poseBase: '$kLisDir/lismon-pose',
                                  cards: e.cards,
                                ),
                              ],
                            ),
                          ),
                        Reveal(
                          delay: next(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 14),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                e.msg,
                                textAlign: TextAlign.center,
                                style: white.copyWith(
                                  fontSize: 16,
                                  height: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (e.maxCombo >= 2)
                          Reveal(
                            delay: next(),
                            child: Text(
                              '🔥 最大 ${e.maxCombo} れんぞく正解！',
                              style: white.copyWith(fontSize: 15, color: LisColors.gold),
                            ),
                          ),
                        if (e.record)
                          Reveal(
                            delay: next(),
                            fromScale: 0.6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ShineSweep(
                                opacity: 0.6,
                                period: const Duration(milliseconds: 2400),
                                child: Text(
                                  '🏆 最高記録こうしん！',
                                  style: white.copyWith(fontSize: 18, color: LisColors.gold),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Reveal(
                          delay: next(),
                          dy: 16,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: GameButton(
                                  label: 'もう一回 ↻',
                                  textColor: Colors.white,
                                  fontSize: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                  shine: true,
                                  onTap: _retrySame,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: GameButton(
                                  label: 'えらびなおす',
                                  white: true,
                                  fontSize: 16,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                  onTap: _backToSelect,
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
            _topButtons(pad),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ArkBottomNav(compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.score b`: gold number that bumps when it grows (extra polish).
class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(score),
      tween: Tween(begin: score == 0 ? 1 : 1.35, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Text(
        '$score',
        style: const TextStyle(
          fontFamily: 'Zen Maru Gothic',
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: LisColors.gold,
        ),
      ),
    );
  }
}

class _EndData {
  const _EndData({
    required this.win,
    required this.rank,
    required this.score,
    required this.msg,
    required this.maxCombo,
    required this.record,
    required this.cards,
  });

  final bool win;
  final String rank;
  final int score;
  final String msg;
  final int maxCombo;
  final bool record;
  final List<int> cards;
}
