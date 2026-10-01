import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Floating decoration stars from the web top page (`#deco`, 60 spans).
///
/// Positions, colours and sizes are copied from ark-kids-top.html. The web
/// floats every star up 8px (4s / 5s alternate); on top of that each star
/// here twinkles on its own phase so the sky feels alive.
///
/// Stars are drawn as paths, not ✧★✦ glyphs, so they look identical on
/// every platform regardless of the device's symbol font.
class DecoStars extends StatefulWidget {
  const DecoStars({super.key});

  @override
  State<DecoStars> createState() => _DecoStarsState();
}

class _DecoStarsState extends State<DecoStars>
    with SingleTickerProviderStateMixin {
  // 40s loop: a common multiple of the 8s / 10s float round trips.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DecoPainter(_c),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Deco {
  const _Deco(this.x, this.y, this.color, this.size, this.glyph);

  /// CSS left / top as a fraction of the viewport.
  final double x;
  final double y;
  final Color color;

  /// CSS font-size in px.
  final double size;
  final String glyph;
}

const _stars = <_Deco>[
  _Deco(0.099, 0.069, Color(0xFFFFD54A), 22, '✧'),
  _Deco(0.246, 0.085, Color(0xFFFFD54A), 14, '✧'),
  _Deco(0.368, 0.048, Color(0xFFFFFFFF), 18, '★'),
  _Deco(0.533, 0.030, Color(0xFF9BE06A), 16, '✧'),
  _Deco(0.722, 0.083, Color(0xFF5CD0F7), 22, '✦'),
  _Deco(0.954, 0.021, Color(0xFFFFF7B0), 14, '✧'),
  _Deco(0.037, 0.188, Color(0xFF9BE06A), 22, '★'),
  _Deco(0.214, 0.189, Color(0xFFFFB066), 16, '★'),
  _Deco(0.475, 0.153, Color(0xFF9BE06A), 14, '✧'),
  _Deco(0.639, 0.165, Color(0xFFFFB066), 12, '✦'),
  _Deco(0.732, 0.123, Color(0xFFFFB066), 12, '★'),
  _Deco(0.895, 0.175, Color(0xFFFFD54A), 18, '✧'),
  _Deco(0.106, 0.237, Color(0xFFC9A3FF), 22, '✦'),
  _Deco(0.225, 0.266, Color(0xFFFFF7B0), 16, '★'),
  _Deco(0.443, 0.215, Color(0xFFC9A3FF), 22, '★'),
  _Deco(0.571, 0.254, Color(0xFFC9A3FF), 16, '✦'),
  _Deco(0.760, 0.211, Color(0xFF5CD0F7), 18, '★'),
  _Deco(0.974, 0.226, Color(0xFFFFF7B0), 16, '★'),
  _Deco(0.085, 0.381, Color(0xFFFFF7B0), 12, '✦'),
  _Deco(0.261, 0.372, Color(0xFFFFB066), 12, '✦'),
  _Deco(0.408, 0.388, Color(0xFFC9A3FF), 18, '★'),
  _Deco(0.597, 0.383, Color(0xFFFFB066), 20, '✦'),
  _Deco(0.756, 0.335, Color(0xFFFFB066), 14, '✦'),
  _Deco(0.955, 0.360, Color(0xFFFFB066), 16, '✧'),
  _Deco(0.040, 0.414, Color(0xFFFFFFFF), 12, '✧'),
  _Deco(0.217, 0.458, Color(0xFFFFF7B0), 20, '✦'),
  _Deco(0.407, 0.414, Color(0xFFFFD54A), 22, '✧'),
  _Deco(0.583, 0.477, Color(0xFF5CD0F7), 20, '★'),
  _Deco(0.800, 0.443, Color(0xFFFFFFFF), 16, '★'),
  _Deco(0.872, 0.478, Color(0xFF5CD0F7), 16, '✦'),
  _Deco(0.137, 0.560, Color(0xFFFFF7B0), 16, '★'),
  _Deco(0.274, 0.535, Color(0xFFFFB066), 16, '✦'),
  _Deco(0.404, 0.522, Color(0xFF5CD0F7), 20, '✦'),
  _Deco(0.639, 0.579, Color(0xFFFF7EB6), 16, '★'),
  _Deco(0.721, 0.573, Color(0xFFC9A3FF), 12, '✧'),
  _Deco(0.953, 0.572, Color(0xFFFFD54A), 22, '✧'),
  _Deco(0.059, 0.655, Color(0xFFFFB066), 22, '✧'),
  _Deco(0.248, 0.672, Color(0xFFFFB066), 16, '✧'),
  _Deco(0.436, 0.656, Color(0xFFFFF7B0), 18, '★'),
  _Deco(0.618, 0.636, Color(0xFFFFF7B0), 16, '✦'),
  _Deco(0.790, 0.662, Color(0xFFC9A3FF), 16, '✦'),
  _Deco(0.935, 0.669, Color(0xFFC9A3FF), 22, '✦'),
  _Deco(0.042, 0.779, Color(0xFFC9A3FF), 16, '✦'),
  _Deco(0.252, 0.752, Color(0xFF9BE06A), 22, '★'),
  _Deco(0.399, 0.778, Color(0xFFFF7EB6), 20, '✦'),
  _Deco(0.605, 0.743, Color(0xFFFFFFFF), 16, '✧'),
  _Deco(0.766, 0.772, Color(0xFFFFB066), 20, '✧'),
  _Deco(0.979, 0.726, Color(0xFFFFF7B0), 18, '✧'),
  _Deco(0.102, 0.828, Color(0xFF5CD0F7), 20, '✧'),
  _Deco(0.278, 0.889, Color(0xFF5CD0F7), 12, '★'),
  _Deco(0.466, 0.819, Color(0xFFFFF7B0), 14, '★'),
  _Deco(0.589, 0.843, Color(0xFFFFFFFF), 20, '✦'),
  _Deco(0.764, 0.857, Color(0xFFC9A3FF), 12, '★'),
  _Deco(0.898, 0.886, Color(0xFFFF7EB6), 20, '✦'),
  _Deco(0.125, 0.940, Color(0xFFFFB066), 12, '★'),
  _Deco(0.224, 0.951, Color(0xFFFFB066), 16, '✧'),
  _Deco(0.457, 0.944, Color(0xFFC9A3FF), 16, '✧'),
  _Deco(0.538, 0.958, Color(0xFFFFF7B0), 14, '✧'),
  _Deco(0.809, 0.959, Color(0xFFFFD54A), 16, '✦'),
  _Deco(0.867, 0.955, Color(0xFF5CD0F7), 16, '✧'),
];

