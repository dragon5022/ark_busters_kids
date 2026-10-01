import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../widgets/effects.dart';

/// Pieces of the end screen shared by all games, plus the ready-go intro.

/// Web `readyGo()` wrapper: shows "Are you ready?" → "GO!" over the game
/// while the ready-go voice plays; completes when play should begin.
Future<void> showReadyGo(BuildContext context) async {
  final go = ValueNotifier(false);
  final nav = Navigator.of(context);
  nav.push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => _ReadyGo(go: go),
    transitionsBuilder: (_, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  ));
  await AudioService.instance.readyGo(onGo: () => go.value = true);
  nav.pop();
  go.dispose();
}

class _ReadyGo extends StatelessWidget {
  const _ReadyGo({required this.go});

  final ValueNotifier<bool> go;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x66140C2D),
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: go,
          builder: (context, isGo, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, a) => ScaleTransition(
              scale: Tween(begin: 0.4, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Text(
              isGo ? 'GO!' : 'Are you ready?',
              key: ValueKey(isGo),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: isGo ? 84 : 40,
                color: isGo ? const Color(0xFFFFD54A) : Colors.white,
                shadows: const [
                  Shadow(offset: Offset(3, 3), color: Color(0xFF5B21B6)),
                  Shadow(blurRadius: 18, color: Color(0x99FFFFFF)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web `.rank`: huge gold Fredoka letter with a hard navy shadow. Stamps in;
/// an S rank gets a rotating burst of light behind it.
class RankLetter extends StatefulWidget {
  const RankLetter({super.key, required this.rank, this.fontSize = 96});

  final String rank;
  final double fontSize;

  @override
  State<RankLetter> createState() => _RankLetterState();
}

class _RankLetterState extends State<RankLetter> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _in.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.rank == 'S';
    final size = widget.fontSize * 1.9;
    return SizedBox(
      width: size,
      height: widget.fontSize * 1.15,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (s)
            AnimatedBuilder(
              animation: Listenable.merge([_in, _spin]),
              builder: (context, _) => Opacity(
                opacity: Curves.easeOut.transform(_in.value),
                child: Transform.rotate(
                  angle: _spin.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _RaysPainter(),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _in,
            builder: (context, child) {
              final t = Curves.elasticOut.transform(_in.value);
              return Opacity(
                opacity: _in.value.clamp(0.0, 0.25) * 4,
                child: Transform.scale(
                  scale: 2.2 - 1.2 * t,
                  child: Transform.rotate(
                    angle: (1 - t) * -0.3,
                    child: child,
                  ),
                ),
              );
            },
            child: Text(
              widget.rank,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w700,
                fontSize: widget.fontSize,
                height: 1,
                color: const Color(0xFFFFC93C),
                shadows: const [
                  Shadow(offset: Offset(4, 4), color: Color(0xFF1F3864)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE9A8).withValues(alpha: 0.75),
          const Color(0xFFFFE9A8).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * r, c.dy + math.sin(a - 0.12) * r)
        ..lineTo(c.dx + math.cos(a + 0.12) * r, c.dy + math.sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Web `.resultimg`: win / lose art, 88% wide (max 380), gold border.
class ResultImage extends StatelessWidget {
  const ResultImage({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Reveal(
      fromScale: 0.9,
      child: FractionallySizedBox(
        widthFactor: 0.88,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC93C), width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(asset, fit: BoxFit.fitWidth),
            ),
          ),
        ),
      ),
    );
  }
}

/// Web `#befriendBox .bf-in`: 「🎉 ○○が なかまに なった！」 with a hop.
class BefriendBanner extends StatelessWidget {
  const BefriendBanner({super.key, required this.image, required this.name});

  final String image;
  final String name;

  @override
  Widget build(BuildContext context) {
    return _Hop(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFB300), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x66FFB300), blurRadius: 16),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(image, width: 56, height: 56, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '🎉 $nameが なかまに なった！',
                style: const TextStyle(
                  color: Color(0xFFC77800),
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Web `.newcards`: 「✨ あたらしいカード GET！ ✨」 and the drawn pose cards.
/// Cards flip in one by one; SR / レア cards glow.
class NewCardsReveal extends StatelessWidget {
  const NewCardsReveal({
    super.key,
    required this.poseBase,
    required this.cards,
  });

  /// e.g. `assets/images/monsters/vocamon/vocamon-pose` (+ `N.webp`)
  final String poseBase;
  final List<int> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          const Text(
            '✨ あたらしいカード GET！ ✨',
            style: TextStyle(
              color: Color(0xFFC77800),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < cards.length; i++)
                _FlipCard(
                  delay: Duration(milliseconds: 400 + 260 * i),
                  image: '$poseBase${cards[i]}.webp',
                  number: cards[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({
    required this.delay,
    required this.image,
    required this.number,
  });

  final Duration delay;
  final String image;
  final int number;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _flip.forward();
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rar = ProgressService.rarity(widget.number);
    final label = '#${widget.number}${rar.isEmpty ? '' : ' $rar'}';
    final front = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glow,
          builder: (context, child) => Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFCF3D), width: 2),
              boxShadow: rar.isEmpty
                  ? null
                  : [
                      BoxShadow(
                        color: HSVColor.fromAHSV(
                          1,
                          rar == 'SR' ? _glow.value * 360 : 45,
                          0.7,
                          1,
                        ).toColor().withValues(alpha: 0.85),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: child,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(widget.image, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5B21B6),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
    final back = Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCF3D), width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text('?', style: TextStyle(color: Colors.white, fontSize: 28)),
    );
    return SizedBox(
      width: 66,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOutBack.transform(_flip.value);
          final angle = t * math.pi;
          final showFront = angle > math.pi / 2;
          return Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(showFront ? angle - math.pi : angle),
            child: showFront
                ? front
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [back, const SizedBox(height: 15)],
                  ),
          );
        },
      ),
    );
  }
}

/// `@keyframes rjump`: rise from below, overshoot, settle.
class _Hop extends StatefulWidget {
  const _Hop({required this.child});

  final Widget child;

  @override
  State<_Hop> createState() => _HopState();
}

class _HopState extends State<_Hop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // cubic-bezier(.3,1.5,.5,1) ≈ strong ease-out-back
        final t = const Cubic(0.3, 1.5, 0.5, 1).transform(_c.value);
        return Opacity(
          opacity: (_c.value * 2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - t)),
            child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
          ),
        );
      },
    );
  }
}
