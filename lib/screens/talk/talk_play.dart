import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../widgets/page_background.dart';
import 'talk_widgets.dart';

/// The play area (`#hud`, `.gameup-strip`, `#playArea`, `.brand`) and the
/// end screen (`#endScreen`) of Talk Buster.

const _asset = 'assets/images/monsters/talkmon';

class TalkPlayView extends StatelessWidget {
  const TalkPlayView({
    super.key,
    required this.qi,
    required this.total,
    required this.score,
    required this.mode,
    required this.ja,
    required this.en,
    required this.options,
    required this.picked,
    required this.showSol,
    required this.micnote,
    required this.showOkBtn,
    required this.listening,
    required this.level,
    required this.hits,
    required this.react,
    required this.feedback,
    required this.onHome,
    required this.onQuit,
    required this.onChoice,
    required this.onListen,
    required this.onSaid,
    required this.onMic,
    required this.onNext,
  });

  final int qi;
  final int total;
  final int score;
  final int mode;
  final String ja;
  final String en;
  final List<String> options;
  final String? picked;
  final bool showSol;
  final String micnote;
  final bool showOkBtn;
  final bool listening;
  final ValueNotifier<double> level;
  final int hits;
  final ReactionController react;
  final FeedbackController feedback;
  final VoidCallback onHome;
  final VoidCallback onQuit;
  final ValueChanged<String> onChoice;
  final VoidCallback onListen;
  final VoidCallback onSaid;
  final VoidCallback onMic;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    // Short phones (< 760pt of usable height): shrink the game-up strip and
    // the bottom gap so the question and all its buttons still fit.
    final usable = size.height - pad.top - pad.bottom;
    final k = ((usable - 560) / 200).clamp(0.55, 1.0);
    final stripH = 104 * k;
    final bottomGap = 64 + 26 * k;
    return Stack(
      children: [
        const Positioned.fill(child: TalkStarfront()),
        // .gameup-strip: top 42, 96% (max 480) × max 104, contain.
        Positioned(
          top: pad.top + 42,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: SizedBox(
                width: math.min(size.width * 0.96, 480),
                height: stripH,
                child: const Center(
                  child: ArtShadow(
                    color: Color(0x73000000),
                    offset: Offset(0, 4),
                    blur: 10,
                    child: AspectRatio(
                      aspectRatio: 800 / 280,
                      child: Image(
                        image: AssetImage('$_asset/talk-gameup.webp'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // .brand
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomGap - 26 + pad.bottom,
          child: const IgnorePointer(
            child: Text(
              'ARK総合学院 ／ Talk Busters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Color(0x80FFFFFF),
              ),
            ),
          ),
        ),
        // .play
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              pad.top + 42 + stripH + 12,
              18,
              bottomGap + pad.bottom,
            ),
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: Center(child: _content(context, c)),
                ),
              ),
            ),
          ),
        ),
        // .hud
        Positioned(
          top: pad.top,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      text: 'Talk',
                      style: TextStyle(
                        fontFamily: 'Mochiy Pop One',
                        fontSize: 16,
                        color: talkGold,
                        shadows: [
                          Shadow(offset: Offset(0, 2), color: talkPurple),
                        ],
                      ),
                      children: [
                        TextSpan(
                          text: ' Busters',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x4D000000),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '第${qi + 1}/$total　⭐$score',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                TalkQuitButton(onTap: onQuit),
              ],
            ),
          ),
        ),
        // .homebtn + #bgmBtn
        Positioned(
          top: pad.top + 8,
          left: 8,
          child: ArkHomeButton(onTap: onHome),
        ),
        Positioned(top: pad.top + 8, left: 118, child: const TalkBgmButton()),
        Positioned.fill(child: TalkFeedback(controller: feedback)),
        Positioned.fill(
          child: ReactionLayer(
            controller: react,
            happyAsset: '$_asset/talk-happy.webp',
            sadAsset: '$_asset/talk-sad.webp',
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, BoxConstraints c) {
    final screenW = MediaQuery.sizeOf(context).width;
    // .qmon: 300px, max 78vw; shrinks on short screens so the question
    // and its buttons stay visible without scrolling.
    final fullW = math.min(300.0, screenW * 0.78);
    final fullH = fullW * 1066 / 1600;
    final rest = showSol
        ? (mode == 1 ? 380.0 : 460.0)
        : mode == 1
        ? 360.0
        : (showOkBtn ? 330.0 : 260.0);
    final qH = (c.maxHeight - rest - 10).clamp(70.0, fullH);
    final maxW = c.maxWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QMon(width: fullW * qH / fullH, height: qH, hits: hits),
        const SizedBox(height: 10),
        Reveal(
          key: ValueKey('q$qi'),
          dy: 12,
          fromScale: 0.96,
          duration: const Duration(milliseconds: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _situation(),
              const SizedBox(height: 10),
              if (mode != 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: StrokeText(
                    en,
                    style: const TextStyle(
                      fontFamily: 'M PLUS Rounded 1c',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.52,
                      height: 1.35,
                      color: Color(0xFFFFF7B0),
                    ),
                    strokeColor: const Color(0xFFB06A00),
                    strokeWidth: 1,
                  ),
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(showSol),
                  child: showSol ? _solbox(maxW) : _modeArea(maxW),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (listening) ...[
                        _LevelBars(level: level),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          micnote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: Color(0xFFFFD1F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _situation() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: talkGold, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 5)),
        ],
      ),
      child: Text.rich(
        TextSpan(
          text: '「$ja」\n',
          children: const [
            TextSpan(
              text: 'って、えいごで なんて言う？',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8A5A00),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Mochiy Pop One',
          fontSize: 19,
          height: 1.5,
          color: talkNavy,
        ),
      ),
    );
  }

  Widget _modeArea(double maxW) {
    if (mode == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: math.min(420, maxW)),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  // live #mobileFit: .choices{gap:9px}
                  if (i > 0) const SizedBox(height: 9),
                  _Choice(
                    text: options[i],
                    correct: picked == options[i],
                    onTap: () => onChoice(options[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final buttons = <Widget>[
      TalkBigButton(
        kind: TalkBtnKind.listen,
        label: mode == 2 ? '🔊 もういちど' : '🔊 おてほん',
        onTap: onListen,
      ),
      if (mode == 2)
        TalkBigButton(kind: TalkBtnKind.ok, label: '言えた！😊', onTap: onSaid)
      else ...[
        _MicPulse(
          listening: listening,
          level: level,
          child: TalkBigButton(
            kind: TalkBtnKind.mic,
            label: '🎤 はなす',
            onTap: onMic,
          ),
        ),
        if (showOkBtn)
          TalkBigButton(kind: TalkBtnKind.ok, label: '言えた！😊', onTap: onSaid),
      ],
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }

  /// Web `.solbox` shown after a miss: 「せいかいは…」 + the answer.
  Widget _solbox(double maxW) {
    return Container(
      width: math.min(440, maxW),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: talkGold, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'せいかいは…',
            style: TextStyle(
              color: Color(0xFFE0641A),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              en,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Mochiy Pop One',
                fontSize: 24,
                height: 1.3,
                color: talkNavy,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '「$ja」',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TalkBigButton(
                kind: TalkBtnKind.listen,
                label: '🔊 もういちど 聞く',
                onTap: onListen,
              ),
              TalkBigButton(
                kind: TalkBtnKind.ok,
                label: 'つぎへ ▶',
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Web `.choice` (turns green `.correct` when picked right).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.text,
    required this.correct,
    required this.onTap,
  });

  final String text;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        // live #mobileFit: .choice{padding:11px 16px}
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: correct ? const Color(0xFFD6FFD6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: correct ? const Color(0xFF3CC77A) : const Color(0xFFC9B8FF),
            width: 3,
          ),
          boxShadow: [
            const BoxShadow(color: Color(0x33000000), offset: Offset(0, 4)),
            if (correct)
              const BoxShadow(color: Color(0x803CC77A), blurRadius: 16),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: talkNavy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

/// `.qmon` (e-talk.png): bobs with `@keyframes qbob` (2.4s alternate,
/// −10px, −2°→2°) under a purple drop shadow. Extra: flinches with a white
/// flash each time the player gets one right.
class _QMon extends StatefulWidget {
  const _QMon({required this.width, required this.height, required this.hits});

  final double width;
  final double height;
  final int hits;

  @override
  State<_QMon> createState() => _QMonState();
}

class _QMonState extends State<_QMon> with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _QMon old) {
    super.didUpdateWidget(old);
    if (widget.hits != old.hits) _hit.forward(from: 0);
  }

  @override
  void dispose() {
    _bob.dispose();
    _hit.dispose();
    super.dispose();
  }

  static const _img = AssetImage('assets/images/hub/e-talk.webp');

  @override
  Widget build(BuildContext context) {
    final art = RepaintBoundary(
      child: ArtShadow(
        color: const Color(0x997828C8),
        offset: const Offset(0, 8),
        blur: 20,
        child: Image(image: _img, fit: BoxFit.contain),
      ),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bob, _hit]),
        builder: (context, _) {
          final b = Curves.easeInOut.transform(_bob.value);
          final h = _hit.value;
          final hitOn = _hit.isAnimating;
          final shake = hitOn ? math.sin(h * math.pi * 7) * 9 * (1 - h) : 0.0;
          final flash = hitOn ? (1 - h) * 0.75 : 0.0;
          return Transform.translate(
            offset: Offset(shake, -10 * b),
            child: Transform.rotate(
              angle: (-2 + 4 * b) * math.pi / 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  art,
                  if (flash > 0)
                    Opacity(
                      opacity: flash,
                      child: const Image(
                        image: _img,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Extra: while the mic listens, rings ripple out of 「はなす」 and its glow
/// follows the live input level.
class _MicPulse extends StatefulWidget {
  const _MicPulse({
    required this.listening,
    required this.level,
    required this.child,
  });

  final bool listening;
  final ValueNotifier<double> level;
  final Widget child;

  @override
  State<_MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<_MicPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _MicPulse old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.listening && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.listening) return widget.child;
    return AnimatedBuilder(
      animation: Listenable.merge([_c, widget.level]),
      child: widget.child,
      builder: (context, child) {
        final lv = widget.level.value;
        return CustomPaint(
          painter: _RingPainter(_c.value, lv),
          child: Transform.scale(scale: 1 + 0.05 * lv, child: child),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t, this.level);

  final double t;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    // The button sits inside 6px of .bigbtn margin.
    final base = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(6),
      const Radius.circular(18),
    );
    final glow = Paint()
      ..color = const Color(0xFFFF9F5A).withValues(alpha: 0.35 + 0.45 * level)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 14 * level);
    canvas.drawRRect(base.inflate(2 + 6 * level), glow);
    for (var i = 0; i < 2; i++) {
      final k = (t + i * 0.5) % 1.0;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - k) + 0.5
        ..color = const Color(0xFFFFD1A8).withValues(alpha: (1 - k) * 0.8);
      canvas.drawRRect(
        base.inflate(4 + 18 * Curves.easeOut.transform(k)),
        ring,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.t != t || old.level != level;
}

/// Extra: tiny equaliser in front of 「きいてるよ…」 driven by the mic level.
class _LevelBars extends StatefulWidget {
  const _LevelBars({required this.level});

  final ValueNotifier<double> level;

  @override
  State<_LevelBars> createState() => _LevelBarsState();
}

class _LevelBarsState extends State<_LevelBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, widget.level]),
      builder: (context, _) {
        final lv = widget.level.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                width: 3,
                height:
                    4 +
                    10 *
                        (0.35 + 0.65 * lv) *
                        (0.5 +
                                0.5 *
                                    math.sin(
                                      (_c.value + i * 0.23) * 2 * math.pi,
                                    ))
                            .abs(),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD1F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------ end screen

class TalkEndData {
  TalkEndData({
    required this.win,
    required this.rank,
    required this.msg,
    required this.cleared,
    required this.total,
    required this.score,
  });

  final bool win;
  final String rank;
  final String msg;
  final int cleared;
  final int total;
  final int score;
  List<int> newCards = const [];
}

/// Web `#endScreen`.
class TalkEndView extends StatelessWidget {
  const TalkEndView({
    super.key,
    required this.data,
    required this.onHome,
    required this.onRetry,
    required this.onReselect,
  });

  final TalkEndData data;
  final VoidCallback onHome;
  final VoidCallback onRetry;
  final VoidCallback onReselect;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final d = data;
    return Scaffold(
      backgroundColor: const Color(0xFF120C33),
      body: PageBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  pad.top + 12,
                  16,
                  ArkBottomNav.heightFor(compact: true) + pad.bottom + 16,
                ),
                children: [
                  // #endImg: 92% (max 360), radius 12, drop shadow.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Reveal(
                      fromScale: 0.9,
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.92,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: ArtShadow(
                              color: const Color(0x66000000),
                              offset: const Offset(0, 6),
                              blur: 14,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  d.win
                                      ? '$_asset/talk-win.webp'
                                      : '$_asset/talk-lose.webp',
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: RankLetter(rank: d.rank, fontSize: 80)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Reveal(
                      delay: const Duration(milliseconds: 250),
                      child: Text(
                        '言えた ${d.cleared} / ${d.total}　SCORE ${d.score}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (d.win)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Column(
                        children: [
                          const BefriendBanner(
                            image: 'assets/images/misc/f-talk.webp',
                            name: 'トークモン',
                          ),
                          NewCardsReveal(
                            poseBase: '$_asset/talkmon-pose',
                            cards: d.newCards,
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Reveal(
                      delay: const Duration(milliseconds: 380),
                      child: Text(
                        d.msg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFE9B0),
                        ),
                      ),
                    ),
                  ),
                  Reveal(
                    delay: const Duration(milliseconds: 480),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        TalkBtn(label: 'もう一回 ↻', onTap: onRetry),
                        TalkBtn(
                          label: 'えらびなおす',
                          white: true,
                          onTap: onReselect,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 8,
              child: ArkHomeButton(onTap: onHome),
            ),
            Positioned(
              top: pad.top + 8,
              left: 118,
              child: const TalkBgmButton(),
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
    );
  }
}
