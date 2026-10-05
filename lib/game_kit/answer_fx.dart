import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Answer feedback shared by every game, so a correct or wrong answer feels
/// the same in Vocabulary, Listening, Sentence and Talk:
///
/// - correct → gold ring + sparks bursting from the tapped answer, light
///   vibration;
/// - wrong → short screen shake ([ShakeScope]), stronger vibration.
///
/// With the system "reduce motion" setting on, bursts and shakes are
/// skipped and only the vibration remains.
class AnswerFx {
  AnswerFx._();

  static bool _calm(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Correct answer. [target] is the tapped widget's context (its centre is
  /// where the burst starts); without it the burst uses screen centre.
  static void correct(
    BuildContext context, {
    BuildContext? target,
    Color color = const Color(0xFFFFD54A),
  }) {
    HapticFeedback.lightImpact();
    if (_calm(context)) return;
    _burst(context, target, color);
  }

  /// Wrong answer or time up. Shakes the nearest [ShakeScope] above
  /// [context], or [shaker] when the scope is built below the caller.
  static void wrong(BuildContext context, {ShakeScopeState? shaker}) {
    HapticFeedback.heavyImpact();
    if (_calm(context)) return;
    (shaker ?? ShakeScope.maybeOf(context))?.shake();
  }

  static void _burst(BuildContext context, BuildContext? target, Color color) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    var center = MediaQuery.sizeOf(context).center(Offset.zero);
    final box = target?.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      center = box.localToGlobal(box.size.center(Offset.zero));
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Burst(
        center: center,
        color: color,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  /// Quick white flash when a battle starts (start screen → encounter).
  static Future<void> battleFlash(BuildContext context) async {
    if (_calm(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _Flash(onDone: () => entry.remove()));
    overlay.insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 140));
  }
}

/// Wrap a battle screen's body so [AnswerFx.wrong] can shake it.
class ShakeScope extends StatefulWidget {
  const ShakeScope({super.key, required this.child});

  final Widget child;

  static ShakeScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<ShakeScopeState>();

  @override
  State<ShakeScope> createState() => ShakeScopeState();
}

class ShakeScopeState extends State<ShakeScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  void shake() => _c.forward(from: 0);

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
        final t = _c.value;
        if (t == 0 || t == 1) return child!;
        // Damped horizontal wobble, ~3 swings, max 8px.
        final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

class _Burst extends StatefulWidget {
  const _Burst({required this.center, required this.color, required this.onDone});

  final Offset center;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _BurstPainter(_c, widget.center, widget.color),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.anim, this.center, this.color) : super(repaint: anim);

  final Animation<double> anim;
  final Offset center;
  final Color color;

  static const _sparks = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final out = Curves.easeOutCubic.transform(t);
    final fade = 1 - Curves.easeIn.transform(t);

    // Expanding ring.
    canvas.drawCircle(
      center,
      18 + 46 * out,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * fade + 1
        ..color = color.withValues(alpha: 0.85 * fade),
    );
    // Soft inner glow.
    canvas.drawCircle(
      center,
      26 * out,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35 * fade)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Sparks: short streaks flying outward, alternating gold / white.
    final p = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;
    for (var i = 0; i < _sparks; i++) {
      final a = i * 2 * math.pi / _sparks + 0.26;
      final dir = Offset(math.cos(a), math.sin(a));
      final r0 = 20 + 52 * out;
      final r1 = r0 + 12 * fade;
      p.color = (i.isEven ? color : Colors.white).withValues(alpha: fade);
      canvas.drawLine(center + dir * r0, center + dir * r1, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => false;
}

class _Flash extends StatefulWidget {
  const _Flash({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Quick rise to 70% white, then fade out.
          final a = t < 0.25 ? t / 0.25 * 0.7 : 0.7 * (1 - (t - 0.25) / 0.75);
          return ColoredBox(color: Colors.white.withValues(alpha: a.clamp(0, 1)));
        },
      ),
    );
  }
}
