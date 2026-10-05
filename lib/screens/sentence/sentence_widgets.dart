import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';

/// Web CSS variables.
class SenColors {
  static const navy = Color(0xFF1F3864);
  static const gold = Color(0xFFFFC93C);
  static const c1 = Color(0xFFFF5E8A);
  static const c2 = Color(0xFF3F9BFF);
  static const c3 = Color(0xFF3FCF7A);

  /// `loadQuestion()` word palette (shuffled per question).
  static const palette = [
    Color(0xFFFF5E8A),
    Color(0xFF3F9BFF),
    Color(0xFF3FCF7A),
    Color(0xFFFF9F43),
    Color(0xFFB06BFF),
    Color(0xFF22B8C4),
    Color(0xFFF4C430),
  ];
}

const _gramDir = 'assets/images/monsters/gramon';

class SenAssets {
  static const keyVisual = 'assets/images/hub/gra-top.webp';
  static const tabTen = 'assets/images/hub/tab-sen-ten.webp';
  static const tabEndless = 'assets/images/hub/tab-sen-endless.webp';
  static const bannerKyuu = 'assets/images/hub/banner-kyuu.webp';
  static const bannerAsobi = 'assets/images/hub/banner-asobi.webp';
  static const happy = '$_gramDir/gra-happy.webp';
  static const sad = '$_gramDir/gra-sad.webp';
  static const win = '$_gramDir/gra-win.webp';
  static const lose = '$_gramDir/gra-lose.webp';
  static const friend = '$_gramDir/グラ友.webp';
  static const poseBase = '$_gramDir/gramon-pose';

  /// The web's inline coin image (`#gramon`, base64 in the live page).
  static const battleArt = '$_gramDir/gramon-coin.webp';

  /// `../app illust/gra pop t.png` (encounter pop-up, live site only).
  static const encounter = 'assets/images/misc/gra pop t.webp';
  static const encounterVoice = 'audio/voice/grapopvoice.mp3';
}

// ---------------------------------------------------------------- start

/// Section ribbon (banner-kyuu / banner-asobi), 96% wide.
class SenBanner extends StatelessWidget {
  const SenBanner(this.asset, {super.key});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.96,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Image.asset(asset, fit: BoxFit.fitWidth),
        ),
      ),
    );
  }
}

/// Web `#shields`: glossy 5級 / 4級 / 3級 gems with the endless best
/// (「最高N」) inside, as in the final `ぷっくり宝石` CSS override.
class ShieldTabs extends StatelessWidget {
  const ShieldTabs({
    super.key,
    required this.selected,
    required this.bests,
    required this.onSelect,
  });

  final String selected;
  final Map<String, int> bests;
  final ValueChanged<String> onSelect;

