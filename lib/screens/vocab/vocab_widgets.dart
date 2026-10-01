import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';

/// Visual pieces of Vocabulary Busters (web `vocabulary-busters_無料版.html`).

const kNavy = Color(0xFF1F3864); // --navy
const kGold = Color(0xFFFFC93C); // --gold
const kBlue = Color(0xFF3F9BFF); // --blue
const kPink = Color(0xFFFF5E8A); // --pink
const kGreen = Color(0xFF3FCF7A); // --green

const kVocaDir = 'assets/images/monsters/vocamon';

// ------------------------------------------------------------ background

/// `#game` background (purple gradient) + `#starfront` floating stars.
class VocaGameBackground extends StatelessWidget {
  const VocaGameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // body: radial-gradient(circle at 50% 25%, #6a3df0, #3a1f8a 60%, #1a1340)
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.2,
          colors: [Color(0xFF6A3DF0), Color(0xFF3A1F8A), Color(0xFF1A1340)],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5B34D6), Color(0xFF3A1F8A), Color(0xFF241357)],
                stops: [0, 0.6, 1],
              ),
              boxShadow: [BoxShadow(color: Color(0x80000000), blurRadius: 40)],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const RepaintBoundary(child: StarFront()),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Star {
  const _Star(this.x, this.y, this.color, this.size, this.glyph);
  final double x, y;
  final int color;
  final double size;
  final String glyph;
}

// Exact positions from the web `#starfront` spans.
const _stars = [
  _Star(6.7, 4.4, 0xFF5CD0F7, 20, '★'), _Star(60.2, 1.5, 0xFFFF7EB6, 20, '★'),
  _Star(15.8, 18.6, 0xFFFFFFFF, 11, '★'), _Star(83.4, 13.3, 0xFFFF7EB6, 16, '★'),
  _Star(3.4, 30.2, 0xFF5CD0F7, 12, '✧'), _Star(36.4, 28.7, 0xFFFFB066, 18, '★'),
  _Star(60.1, 27.8, 0xFFC9A3FF, 20, '✧'), _Star(91.0, 31.1, 0xFFC9A3FF, 14, '✧'),
  _Star(25.1, 37.3, 0xFFFF7EB6, 12, '✦'), _Star(47.4, 39.0, 0xFFFFD54A, 14, '★'),
  _Star(67.7, 41.7, 0xFFC9A3FF, 18, '✦'), _Star(82.0, 39.5, 0xFFFFFFFF, 18, '★'),
  _Star(89.6, 43.1, 0xFFC9A3FF, 20, '✦'), _Star(7.9, 46.7, 0xFF5CD0F7, 18, '✦'),
  _Star(25.6, 47.8, 0xFF5CD0F7, 14, '★'), _Star(41.2, 54.4, 0xFF5CD0F7, 11, '✧'),
  _Star(44.5, 49.5, 0xFFFFB066, 16, '✦'), _Star(58.3, 52.7, 0xFF5CD0F7, 14, '✦'),
  _Star(79.3, 46.7, 0xFFFFB066, 18, '★'), _Star(88.2, 49.3, 0xFFFFFFFF, 16, '★'),
  _Star(11.9, 58.1, 0xFFFFB066, 20, '✧'), _Star(22.6, 62.1, 0xFFFF7EB6, 11, '✦'),
  _Star(33.0, 57.7, 0xFFFF7EB6, 12, '✧'), _Star(53.4, 58.6, 0xFF9BE06A, 12, '★'),
  _Star(64.0, 61.9, 0xFFFFFFFF, 11, '✧'), _Star(74.6, 60.9, 0xFFFF7EB6, 18, '✦'),
  _Star(87.1, 65.6, 0xFFFFB066, 16, '✦'), _Star(7.5, 73.5, 0xFFFFB066, 11, '★'),
  _Star(24.2, 74.2, 0xFFFF7EB6, 18, '★'), _Star(35.6, 68.2, 0xFFFFD54A, 18, '✧'),
  _Star(51.3, 71.1, 0xFF9BE06A, 14, '✦'), _Star(68.3, 74.3, 0xFFFFF7B0, 12, '✧'),
  _Star(72.9, 73.1, 0xFFFFD54A, 18, '✧'), _Star(91.7, 73.0, 0xFF9BE06A, 11, '★'),
  _Star(8.5, 80.4, 0xFFFFD54A, 14, '★'), _Star(23.0, 83.8, 0xFFFFD54A, 18, '✦'),
  _Star(39.1, 81.8, 0xFFFFD54A, 14, '✦'), _Star(55.6, 84.2, 0xFFFFF7B0, 20, '✦'),
  _Star(59.8, 86.9, 0xFF9BE06A, 14, '✧'), _Star(82.0, 80.5, 0xFFFF7EB6, 11, '★'),
  _Star(87.4, 79.5, 0xFFFF7EB6, 14, '✧'), _Star(2.3, 90.1, 0xFF9BE06A, 14, '✧'),
  _Star(26.0, 90.6, 0xFFFFB066, 20, '★'), _Star(35.9, 91.7, 0xFFFFB066, 16, '✦'),
  _Star(44.1, 90.8, 0xFFFFD54A, 14, '✦'), _Star(64.0, 92.8, 0xFFFFD54A, 18, '★'),
  _Star(75.8, 92.6, 0xFFC9A3FF, 20, '★'), _Star(98.8, 93.6, 0xFFFFB066, 20, '★'),
];

