import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';

/// Pieces of the Listening Buster battle (web `listening-buster_無料版.html`).

const kLisDir = 'assets/images/monsters/lismon';

/// Web CSS variables.
class LisColors {
  static const navy = Color(0xFF1F3864);
  static const gold = Color(0xFFFFC93C);
  static const goldShadow = Color(0xFF8A6800);
  static const c1 = Color(0xFFFF5E8A);
  static const c2 = Color(0xFF3F9BFF);
  static const c3 = Color(0xFF3FCF7A);

  /// `loadQuestion()` palette, shuffled per question.
  static const palette = [
    Color(0xFFFF5E8A),
    Color(0xFF3F9BFF),
    Color(0xFF3FCF7A),
    Color(0xFFFF9F43),
    Color(0xFFB06BFF),
    Color(0xFF22B8C4),
  ];
}

const _zen = 'Zen Maru Gothic';

/// Browsers fall back to a Japanese font for kana inside Fredoka text.
const _jpFallback = ['Zen Maru Gothic', 'M PLUS Rounded 1c'];

// ------------------------------------------------------------ star field

class _Star {
  const _Star(this.left, this.top, this.color, this.size, this.char);

  final double left;
  final double top;
  final int color;
  final double size;
  final String char;
}

/// Web `#starfront` (moved inside `#game`): 63 coloured ★ ✦ ✧ that bob
/// up 7px (4s, odd children 5.2s, alternate).
const _stars = [
  _Star(2.2, 3.9, 0xFFFFFFFF, 16, '★'),
  _Star(19.2, 6.1, 0xFFFFFFFF, 12, '✦'),
  _Star(30.5, 3.7, 0xFFFFF7B0, 14, '✦'),
  _Star(48.6, 4.0, 0xFFC9A3FF, 11, '★'),
  _Star(60.2, 6.0, 0xFF9BE06A, 18, '★'),
  _Star(76.9, 9.2, 0xFFFF7EB6, 14, '✧'),
  _Star(98.7, 9.8, 0xFFFFFFFF, 12, '✧'),
  _Star(9.6, 19.1, 0xFFFFD54A, 18, '★'),
  _Star(22.1, 16.4, 0xFFC9A3FF, 20, '✧'),
  _Star(39.8, 16.8, 0xFFFFF7B0, 18, '★'),
  _Star(43.9, 20.5, 0xFFFF7EB6, 12, '★'),
  _Star(58.3, 20.5, 0xFFFF7EB6, 12, '★'),
  _Star(76.5, 18.4, 0xFFFFFFFF, 18, '✧'),
  _Star(97.0, 15.7, 0xFF5CD0F7, 16, '✧'),
  _Star(9.5, 26.5, 0xFF9BE06A, 14, '✦'),
  _Star(26.5, 28.4, 0xFF5CD0F7, 16, '✧'),
  _Star(31.7, 26.0, 0xFFFFB066, 14, '★'),
  _Star(50.3, 30.1, 0xFFFF7EB6, 14, '✦'),
  _Star(61.6, 27.9, 0xFF9BE06A, 12, '✦'),
  _Star(76.5, 30.0, 0xFFFFD54A, 16, '✦'),
  _Star(90.1, 26.4, 0xFF5CD0F7, 16, '✧'),
  _Star(10.6, 40.4, 0xFFFFF7B0, 12, '★'),
  _Star(19.5, 41.1, 0xFFFFFFFF, 12, '★'),
  _Star(35.9, 42.0, 0xFFFFFFFF, 11, '✧'),
  _Star(54.3, 43.4, 0xFFC9A3FF, 14, '✧'),
  _Star(62.7, 37.7, 0xFFFFF7B0, 14, '✦'),
  _Star(80.2, 43.1, 0xFFFF7EB6, 12, '✧'),
  _Star(98.6, 35.1, 0xFFFFB066, 12, '✦'),
  _Star(10.4, 54.3, 0xFFFFD54A, 18, '★'),
  _Star(21.9, 51.6, 0xFFFFD54A, 11, '★'),
  _Star(38.4, 50.8, 0xFFC9A3FF, 14, '★'),
  _Star(52.5, 48.5, 0xFFFFD54A, 11, '✦'),
  _Star(63.1, 52.5, 0xFFFFF7B0, 18, '✦'),
  _Star(72.9, 47.0, 0xFF9BE06A, 18, '★'),
  _Star(94.9, 50.2, 0xFFFFFFFF, 20, '✧'),
  _Star(10.3, 64.6, 0xFF5CD0F7, 20, '✧'),
  _Star(19.9, 65.3, 0xFF5CD0F7, 14, '✦'),
  _Star(34.7, 63.4, 0xFFFF7EB6, 16, '✧'),
  _Star(55.7, 61.3, 0xFFC9A3FF, 16, '✦'),
  _Star(67.6, 64.3, 0xFFFFD54A, 12, '✧'),
  _Star(81.5, 62.4, 0xFFFFB066, 20, '✦'),
  _Star(88.0, 64.4, 0xFFFFF7B0, 18, '★'),
  _Star(2.5, 70.5, 0xFFFFD54A, 12, '★'),
  _Star(23.5, 71.4, 0xFFC9A3FF, 18, '✦'),
  _Star(33.8, 72.8, 0xFFFFD54A, 12, '★'),
  _Star(53.0, 69.6, 0xFF9BE06A, 11, '★'),
  _Star(61.3, 75.7, 0xFFC9A3FF, 14, '✦'),
  _Star(79.3, 74.1, 0xFFFF7EB6, 18, '★'),
  _Star(91.7, 71.6, 0xFFFFD54A, 12, '★'),
  _Star(8.0, 83.4, 0xFFC9A3FF, 18, '✦'),
  _Star(23.4, 87.0, 0xFFFFFFFF, 11, '✦'),
  _Star(31.6, 83.7, 0xFFFFF7B0, 14, '✦'),
  _Star(47.4, 86.0, 0xFFFFFFFF, 18, '✧'),
  _Star(67.5, 79.3, 0xFF9BE06A, 14, '✦'),
  _Star(75.6, 82.9, 0xFFFFFFFF, 16, '★'),
  _Star(98.4, 80.4, 0xFFFF7EB6, 20, '✧'),
  _Star(9.8, 92.8, 0xFFFFD54A, 14, '✦'),
  _Star(20.6, 93.4, 0xFFFFF7B0, 12, '★'),
  _Star(37.0, 92.1, 0xFFFFD54A, 16, '✧'),
  _Star(45.3, 95.1, 0xFFFFF7B0, 16, '★'),
  _Star(59.4, 94.5, 0xFF5CD0F7, 11, '✧'),
  _Star(78.9, 95.9, 0xFFFFFFFF, 12, '★'),
  _Star(89.1, 94.2, 0xFFFFF7B0, 20, '✧'),
];