class _DecoPainter extends CustomPainter {
  _DecoPainter(this.anim) : super(repaint: anim);

  final Animation<double> anim;

  static final _shadow = Paint()
    ..color = const Color(0x59000000) // text-shadow rgba(0,0,0,.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = anim.value * 40;
    final fill = Paint()..isAntiAlias = true;
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      // @keyframes decofloat: translateY(0 → -8px), ease-in-out, alternate;
      // odd children (1-based) run 5s, even 4s.
      final period = i.isEven ? 5.0 : 4.0;
      final phase = (seconds / period) % 2;
      final lin = phase < 1 ? phase : 2 - phase;
      final dy = -8 * Curves.easeInOut.transform(lin);

      // Extra twinkle: each star breathes on its own phase.
      // 9 cycles per 40s loop (~4.4s) so the loop wraps seamlessly.
      final tw = 0.5 + 0.5 * math.sin(seconds * math.pi * 2 * 9 / 40 + i * 2.39);
      final opacity = 0.62 + 0.38 * tw;
      final scale = 0.9 + 0.12 * tw;

      // Glyph box → visual centre (inline text box is ~1.25em tall).
      final c = Offset(
        s.x * size.width + s.size * 0.46,
        s.y * size.height + s.size * 0.66 + dy,
      );
      final r = s.size * 0.46 * scale;
      final path = s.glyph == '★' ? _star5(c, r) : _star4(c, r * 0.95, 0.30);
      canvas.drawPath(path.shift(const Offset(0, 2)), _shadow);
      fill.color = s.color.withValues(alpha: opacity);
      if (s.glyph == '✧') {
        // White (outlined) four-pointed star.
        fill
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, s.size * 0.075)
          ..strokeJoin = StrokeJoin.round;
      } else {
        fill.style = PaintingStyle.fill;
      }
      canvas.drawPath(path, fill);
    }
  }

  static Path _star5(Offset c, double r) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final rad = k.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + k * math.pi / 5;
      final pt = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  static Path _star4(Offset c, double r, double inner) {
    final p = Path();
    for (var k = 0; k < 8; k++) {
      final rad = k.isEven ? r : r * inner;
      final a = -math.pi / 2 + k * math.pi / 4;
      final pt = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _DecoPainter old) => false;
}
