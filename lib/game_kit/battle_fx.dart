import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/effects.dart';

/// Drives [ReactionLayer]: call [show] after each answer.
class ReactionController extends ChangeNotifier {
  bool ok = true;
  String text = '';

  /// Web `monReact(ok)`: happy monster + 「やったね！」 (with confetti) or
  /// sad monster + 「おしい！」.
  void show(bool ok, {String? text}) {
    this.ok = ok;
    this.text = text ?? (ok ? 'やったね！' : 'おしい！');
    notifyListeners();
  }
}

/// Web `#reactLayer`: small monster with a speech bubble in the lower-right
/// corner (84px, right 10 / bottom 84), plus a confetti burst on success.
/// Place it last in the game's [Stack].
class ReactionLayer extends StatefulWidget {
  const ReactionLayer({
    super.key,
    required this.controller,
    required this.happyAsset,
    required this.sadAsset,
    this.bottom = 84,
  });

  final ReactionController controller;
  final String happyAsset;
  final String sadAsset;
  final double bottom;

  @override
  State<ReactionLayer> createState() => _ReactionLayerState();
}

class _ReactionLayerState extends State<ReactionLayer>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 0,
  );
  int _seen = 0;
  int _confettiKey = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onShow);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onShow);
    _enter.dispose();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _onShow() async {
    final token = ++_seen;
    setState(() {
      if (widget.controller.ok) _confettiKey++;
    });
    _fade.value = 1;
    await _enter.forward(from: 0);
    // Web: hide after 1000ms (ok) / 800ms (ng) from the start.
    await Future<void>.delayed(
      Duration(milliseconds: widget.controller.ok ? 400 : 250),
    );
    if (!mounted || token != _seen) return;
    await _fade.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return IgnorePointer(
      child: Stack(
        children: [
          if (_confettiKey > 0)
            Positioned.fill(child: ConfettiBurst(key: ValueKey(_confettiKey))),
          Positioned(
            right: 10,
            bottom: widget.bottom + MediaQuery.paddingOf(context).bottom,
            child: FadeTransition(
              opacity: _fade,
              child: AnimatedBuilder(
                animation: _enter,
                builder: (context, child) {
                  final t = _enter.value;
                  if (c.ok) {
                    // @keyframes rjump
                    final dy = t < 0.55
                        ? _lerp(40, -14, _ease(t / 0.55))
                        : _lerp(-14, 0, _ease((t - 0.55) / 0.45));
                    final s = t < 0.55
                        ? _lerp(0.6, 1.12, _ease(t / 0.55))
                        : _lerp(1.12, 1, _ease((t - 0.55) / 0.45));
                    return Opacity(
                      opacity: (t / 0.55).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(scale: s, child: child),
                      ),
                    );
                  }
                  // @keyframes rshake
                  return Transform.translate(
                    offset: Offset(_shakeX(t), 0),
                    child: Transform.rotate(angle: _shakeR(t), child: child),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Bubble(text: c.text, ok: c.ok),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 84,
                      child: ArtShadow(
                        color: const Color(0x4D000000),
                        offset: const Offset(0, 6),
                        blur: 12,
                        child: Image.asset(
                          c.ok ? widget.happyAsset : widget.sadAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
  static double _ease(double t) => Curves.easeOut.transform(t.clamp(0, 1));

  // rshake keyframes: 15% -13px/-5°, 35% 12px/5°, 55% -9px, 75% 8px.
  static const _xs = [0.0, -13.0, 12.0, -9.0, 8.0, 0.0];
  static const _rs = [0.0, -5.0, 5.0, 0.0, 0.0, 0.0];
  static const _ts = [0.0, 0.15, 0.35, 0.55, 0.75, 1.0];

  static double _key(List<double> v, double t) {
    for (var i = 1; i < _ts.length; i++) {
      if (t <= _ts[i]) {
        final k = (t - _ts[i - 1]) / (_ts[i] - _ts[i - 1]);
        return _lerp(v[i - 1], v[i], Curves.easeInOut.transform(k));
      }
    }
    return v.last;
  }

  static double _shakeX(double t) => _key(_xs, t);
  static double _shakeR(double t) => _key(_rs, t) * math.pi / 180;
}

/// `#reactMsg`: white bubble with purple (ng) or orange (ok) outline.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFFC2410C) : const Color(0xFF5B21B6);
    return CustomPaint(
      painter: _TailPainter(color),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x405B21B6), offset: Offset(0, 4)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// `#reactMsg:after`: downward tail 20px from the right edge.
class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width - 6 - 20 - 7;
    final y = size.height;
    final p = Path()
      ..moveTo(x, y - 1)
      ..lineTo(x + 14, y - 1)
      ..lineTo(x + 7, y + 8)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) => old.color != color;
}

/// Web `confetti()`: pieces fall from 28% height, spinning, fading out.
/// Richer than the web (more pieces, drift, mixed shapes); ~1.3s total.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 26});

  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFFFD54A),
    Color(0xFFFF7EB6),
    Color(0xFF5CD0F7),
    Color(0xFFA78BFA),
    Color(0xFF7CFC9A),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  late final List<_Piece> _pieces = List.generate(widget.count, (i) {
    final r = math.Random();
    return _Piece(
      x: 0.08 + r.nextDouble() * 0.84,
      delay: r.nextDouble() * 0.15,
      drift: (r.nextDouble() - 0.5) * 60,
      spin: 300 + r.nextDouble() * 240,
      color: _colors[i % _colors.length],
      round: i % 4 == 0,
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(painter: _ConfettiPainter(_c, _pieces)),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.drift,
    required this.spin,
    required this.color,
    required this.round,
  });

  final double x;
  final double delay;
  final double drift;
  final double spin;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.pieces) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final t = ((anim.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final e = Curves.easeIn.transform(t); // conffall: ease-in
      final x = p.x * size.width + p.drift * t;
      final y = size.height * 0.28 - 30 + 340 * e;
      paint.color = p.color.withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * e * math.pi / 180);
      if (p.round) {
        canvas.drawCircle(Offset.zero, 6, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -7, 12, 14),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => false;
}

/// Drives [FeedbackPop].
class FeedbackController extends ChangeNotifier {
  String text = '';
  Color color = Colors.white;

  /// Web `feedback(text, color)`.
  void pop(String text, Color color) {
    this.text = text;
    this.color = color;
    notifyListeners();
  }
}

/// Web `.feedback`: big Fredoka word at 46% height that pops (scale .5 →
/// 1.2 → 1) and floats up while fading (0.8s). Place in the game [Stack].
class FeedbackPop extends StatefulWidget {
  const FeedbackPop({super.key, required this.controller, this.fontSize = 38});

  final FeedbackController controller;
  final double fontSize;

  @override
  State<FeedbackPop> createState() => _FeedbackPopState();
}

class _FeedbackPopState extends State<FeedbackPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_go);
  }

  void _go() {
    setState(() {});
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_go);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.08), // top: 46%
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            if (t == 0 || t == 1) return const SizedBox.shrink();
            final double opacity, scale, dy;
            if (t < 0.3) {
              final k = Curves.easeOut.transform(t / 0.3);
              opacity = k;
              scale = 0.5 + 0.7 * k;
              dy = 0;
            } else {
              final k = Curves.easeIn.transform((t - 0.3) / 0.7);
              opacity = 1 - k;
              scale = 1.2 - 0.2 * k;
              dy = -30 * k;
            }
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
          child: Text(
            widget.controller.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              // Fredoka has no Japanese: 「せいかい！」 uses the bundled
              // rounded font instead of a system fallback (or □ boxes).
              fontFamilyFallback: const ['M PLUS Rounded 1c'],
              fontWeight: FontWeight.w700,
              fontSize: widget.fontSize,
              color: widget.controller.color,
              shadows: const [
                Shadow(blurRadius: 10, offset: Offset(0, 2), color: Color(0x99000000)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