/// `#starfront span`: float up 7px, 4s (even) / 5.2s (odd) alternate.
class StarFront extends StatefulWidget {
  const StarFront({super.key});

  @override
  State<StarFront> createState() => _StarFrontState();
}

class _StarFrontState extends State<StarFront>
    with SingleTickerProviderStateMixin {
  // 104s = LCM of both full alternate cycles (8s, 10.4s): seamless loop.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 104),
  )..repeat();

  late final List<TextPainter> _painters = [
    for (final s in _stars)
      TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: s.glyph,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            fontSize: s.size,
            height: 1.2,
            color: Color(s.color),
            shadows: const [
              Shadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x59000000)),
            ],
          ),
        ),
      )..layout(),
  ];

  @override
  void dispose() {
    _c.dispose();
    for (final p in _painters) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter(_c, _painters));
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.anim, this.painters) : super(repaint: anim);

  final Animation<double> anim;
  final List<TextPainter> painters;

  @override
  void paint(Canvas canvas, Size size) {
    final secs = anim.value * 104;
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      // nth-child(odd) (1-based) → index 0, 2, 4…
      final dur = i.isEven ? 5.2 : 4.0;
      final ph = (secs / dur) % 2;
      final k = Curves.easeInOut.transform(ph <= 1 ? ph : 2 - ph);
      painters[i].paint(
        canvas,
        Offset(size.width * s.x / 100, size.height * s.y / 100 - 7 * k),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => false;
}

// ------------------------------------------------------------------ HUD

/// `.hud .info`: 第<b>1</b>/10　⭐<b>0</b>
class HudInfo extends StatelessWidget {
  const HudInfo({super.key, required this.qnum, required this.total, required this.score});

  final int qnum;
  final int total;
  final int score;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontFamily: 'Zen Maru Gothic',
      fontWeight: FontWeight.w700,
      fontSize: 15,
      color: Colors.white,
    );
    const b = TextStyle(fontSize: 19, color: kGold);
    return Text.rich(
      TextSpan(style: base, children: [
        const TextSpan(text: '第'),
        TextSpan(text: '$qnum', style: b),
        TextSpan(text: '/$total　'),
        // ⭐ emoji, drawn so it looks the same on every platform.
        const WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: 1),
            child: CustomPaint(size: Size(17, 17), painter: _EmojiStar()),
          ),
        ),
        TextSpan(
          text: '$score',
          style: b.copyWith(fontFamily: 'Zen Maru Gothic'),
        ),
      ]),
      maxLines: 1,
    );
  }
}

/// Colour-emoji style ⭐ (gold star, darker rim).
class _EmojiStar extends CustomPainter {
  const _EmojiStar();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.48;
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE066), Color(0xFFFFB300)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.4
        ..color = const Color(0xFFE08A00),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------- choices

enum ChoiceState { idle, correct, wrong }

