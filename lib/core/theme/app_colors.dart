import 'package:flutter/material.dart';

/// Colors aligned with ark-kids-top.html
class AppColors {
  static const skyTop = Color(0xFF9FE0FF);
  static const skyBottom = Color(0xFFD9C7FF);
  static const cream = Color(0xFFFFFDF5);
  static const ink = Color(0xFF2B2350);

  static const purple = Color(0xFF8B5CF6);
  static const purpleDeep = Color(0xFF5B21B6);
  static const yellow = Color(0xFFFFB300);
  static const yellowDeep = Color(0xFFC77800);
  static const blue = Color(0xFF23B5E8);
  static const blueDeep = Color(0xFF0A6EA3);
  static const orange = Color(0xFFFF8A3D);
  static const orangeDeep = Color(0xFFD35A0E);
  static const pink = Color(0xFFFF7EB6);
  static const gold = Color(0xFFFFCF3D);

  // Web body radial-gradient stops
  static const bg0 = Color(0xFF6A47C0);
  static const bg1 = Color(0xFF4A2AA0);
  static const bg2 = Color(0xFF2E1C72);
  static const bg3 = Color(0xFF1A1147);
  static const bg4 = Color(0xFF120C33);

  static const bgTop = bg0;
  static const bgMid = bg2;
  static const bgBottom = bg4;

  static const shadow = Color(0x403C2878);

  /// Matches: radial-gradient(ellipse 130% 90% at 50% -8%, ...)
  static const RadialGradient background = RadialGradient(
    center: Alignment(0.0, -1.16), // 50% -8%
    radius: 1.3, // × shortest side (width in portrait) = 130% width
    colors: [bg0, bg1, bg2, bg3, bg4],
    stops: [0.0, 0.26, 0.54, 0.80, 1.0],
    transform: _CssEllipse(),
  );

  /// Soft pastel behind hero (web .hero fallback)
  static const LinearGradient heroBackdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE9A8), Color(0xFFFFC4E3), Color(0xFFBDB6FF)],
    stops: [0.0, 0.55, 1.0],
  );
}

/// Squashes Flutter's circular [RadialGradient] into the CSS ellipse
/// `130% 90%`: horizontal radius 1.3×width, vertical radius 0.9×height.
class _CssEllipse extends GradientTransform {
  const _CssEllipse();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final cx = bounds.left + bounds.width * 0.5;
    final cy = bounds.top - bounds.height * 0.08;
    final rx = 1.3 * bounds.shortestSide;
    final sy = (0.9 * bounds.height) / rx;
    return Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(1, sy, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}
