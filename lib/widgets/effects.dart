import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// CSS `filter: drop-shadow(dx dy blur color)`: the shadow follows the
/// child's alpha (e.g. a monster cut-out), not its bounding box.
class ArtShadow extends StatelessWidget {
  const ArtShadow({
    super.key,
    required this.child,
    this.color = const Color(0x66000000),
    this.offset = const Offset(0, 6),
    this.blur = 12,
  });

  final Widget child;
  final Color color;
  final Offset offset;

  /// CSS blur radius in px (sigma = blur / 2).
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: offset,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur / 2,
                sigmaY: blur / 2,
                tileMode: TileMode.decal,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                child: child,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A soft diagonal light band that glides across [child] every [period],
/// drawn only on the child's opaque pixels (card art, buttons).
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 4200),
    this.delay = Duration.zero,
    this.opacity = 0.45,
  });

  final Widget child;
  final Duration period;

  /// Initial offset so neighbouring cards don't shine in unison.
  final Duration delay;
  final double opacity;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat();
    });
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
      child: widget.child,
      builder: (context, child) {
        // Sweep during the first 30% of each cycle, then rest.
        final t = (_c.value / 0.3).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) return child!;
        final x = -1.6 + 3.2 * Curves.easeInOutSine.transform(t);
        final a = widget.opacity;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.5, -1),
            end: Alignment(x + 0.5, 1),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: a),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// Entrance: fades in while rising [dy] px (and optionally scaling up),
/// after [delay]. Use increasing delays for a staggered list.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.dy = 18,
    this.fromScale = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double dy;
  final double fromScale;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.dy * (1 - v)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * v,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Like [Reveal], but waits until the widget is scrolled into view of the
/// nearest [Scrollable] (web story panels appearing as you scroll).
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.dy = 28,
    this.fromScale = 0.96,
  });

  final Widget child;
  final double dy;
  final double fromScale;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  ScrollPosition? _pos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted || _c.isAnimating || _c.isCompleted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final screenH = MediaQuery.sizeOf(context).height;
    // Start once the top of the panel is within the lower 85% of the screen.
    if (top < screenH * 0.85) {
      _c.forward();
      _pos?.removeListener(_check);
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_check);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, widget.dy * (1 - v)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * v,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