/// `.choice` (mobileFit: Fredoka 600 19px, padding 10/16).
class ChoiceButton extends StatefulWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.width,
  });

  final String label;
  final ChoiceState state;
  final VoidCallback onTap;
  final double? width;

  @override
  State<ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<ChoiceButton>
    with SingleTickerProviderStateMixin {
  // @keyframes cpop .4s: scale 1 → 1.12 → 1
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void didUpdateWidget(covariant ChoiceButton old) {
    super.didUpdateWidget(old);
    if (widget.state == ChoiceState.correct && old.state != ChoiceState.correct) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final bg = switch (s) {
      ChoiceState.correct => kGreen,
      ChoiceState.wrong => kPink,
      ChoiceState.idle => kBlue,
    };
    final border = s == ChoiceState.correct
        ? Colors.white
        : Colors.white.withValues(alpha: 0.7);
    return Pressable(
      onTap: widget.onTap,
      pressedScale: 1,
      pressedOffset: 2,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) {
          final t = _pop.value;
          final sc = 1 + 0.12 * math.sin(t * math.pi);
          return Transform.scale(scale: sc, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 3),
            boxShadow: [
              const BoxShadow(color: Color(0x40000000), offset: Offset(0, 6)),
              // Extra: soft glow on the revealed answer.
              if (s == ChoiceState.correct)
                const BoxShadow(color: Color(0x8C7CFC9A), blurRadius: 18, spreadRadius: 1),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.21,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- spelling (lv3)

/// `.slot` / `.slot.filled`: 46×56 dashed box, blue when filled.
class SpellSlot extends StatelessWidget {
  const SpellSlot({super.key, required this.ch});

  final String? ch;

  @override
  Widget build(BuildContext context) {
    final filled = ch != null;
    return CustomPaint(
      painter: _DashedRRect(
        color: Colors.white.withValues(alpha: 0.4),
        dashed: !filled,
        fill: filled ? kBlue : Colors.white.withValues(alpha: 0.08),
      ),
      child: SizedBox(
        width: 46,
        height: 56,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(
              scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
              child: c,
            ),
            child: Text(
              ch ?? '',
              key: ValueKey(ch),
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect({required this.color, required this.dashed, required this.fill});

  final Color color;
  final bool dashed;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = fill);
    final inner = r.deflate(1.5);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (!dashed) {
      canvas.drawRRect(inner, p);
      return;
    }
    final path = Path()..addRRect(inner);
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 9, m.length)), p);
        d += 15;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRect old) =>
      old.dashed != dashed || old.fill != fill || old.color != color;
}

/// `.tile` / `.tile.used`: 52×60 gold letter tile.
class SpellTile extends StatelessWidget {
  const SpellTile({super.key, required this.ch, required this.used, required this.onTap});

  final String ch;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: used,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: used ? 0.22 : 1,
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.94,
          pressedOffset: 2,
          child: Container(
            width: 52,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kGold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0xFF8A6800), offset: Offset(0, 5))],
            ),
            child: Text(
              ch,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: 30,
                height: 1,
                color: kNavy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.minibtn`: white pill (← けす / 🔊 きく).
class MiniButton extends StatelessWidget {
  const MiniButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 1,
      pressedOffset: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0xFFBBBBBB), offset: Offset(0, 3))],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Zen Maru Gothic',
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: kNavy,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ explain

/// `.explain .ecard`: shown after a miss / time-up.
class ExplainCard extends StatelessWidget {
  const ExplainCard({
    super.key,
    required this.timeup,
    required this.word,
    required this.ja,
    required this.image,
    required this.onListen,
    required this.onNext,
  });

  final bool timeup;
  final String word;
  final String ja;
  final String? image;
  final VoidCallback onListen;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kPink, width: 5),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 14), blurRadius: 40),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeup ? '⏰ 時間切れ！' : '❌ おしい！',
            style: const TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: kPink,
            ),
          ),
          const SizedBox(height: 12),
          if (image != null) ...[
            Container(
              width: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(image!, width: 164, fit: BoxFit.fitWidth),
              ),
            ),
            const SizedBox(height: 14),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: 40,
                height: 1,
                color: kNavy,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ja,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Zen Maru Gothic',
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EButton(
                label: '🔊 きく',
                color: kBlue,
                shadow: const Color(0xFF1A5BB0),
                textColor: Colors.white,
                fontSize: 15,
                hPad: 20,
                onTap: onListen,
              ),
              const SizedBox(width: 12),
              _EButton(
                label: 'つぎへ ▶',
                color: kGold,
                shadow: const Color(0xFF8A6800),
                textColor: kNavy,
                fontSize: 16,
                hPad: 26,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EButton extends StatelessWidget {
  const _EButton({
    required this.label,
    required this.color,
    required this.shadow,
    required this.textColor,
    required this.fontSize,
    required this.hPad,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color shadow;
  final Color textColor;
  final double fontSize;
  final double hPad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 1,
      pressedOffset: 2,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Zen Maru Gothic',
            // ▶ is not in Zen Maru; use a text glyph, not the ▶️ emoji.
            fontFamilyFallback: const ['M PLUS Rounded 1c'],
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- encounter

/// Live site `readyGo()` replacement (`#encPop`): the enemy ボキャモン jumps
/// in with 「ボキャモンが あらわれた！」 and its voice; play starts 1.7s later.
Future<void> showVocaEncounter(BuildContext context) async {
  final nav = Navigator.of(context);
  final player = AudioPlayer();
  unawaited(() async {
    try {
      await player.setVolume(0.95);
      await player.play(AssetSource('audio/voice/voca/vocapopvoice.mp3'));
    } catch (_) {
      await AudioService.instance.playSfx('start');
    }
  }());
  nav.push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => const _Encounter(),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ));
  await Future<void>.delayed(const Duration(milliseconds: 1700));
  nav.pop();
  // Let the clip finish on its own, then release the player.
  unawaited(Future<void>.delayed(const Duration(seconds: 3), player.dispose));
}

class _Encounter extends StatefulWidget {
  const _Encounter();

  @override
  State<_Encounter> createState() => _EncounterState();
}

class _EncounterState extends State<_Encounter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // @keyframes encIn, cubic-bezier(.25,1.7,.5,1)
    const curve = Cubic(0.25, 1.7, 0.5, 1);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = curve.transform(_c.value);
                return Opacity(
                  opacity: (_c.value / 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 80 * (1 - t)),
                    child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
                  ),
                );
              },
              child: ArtShadow(
                color: const Color(0x99000000),
                offset: const Offset(0, 12),
                blur: 30,
                child: Image.asset(
                  'assets/images/misc/voca pop t.webp',
                  width: math.min(w * 0.58, 290),
                ),
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
                  BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 22),
                ],
              ),
              child: const Text(
                'ボキャモンが あらわれた！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DotGothic16', // web #encMsg
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: Colors.white,
                  shadows: [Shadow(offset: Offset(0, 2), blurRadius: 3, color: Color(0xE6000000))],
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