  static const _grades = ['g5', 'g4', 'g3'];
  static const _gradients = [
    [Color(0xFFBFE0FF), Color(0xFF2E6FE0), Color(0xFF1450B0)],
    [Color(0xFFFFE6A8), Color(0xFFF3A52A), Color(0xFFD98014)],
    [Color(0xFFFFC2CF), Color(0xFFEC3F5E), Color(0xFFC01F3E)],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = math.min(118.0, (c.maxWidth - 20) / 3);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                SizedBox(
                  width: w,
                  child: _Shield(
                    label: '${_grades[i].substring(1)}級',
                    best: bests[_grades[i]] ?? 0,
                    colors: _gradients[i],
                    active: _grades[i] == selected,
                    onTap: () => onSelect(_grades[i]),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Shield extends StatelessWidget {
  const _Shield({
    required this.label,
    required this.best,
    required this.colors,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int best;
  final List<Color> colors;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        height: 64,
        transform: Matrix4.identity()
          ..translateByDouble(0, active ? -3 : 0, 0, 1)
          ..scaleByDouble(active ? 1.06 : 1, active ? 1.06 : 1, 1, 1),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          gradient: LinearGradient(
            begin: const Alignment(-0.26, -1),
            end: const Alignment(0.26, 1),
            colors: colors,
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x38000000),
              offset: Offset(0, active ? 8 : 5),
            ),
            if (active)
              const BoxShadow(color: Color(0xA6FFFFFF), blurRadius: 16),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 3,
                left: 8,
                right: 8,
                height: 64 * 0.4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.78),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 3,
                right: 9,
                child: Text(
                  '✦',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Mochiy Pop One',
                      fontSize: 26,
                      height: 1,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 2,
                          color: Color(0x4D000000),
                        ),
                      ],
                    ),
                  ),
                  // .best{font-size:9px;margin-top:1px;min-height:12px}
                  SizedBox(
                    height: 13,
                    child: best > 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              '最高$best',
                              style: const TextStyle(
                                fontFamily: 'Zen Maru Gothic',
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                height: 1.3,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 1,
                                    color: Color(0x66000000),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- encounter

/// Live-site `readyGo()` replacement: 「グラモンが あらわれた！」 pop-up
/// (monster bounces in, grapopvoice plays) for 1.7 s before each game.
Future<void> showGramEncounter(BuildContext context) async {
  final nav = Navigator.of(context);
  nav.push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) => const _EncounterPop(),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
  AudioService.instance.playVoiceAsset(SenAssets.encounterVoice);
  await Future<void>.delayed(const Duration(milliseconds: 1700));
  nav.pop();
}

class _EncounterPop extends StatefulWidget {
  const _EncounterPop();

  @override
  State<_EncounterPop> createState() => _EncounterPopState();
}

class _EncounterPopState extends State<_EncounterPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // @keyframes encIn (.5s cubic-bezier(.25,1.7,.5,1)):
    // translateY(80) scale(.4) → -12 / 1.12 → 0 / 1
    const inEnd = 0.5 / 1.7;
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = (_c.value / inEnd).clamp(0.0, 1.0);
            final double dy, s;
            if (t < 0.6) {
              final k = Curves.easeOut.transform(t / 0.6);
              dy = 80 + (-12 - 80) * k;
              s = 0.4 + (1.12 - 0.4) * k;
            } else {
              final k = Curves.easeInOut.transform((t - 0.6) / 0.4);
              dy = -12 + 12 * k;
              s = 1.12 - 0.12 * k;
            }
            // Extra: a soft purple aura that breathes behind the monster.
            final aura = 0.5 + 0.5 * math.sin(_c.value * math.pi * 3);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: t * (0.55 + 0.25 * aura),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.55,
                          colors: [Color(0x99B06BFF), Color(0x00B06BFF)],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: (t * 2).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(
                          scale: s,
                          child: SizedBox(
                            width: math.min(290, w * 0.58),
                            child: ArtShadow(
                              color: const Color(0x99000000),
                              offset: const Offset(0, 12),
                              blur: 30,
                              child: Image.asset(SenAssets.encounter),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Opacity(
                      opacity: t,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC10122E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80000000),
                              offset: Offset(0, 8),
                              blurRadius: 22,
                            ),
                          ],
                        ),
                        // One line, shrinking if needed (web never wraps it).
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'グラモンが あらわれた！',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'DotGothic16', // web #encMsg
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: 1,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 3,
                                  color: Color(0xE6000000),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- battle

/// Web `.word`: colored Fredoka pill the player taps (shoots).
class WordChip extends StatelessWidget {
  const WordChip({
    super.key,
    required this.text,
    required this.color,
    required this.fontSize,
    required this.onTap,
  });

  final String text;
  final Color color;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.93,
      haptic: false,
      child: Container(
        // mobileFit: .word{padding:9px 12px!important}
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.7),
            width: 3,
          ),
          // Extra: a faint top gloss on the flat web colour.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(color, Colors.white, 0.12)!, color],
            stops: const [0, 0.55],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), offset: Offset(0, 5)),
            BoxShadow(
              color: Color(0x59000000),
              offset: Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
            height: 1.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Web `.slot`: dashed answer box that fills with the shot word's colour.
class AnswerSlot extends StatelessWidget {
  const AnswerSlot({
    super.key,
    required this.number,
    required this.text,
    required this.color,
    required this.small,
  });

  final int number;
  final String? text;
  final Color? color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final filled = text != null;
    final h = small ? 40.0 : 46.0;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minWidth: small ? 48 : 54),
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: filled ? Border.all(color: color!, width: 3) : null,
        boxShadow: filled
            ? [BoxShadow(color: color!.withValues(alpha: 0.55), blurRadius: 14)]
            : null,
      ),
      child: filled
          ? Center(
              widthFactor: 1,
              child: Text(
                text!,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            )
          : const SizedBox(width: 0, height: 0),
    );
    return AnimatedScale(
      scale: filled ? 1.05 : 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          filled
              ? box
              : CustomPaint(
                  foregroundPainter: const _DashedRRect(
                    color: Color(0x59FFFFFF),
                    width: 3,
                    radius: 12,
                  ),
                  child: box,
                ),
          // .slot .n{position:absolute;margin-top:-44px;font-size:11px}
          Positioned(
            top: -8,
            child: Opacity(
              opacity: 0.8,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontFamily: 'Zen Maru Gothic',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  height: 1.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  const _DashedRRect({
    required this.color,
    required this.width,
    required this.radius,
  });

  final Color color;
  final double width;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius - width / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()..addRRect(r);
    for (final m in path.computeMetrics()) {
      // Chrome draws 3px dashes about 3× as long as they are wide.
      const dash = 8.0, gap = 5.0;
      final n = (m.length / (dash + gap)).round();
      final step = m.length / n;
      for (var i = 0; i < n; i++) {
        canvas.drawPath(m.extractPath(i * step, i * step + step * 0.62), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRect old) =>
      old.color != color || old.width != width;
}

/// Web `.gramon`: the enemy coin that floats, shakes on a hit and flees
/// when the sentence is complete.
enum GramonState { idle, hit, flee }

class GramonCoin extends StatefulWidget {
  const GramonCoin({
    super.key,
    required this.state,
    required this.size,
    required this.hitSerial,
  });

  final GramonState state;
  final double size;

  /// Bumped on every hit so consecutive hits restart the shake.
  final int hitSerial;

  @override
  State<GramonCoin> createState() => _GramonCoinState();
}

class _GramonCoinState extends State<GramonCoin> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final AnimationController _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final AnimationController _flee = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didUpdateWidget(GramonCoin old) {
    super.didUpdateWidget(old);
    if (widget.state == GramonState.flee && old.state != GramonState.flee) {
      _flee.forward(from: 0);
    } else if (widget.state != GramonState.flee) {
      _flee.value = 0;
    }
    if (widget.hitSerial != old.hitSerial && widget.state == GramonState.hit) {
      _hit.forward(from: 0);
      _float.forward(from: 0); // CSS restarts `float` after the shake
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _hit.dispose();
    _flee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    // The medallion art already includes its gold rim.
    final coin = ArtShadow(
      // filter: drop-shadow(0 8px 20px rgba(120,40,200,.55))
      color: const Color(0x8C7828C8),
      offset: const Offset(0, 8),
      blur: 20,
      child: Image.asset(SenAssets.battleArt, width: s, height: s),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _hit, _flee]),
      child: Opacity(opacity: 0.96, child: coin),
      builder: (context, child) {
        var dx = 0.0, dy = 0.0, rot = 0.0, scale = 1.0, op = 1.0;
        if (_flee.value > 0) {
          // @keyframes flee{to{translateY(-200px) scale(.3);opacity:0}}
          final k = Curves.ease.transform(_flee.value);
          dy = -200 * k;
          scale = 1 - 0.7 * k;
          op = 1 - k;
        } else if (_hit.isAnimating) {
          // shake: 20% -8% / -6°, 60% +8% / 6°
          final t = _hit.value;
          double k(double a, double b, double x) => a + (b - a) * x;
          if (t < 0.2) {
            final x = t / 0.2;
            dx = k(0, -0.08, x);
            rot = k(0, -6, x);
          } else if (t < 0.6) {
            final x = (t - 0.2) / 0.4;
            dx = k(-0.08, 0.08, x);
            rot = k(-6, 6, x);
          } else {
            final x = (t - 0.6) / 0.4;
            dx = k(0.08, 0, x);
            rot = k(6, 0, x);
          }
          dx *= s;
        } else {
          // float 2.6s ease-in-out: 0 → -12px / -2° → 2°
          final t = _float.value;
          final k = Curves.easeInOut.transform(t < 0.5 ? t * 2 : 2 - t * 2);
          dy = -12 * k;
          rot = -2 + 4 * k;
        }
        return Opacity(
          opacity: op.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: rot * math.pi / 180,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Web `.boom` (💥 scale .3 → 1.8, fading, .5 s) plus a ring of sparks in
/// the word's colour.
class BoomBurst extends StatefulWidget {
  const BoomBurst({super.key, required this.color});

  final Color color;

  @override
  State<BoomBurst> createState() => _BoomBurstState();
}

class _BoomBurstState extends State<BoomBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();
  final _seed = math.Random().nextDouble() * math.pi;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _SparkPainter(t, widget.color, _seed),
                ),
                Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.3 + 1.5 * t,
                    child: const Text(
                      '💥',
                      style: TextStyle(fontSize: 40, height: 1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t, this.color, this.seed);

  final double t;
  final Color color;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final e = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);
    // ring
    canvas.drawCircle(
      c,
      10 + 42 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * fade
        ..color = Colors.white.withValues(alpha: 0.8 * fade),
    );
    final p = Paint()..color = color.withValues(alpha: fade);
    final w = Paint()..color = Colors.white.withValues(alpha: fade);
    for (var i = 0; i < 10; i++) {
      final a = seed + i * math.pi * 2 / 10;
      final r = 14 + 44 * e * (i.isEven ? 1 : 0.75);
      final o = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(
        o,
        (i.isEven ? 4.5 : 3) * fade + 0.5,
        i % 3 == 0 ? w : p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.t != t;
}

/// Web `.combo`: 「🔥 N れんぞく！」 that pops (comboPop .5 s) each time.
class ComboBadge extends StatefulWidget {
  const ComboBadge({super.key, required this.combo, required this.serial});

  final int combo;
  final int serial;

  @override
  State<ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<ComboBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void didUpdateWidget(ComboBadge old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) _c.forward(from: 0);
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
        final double s, o;
        if (t < 0.4) {
          final k = Curves.ease.transform(t / 0.4);
          s = 0.5 + 0.8 * k;
          o = k;
        } else {
          final k = Curves.ease.transform((t - 0.4) / 0.6);
          s = 1.3 - 0.3 * k;
          o = 1;
        }
        return Opacity(
          opacity: o,
          child: Transform.scale(scale: s, child: child),
        );
      },
      child: Text(
        '🔥 ${widget.combo} れんぞく！',
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontFamilyFallback: ['M PLUS Rounded 1c'],
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: SenColors.gold,
          shadows: [
            Shadow(
              offset: Offset(0, 2),
              blurRadius: 6,
              color: Color(0x66000000),
            ),
            Shadow(blurRadius: 14, color: Color(0x80FF9F43)),
          ],
        ),
      ),
    );
  }
}

/// Web `.explain .ecard`: the answer, its parts, the tip and
/// 「🔊 きく」「つぎへ ▶」.
class ExplainCard extends StatelessWidget {
  const ExplainCard({
    super.key,
    required this.timeup,
    required this.english,
    required this.japanese,
    required this.parts,
    required this.tip,
    required this.onListen,
    required this.onNext,
  });

  final bool timeup;
  final String english;
  final String japanese;

  /// (label, word) in answer order.
  final List<(String, String)> parts;
  final String tip;
  final VoidCallback onListen;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const zen = 'Zen Maru Gothic';
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SenColors.gold, width: 4),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFEEF4FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            offset: Offset(0, 12),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeup ? '⏰ 時間切れ！' : '❌ おしい！',
            style: const TextStyle(
              fontFamily: zen,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFFFF5E6C),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAFCE9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SenColors.c3, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  english,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    height: 1.3,
                    color: Color(0xFF1F7A3D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  japanese,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: zen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < parts.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCDD9F0)),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${i + 1}',
                          style: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2476E6),
                          ),
                        ),
                        TextSpan(text: ' ${parts[i].$1}：${parts[i].$2}'),
                      ],
                    ),
                    style: const TextStyle(
                      fontFamily: zen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: SenColors.navy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SenColors.gold, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 ポイント',
                  style: TextStyle(
                    fontFamily: zen,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xFFB8860B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: const TextStyle(
                    fontFamily: zen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF7A5B00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: GameButton(
                  label: '🔊 きく',
                  onTap: onListen,
                  color: SenColors.c2,
                  textColor: Colors.white,
                  shadowColor: const Color(0xFF1A5BB0),
                  fontSize: 15,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: GameButton(
                  label: 'つぎへ ▶',
                  onTap: onNext,
                  fontSize: 15,
                  shine: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
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

/// Glow + blur backdrop used by the explain overlay (web rgba(8,16,40,.74)).
class DimBackdrop extends StatelessWidget {
  const DimBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
      child: ColoredBox(color: const Color(0xBD081028), child: child),
    );
  }
}