class LisStarField extends StatefulWidget {
  const LisStarField({super.key});

  @override
  State<LisStarField> createState() => _LisStarFieldState();
}

class _LisStarFieldState extends State<LisStarField> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat(reverse: true);
  late final AnimationController _b = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              for (var i = 0; i < _stars.length; i++)
                Positioned(
                  left: c.maxWidth * _stars[i].left / 100,
                  top: c.maxHeight * _stars[i].top / 100,
                  child: _BobStar(
                    // nth-child(odd) (1-based) → 5.2s
                    anim: i.isEven ? _a : _b,
                    star: _stars[i],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BobStar extends AnimatedWidget {
  const _BobStar({required Animation<double> anim, required this.star})
      : super(listenable: anim);

  final _Star star;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform((listenable as Animation<double>).value);
    return Transform.translate(
      offset: Offset(0, -7 * t),
      child: Text(
        star.char,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontFamilyFallback: _jpFallback,
          fontWeight: FontWeight.w700,
          fontSize: star.size,
          height: 1.2,
          color: Color(star.color),
          shadows: const [
            Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x59000000)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ encounter

/// Live site `readyGo()` replacement (`#encPop`): the enemy リスモン jumps in
/// with 「リスモンが あらわれた！」 and its voice; play starts 1.7s later.
Future<void> showLisEncounter(BuildContext context) async {
  final nav = Navigator.of(context);
  final player = AudioPlayer();
  unawaited(() async {
    try {
      await player.setVolume(0.95);
      await player.play(AssetSource('audio/voice/lis/lispopvoice.mp3'));
    } catch (_) {
      await AudioService.instance.playSfx('start');
    }
  }());
  nav.push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: const Duration(milliseconds: 150),
    // Back is blocked: this helper pops the route itself after 1.7s.
    pageBuilder: (_, _, _) => const PopScope(canPop: false, child: _Encounter()),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ));
  await Future<void>.delayed(const Duration(milliseconds: 1700));
  nav.pop();
  unawaited(Future<void>.delayed(const Duration(seconds: 3), player.dispose));
}

class _Encounter extends StatefulWidget {
  const _Encounter();

  @override
  State<_Encounter> createState() => _EncounterState();
}

class _EncounterState extends State<_Encounter> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  // Extra polish: a soft glow ring that swells behind the monster.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final imgW = math.min(w * 0.58, 290.0);
    // @keyframes encIn, cubic-bezier(.25,1.7,.5,1): 0% y80 s.4 o0 → 60% y-12
    // s1.12 → 100% y0 s1
    const curve = Cubic(0.25, 1.7, 0.5, 1);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_c, _glow]),
              builder: (context, child) {
                final t = curve.transform(_c.value);
                return Opacity(
                  opacity: (_c.value / 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 80 * (1 - t)),
                    child: Transform.scale(
                      scale: 0.4 + 0.6 * t,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: imgW * (0.78 + 0.06 * _glow.value),
                            height: imgW * (0.78 + 0.06 * _glow.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF9B6BFF).withValues(alpha: 0.45),
                                  const Color(0x009B6BFF),
                                ],
                              ),
                            ),
                          ),
                          child!,
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: ArtShadow(
                color: const Color(0x99000000),
                offset: const Offset(0, 12),
                blur: 30,
                child: Image.asset('assets/images/misc/lis pop t.webp', width: imgW),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC10122E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xEBFFFFFF), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        offset: Offset(0, 8),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Text(
                    'リスモンが あらわれた！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DotGothic16', // web #encMsg
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: Colors.white,
                      shadows: [
                        Shadow(offset: Offset(0, 2), blurRadius: 3, color: Color(0xE6000000)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ HUD

/// Web `.lives`: ♥ per max life, lost ones faded.
class LisHearts extends StatelessWidget {
  const LisHearts({super.key, required this.lives, required this.max});

  final int lives;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedScale(
            // Extra polish: a lost heart shrinks a bit.
            scale: i < lives ? 1 : 0.86,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '♥',
                style: TextStyle(
                  fontFamily: _zen,
                  fontSize: 18,
                  height: 1,
                  color: i < lives ? const Color(0xFFFF4D6D) : const Color(0x47FFFFFF),
                  shadows: i < lives
                      ? const [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000))]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ lismon

/// Web `.lismon`: floating monster (tap = replay) + 「🔊 きく」 + instruction.
/// [pulse] increments → `.hit` shake; [flee] → `.flee` fly-away.
class LisMonster extends StatefulWidget {
  const LisMonster({
    super.key,
    required this.imageWidth,
    required this.instruct,
    required this.instructSize,
    required this.pulse,
    required this.flee,
    required this.onTap,
  });

  final double imageWidth;
  final String instruct;
  final double instructSize;
  final int pulse;
  final bool flee;
  final VoidCallback onTap;

  @override
  State<LisMonster> createState() => _LisMonsterState();
}

class _LisMonsterState extends State<LisMonster> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _flee = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _down = false;

  @override
  void didUpdateWidget(covariant LisMonster old) {
    super.didUpdateWidget(old);
    if (widget.pulse != old.pulse) _hit.forward(from: 0);
    if (widget.flee && !old.flee) _flee.forward(from: 0);
    if (!widget.flee && old.flee) _flee.value = 0;
  }

  @override
  void dispose() {
    _float.dispose();
    _hit.dispose();
    _flee.dispose();
    super.dispose();
  }

  // @keyframes shake{0%,100%{x0}20%{x-10 r-5}60%{x10 r5}}
  static double _seg(double t, List<double> ts, List<double> vs) {
    for (var i = 1; i < ts.length; i++) {
      if (t <= ts[i]) {
        final k = Curves.ease.transform((t - ts[i - 1]) / (ts[i] - ts[i - 1]));
        return vs[i - 1] + (vs[i] - vs[i - 1]) * k;
      }
    }
    return vs.last;
  }

  Widget _image() {
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _hit, _flee]),
      builder: (context, child) {
        if (widget.flee || _flee.value > 0) {
          // flee: to{translateY(-220px) scale(.25) rotate(40deg); opacity:0}
          final t = Curves.ease.transform(_flee.value);
          return Opacity(
            opacity: 1 - t,
            child: Transform.translate(
              offset: Offset(0, -220 * t),
              child: Transform.rotate(
                angle: 40 * t * math.pi / 180,
                child: Transform.scale(scale: 1 - 0.75 * t, child: child),
              ),
            ),
          );
        }
        if (_hit.isAnimating) {
          const ts = [0.0, 0.2, 0.6, 1.0];
          final x = _seg(_hit.value, ts, const [0, -10, 10, 0]);
          final r = _seg(_hit.value, ts, const [0, -5, 5, 0]);
          return Transform.translate(
            offset: Offset(x, 0),
            child: Transform.rotate(angle: r * math.pi / 180, child: child),
          );
        }
        // float 2.8s: y 0 → -10, rotate -2° → 2°
        final f = Curves.easeInOut.transform(_float.value);
        return Transform.translate(
          offset: Offset(0, -10 * f),
          child: Transform.rotate(angle: (-2 + 4 * f) * math.pi / 180, child: child),
        );
      },
      child: ArtShadow(
        color: const Color(0x997828C8),
        offset: const Offset(0, 8),
        blur: 20,
        // Transparent battle art (embedded as base64 in the live page).
        child: Image.asset('$kLisDir/lismon-battle.webp', width: widget.imageWidth),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Web quirk kept on purpose: `.instruct{max-width:90%}` of the shrink-
    // wrapped `.lismon` column, so short instructions wrap under the image.
    final tp = TextPainter(
      text: TextSpan(
        text: widget.instruct,
        style: TextStyle(
          fontFamily: _zen,
          fontWeight: FontWeight.w900,
          fontSize: widget.instructSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final colW = math.max(widget.imageWidth, tp.width + 36 + 12);
    tp.dispose();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: SizedBox(
        width: colW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _image(),
            const SizedBox(height: 6),
            // .listenbtn
            AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 7),
              decoration: BoxDecoration(
                color: LisColors.gold,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: LisColors.goldShadow, offset: Offset(0, _down ? 2 : 4)),
                ],
              ),
              child: const Text(
                '🔊 きく',
                style: TextStyle(
                  fontFamily: _zen,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // .instruct
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: colW * 0.9),
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x52000000),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.instruct,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: _zen,
                    fontWeight: FontWeight.w900,
                    fontSize: widget.instructSize,
                    height: 1.4,
                    color: Colors.white,
                    shadows: const [
                      Shadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x80000000)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ combo

/// Web `.combo` with `comboPop` (.5s).
class LisCombo extends StatefulWidget {
  const LisCombo({super.key, required this.combo});

  final int combo;

  @override
  State<LisCombo> createState() => _LisComboState();
}

class _LisComboState extends State<LisCombo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void didUpdateWidget(covariant LisCombo old) {
    super.didUpdateWidget(old);
    if (widget.combo != old.combo) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // 0%{s.5 o0} 40%{s1.3 o1} 100%{s1}
        final double s, o;
        if (t < 0.4) {
          final k = Curves.ease.transform(t / 0.4);
          s = 0.5 + 0.8 * k;
          o = k;
        } else {
          s = 1.3 - 0.3 * Curves.ease.transform((t - 0.4) / 0.6);
          o = 1;
        }
        return Opacity(opacity: o, child: Transform.scale(scale: s, child: child));
      },
      child: ShineSweep(
        opacity: 0.55,
        period: const Duration(milliseconds: 1600),
        child: Text(
          '🔥 ${widget.combo} れんぞく！',
          style: const TextStyle(
            fontFamily: 'Fredoka',
          fontFamilyFallback: _jpFallback,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            height: 1.2,
            color: LisColors.gold,
            shadows: [Shadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x66000000))],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ choices

enum ChoiceFx { idle, shot, wrong }

/// Web `.choice` (text) / `.choices.emoji .choice` (picture tile), with
/// `.shot` (fade + grow), `.wrongpick` (shake) and the 💥 `boom()`.
class LisChoice extends StatefulWidget {
  const LisChoice({
    super.key,
    required this.label,
    required this.color,
    required this.emoji,
    required this.compact,
    required this.fx,
    required this.onTap,
    this.width,
  });

  final String label;
  final Color color;
  final bool emoji;
  final bool compact;
  final ChoiceFx fx;
  final VoidCallback onTap;
  final double? width;

  @override
  State<LisChoice> createState() => _LisChoiceState();
}

class _LisChoiceState extends State<LisChoice> with TickerProviderStateMixin {
  late final AnimationController _shot = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final AnimationController _wrong = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _boom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  bool _down = false;

  @override
  void didUpdateWidget(covariant LisChoice old) {
    super.didUpdateWidget(old);
    if (widget.fx != old.fx) {
      if (widget.fx == ChoiceFx.shot) {
        _shot.forward(from: 0);
        _boom.forward(from: 0);
      } else if (widget.fx == ChoiceFx.wrong) {
        _wrong.forward(from: 0);
      } else {
        _shot.value = 0;
        _wrong.value = 0;
        _boom.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _shot.dispose();
    _wrong.dispose();
    _boom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.emoji;
    final tile = emoji ? (widget.compact ? 96.0 : 120.0) : null;
    final radius = BorderRadius.circular(emoji ? 22 : 18);
    Widget body = Container(
      width: tile ?? widget.width,
      height: tile,
      alignment: Alignment.center,
      padding: emoji
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: radius,
        border: Border.all(color: const Color(0xB3FFFFFF), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 5)),
          BoxShadow(color: Color(0x59000000), offset: Offset(0, 8), blurRadius: 18),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        // :active{filter:brightness(1.15)}
        color: _down ? const Color(0x26FFFFFF) : Colors.transparent,
      ),
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontFamilyFallback: _jpFallback,
          fontWeight: FontWeight.w600,
          fontSize: emoji ? (widget.compact ? 46 : 60) : (widget.compact ? 19 : 22),
          height: emoji ? 1 : 1.2,
          color: Colors.white,
        ),
      ),
    );

    body = AnimatedBuilder(
      animation: Listenable.merge([_shot, _wrong]),
      builder: (context, child) {
        if (_shot.value > 0) {
          final t = _shot.value;
          return Opacity(
            opacity: 1 - t,
            child: Transform.scale(scale: 1 + 0.3 * t, child: child),
          );
        }
        if (_wrong.isAnimating) {
          // wp: 25% -8 / 75% +8
          final t = _wrong.value;
          final x = t < 0.25
              ? -8 * (t / 0.25)
              : t < 0.75
                  ? -8 + 16 * ((t - 0.25) / 0.5)
                  : 8 - 8 * ((t - 0.75) / 0.25);
          return Transform.translate(offset: Offset(x, 0), child: child);
        }
        return child!;
      },
      child: body,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.fx == ChoiceFx.idle ? widget.onTap : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          body,
          // .boom 💥: scale .3 → 1.8, fade (0.5s)
          AnimatedBuilder(
            animation: _boom,
            builder: (context, _) {
              final t = _boom.value;
              if (t == 0 || t == 1) return const SizedBox.shrink();
              return IgnorePointer(
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(
                    scale: 0.3 + 1.5 * t,
                    child: const Text('💥', style: TextStyle(fontSize: 40, height: 1)),
                  ),
                ),
              );
            },
          ),
          // Extra polish: a golden ring bursts out of the correct answer.
          AnimatedBuilder(
            animation: _boom,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_boom.value);
              if (_boom.value == 0 || _boom.value == 1) return const SizedBox.shrink();
              return IgnorePointer(
                child: Container(
                  width: 40 + 140 * t,
                  height: 40 + 140 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD84D).withValues(alpha: 1 - t),
                      width: 4 * (1 - t) + 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ review

/// Web `#review .rcard`: shown after a miss or time-up.
class LisReviewCard extends StatelessWidget {
  const LisReviewCard({
    super.key,
    required this.head,
    required this.answer,
    required this.en,
    required this.ja,
    required this.tip,
    required this.onListen,
    required this.onNext,
  });

  final String head;
  final String answer;
  final String en;
  final String ja;
  final String tip;
  final VoidCallback onListen;
  final VoidCallback onNext;

  Widget _row(String label, String value, {bool en = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: LisColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: _zen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontFamily: en ? 'Fredoka' : _zen,
                fontFamilyFallback: _jpFallback,
                fontWeight: en ? FontWeight.w600 : FontWeight.w700,
                fontSize: 15,
                color: LisColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEEF4FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LisColors.gold, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 12), blurRadius: 40),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            head,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _zen,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Color(0xFFFF5E6C),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFCE9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LisColors.c3, width: 2),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'こたえ → '),
                  TextSpan(text: answer, style: const TextStyle(fontSize: 28)),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _zen,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1F7A3D),
              ),
            ),
          ),
          _row('よみあげ', en, en: true),
          _row('いみ', ja),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LisColors.gold, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 きくポイント',
                  style: TextStyle(
                    fontFamily: _zen,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xFFB8860B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    fontFamily: _zen,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF7A5B00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: _PillButton(
                  label: '🔊 もう一回きく',
                  color: LisColors.c2,
                  shadow: const Color(0xFF1A5BB0),
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shadowDy: 4,
                  onTap: onListen,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _PillButton(
                    label: 'つぎへ ▶',
                    color: LisColors.gold,
                    shadow: LisColors.goldShadow,
                    fontSize: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shadowDy: 5,
                    radius: 40,
                    shine: true,
                    onTap: onNext,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.rlisten` / `.btn` pill (white text) that presses down.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.shadow,
    required this.fontSize,
    required this.padding,
    required this.shadowDy,
    required this.onTap,
    this.radius = 30,
    this.shine = false,
  });

  final String label;
  final Color color;
  final Color shadow;
  final double fontSize;
  final EdgeInsets padding;
  final double shadowDy;
  final double radius;
  final bool shine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: shadow, offset: Offset(0, shadowDy))],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            // A painted ▶ so it never turns into the colour emoji.
            for (final (i, part) in label.split('▶').indexed) ...[
              if (i > 0)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: CustomPaint(
                    size: Size(fontSize * 0.8, fontSize * 0.9),
                    painter: const _TrianglePainter(Colors.white),
                  ),
                ),
              TextSpan(text: part),
            ],
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: _zen,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
    if (shine) body = ShineSweep(opacity: 0.45, child: body);
    return Pressable(onTap: onTap, pressedScale: 1, pressedOffset: 2, child: body);
  }
}


class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.1)
      ..lineTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.12, h * 0.9)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}
