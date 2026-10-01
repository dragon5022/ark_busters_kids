import 'package:flutter/material.dart';

/// Twinkle dots like web `body::before` (final rule in ark-kids-top.html).
class WebSparkleBackground extends StatefulWidget {
  const WebSparkleBackground({super.key, required this.child});

  final Widget child;

  @override
  State<WebSparkleBackground> createState() => _WebSparkleBackgroundState();
}

class _WebSparkleBackgroundState extends State<WebSparkleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SparklePainter(t: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SparkleLayer {
  const _SparkleLayer({
    required this.nx,
    required this.ny,
    required this.color,
    required this.radius,
    required this.tile,
  });

  final double nx;
  final double ny;
  final Color color;
  final double radius;
  final Size tile;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.t});

  final double t;

  // Final body::before in ark-kids-top.html (12 tiled layers).
  static const _layers = <_SparkleLayer>[
    _SparkleLayer(nx: 0.12, ny: 0.18, color: Color(0xE6FFFFFF), radius: 1.4, tile: Size(150, 150)),
    _SparkleLayer(nx: 0.38, ny: 0.08, color: Color(0xD9FFE9A8), radius: 1.3, tile: Size(190, 190)),
    _SparkleLayer(nx: 0.62, ny: 0.22, color: Color(0xD9CDE8FF), radius: 1.2, tile: Size(130, 130)),
    _SparkleLayer(nx: 0.88, ny: 0.12, color: Color(0xCCFFFFFF), radius: 1.3, tile: Size(210, 210)),
    _SparkleLayer(nx: 0.22, ny: 0.45, color: Color(0xCCFFD1F0), radius: 1.2, tile: Size(170, 170)),
    _SparkleLayer(nx: 0.50, ny: 0.55, color: Color(0xCCFFFFFF), radius: 1.1, tile: Size(110, 110)),
    _SparkleLayer(nx: 0.78, ny: 0.48, color: Color(0xCCFFE9A8), radius: 1.3, tile: Size(160, 160)),
    _SparkleLayer(nx: 0.10, ny: 0.72, color: Color(0xCCCDE8FF), radius: 1.2, tile: Size(200, 200)),
    _SparkleLayer(nx: 0.40, ny: 0.82, color: Color(0xD9FFFFFF), radius: 1.3, tile: Size(140, 140)),
    _SparkleLayer(nx: 0.68, ny: 0.78, color: Color(0xCCFFD1F0), radius: 1.2, tile: Size(180, 180)),
    _SparkleLayer(nx: 0.92, ny: 0.88, color: Color(0xCCFFFFFF), radius: 1.2, tile: Size(120, 120)),
    _SparkleLayer(nx: 0.28, ny: 0.95, color: Color(0xBFFFE9A8), radius: 1.1, tile: Size(230, 230)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // @keyframes twinkle: opacity .5 ↔ 1
    final opacity = 0.5 + 0.5 * t;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final layer in _layers) {
      final tw = layer.tile.width;
      final th = layer.tile.height;
      final cols = (size.width / tw).ceil() + 1;
      final rows = (size.height / th).ceil() + 1;

      paint.color = layer.color.withValues(alpha: layer.color.a * opacity);

      for (var row = 0; row < rows; row++) {
        for (var col = 0; col < cols; col++) {
          final cx = col * tw + layer.nx * tw;
          final cy = row * th + layer.ny * th;
          if (cx < -4 || cy < -4 || cx > size.width + 4 || cy > size.height + 4) {
            continue;
          }
          canvas.drawCircle(Offset(cx, cy), layer.radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.t != t;
}
