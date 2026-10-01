import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';

/// Talk Buster building blocks, styled after talk-buster_無料版.html.

const talkGold = Color(0xFFFFCF3D); // --gold
const talkNavy = Color(0xFF23204D); // --navy
const talkPurple = Color(0xFF5B21B6);

// ------------------------------------------------------------ starfront

class _S {
  const _S(this.x, this.y, this.color, this.size, this.kind);
  final double x;
  final double y;
  final Color color;
  final double size;

  /// 0 = ✦, 1 = ✧, 2 = ★
  final int kind;
}

/// `#starfront`: 63 coloured ✦ ✧ ★ glyphs over the battle background that
/// float up 7px (4s / 5.2s alternate). Drawn as paths so they look the same
/// on every platform.
class TalkStarfront extends StatefulWidget {
  const TalkStarfront({super.key});

  @override
  State<TalkStarfront> createState() => _TalkStarfrontState();
}

class _TalkStarfrontState extends State<TalkStarfront>
    with SingleTickerProviderStateMixin {
  // 104s = lcm-ish loop of the 8s / 10.4s round trips.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 104),
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
        child: CustomPaint(painter: _StarPainter(_c), size: Size.infinite),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  static final Map<int, Path> _unit = {
    0: _four(0.30),
    1: _four(0.30),
    2: _five(),
  };

  static Path _four(double inner) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? 1.0 : inner;
      final o = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  static Path _five() {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? 1.0 : 0.42;
      final o = Offset(math.cos(a) * r, math.sin(a) * r + 0.08);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final secs = anim.value * 104;
    final fill = Paint();
    // text-shadow 0 2px 4px rgba(0,0,0,.35), approximated without a blur
    // so 63 stars stay cheap to repaint every frame.
    final shadow = Paint()..color = const Color(0x40000000);
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      // nth-child(odd) → 5.2s, others 4s; ease-in-out alternate.
      final dur = i.isEven ? 5.2 : 4.0;
      final ph = (secs % (dur * 2)) / dur;
      final k = ph <= 1 ? ph : 2 - ph;
      final dy = -7 * Curves.easeInOut.transform(k);
      final r = s.size * (s.kind == 2 ? 0.46 : 0.42);
      final cx = s.x * size.width + s.size * 0.5;
      final cy = s.y * size.height + s.size * 0.62 + dy;
      final m = Matrix4.identity()
        ..translateByDouble(cx, cy, 0, 1)
        ..scaleByDouble(r, r, 1, 1);
      final path = _unit[s.kind]!.transform(m.storage);
      canvas.drawPath(path.shift(const Offset(0, 2)), shadow);
      if (s.kind == 1) {
        fill
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, s.size / 11);
      } else {
        fill
          ..color = s.color
          ..style = PaintingStyle.fill;
      }
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => false;
}

const _stars = <_S>[
  _S(0.128, 0.081, Color(0xFF9BE06A), 11, 0),
  _S(0.186, 0.093, Color(0xFFFFD54A), 12, 0),
  _S(0.348, 0.040, Color(0xFFFFFFFF), 11, 1),
  _S(0.490, 0.017, Color(0xFFFFB066), 14, 1),
  _S(0.612, 0.074, Color(0xFFFFFFFF), 12, 2),
  _S(0.730, 0.043, Color(0xFFC9A3FF), 14, 0),
  _S(0.935, 0.077, Color(0xFFFFFFFF), 14, 1),
  _S(0.090, 0.165, Color(0xFF9BE06A), 12, 0),
  _S(0.168, 0.156, Color(0xFFFFFFFF), 16, 0),
  _S(0.373, 0.153, Color(0xFF9BE06A), 14, 0),
  _S(0.549, 0.143, Color(0xFFC9A3FF), 11, 1),
  _S(0.697, 0.127, Color(0xFFFFB066), 14, 1),
  _S(0.781, 0.207, Color(0xFF9BE06A), 16, 0),
  _S(0.951, 0.160, Color(0xFFC9A3FF), 12, 0),
  _S(0.105, 0.239, Color(0xFFFFF7B0), 14, 2),
  _S(0.257, 0.314, Color(0xFF9BE06A), 16, 1),
  _S(0.313, 0.264, Color(0xFFC9A3FF), 11, 2),
  _S(0.459, 0.243, Color(0xFFFFD54A), 11, 2),
  _S(0.686, 0.320, Color(0xFF9BE06A), 20, 1),
  _S(0.803, 0.317, Color(0xFF9BE06A), 11, 0),
  _S(0.905, 0.241, Color(0xFFFFB066), 20, 2),
  _S(0.040, 0.389, Color(0xFF9BE06A), 12, 0),
  _S(0.197, 0.369, Color(0xFFFFD54A), 14, 2),
  _S(0.333, 0.403, Color(0xFFFFD54A), 11, 1),
  _S(0.451, 0.372, Color(0xFFFFD54A), 20, 1),
  _S(0.683, 0.386, Color(0xFFC9A3FF), 14, 1),
  _S(0.828, 0.353, Color(0xFF9BE06A), 12, 0),
  _S(0.930, 0.395, Color(0xFFFFD54A), 16, 1),
  _S(0.019, 0.507, Color(0xFFFFD54A), 16, 1),
  _S(0.159, 0.523, Color(0xFFFF7EB6), 14, 0),
  _S(0.301, 0.459, Color(0xFF5CD0F7), 18, 1),
  _S(0.506, 0.490, Color(0xFF9BE06A), 16, 1),
  _S(0.655, 0.522, Color(0xFFFFD54A), 12, 1),
  _S(0.731, 0.476, Color(0xFFFF7EB6), 20, 0),
  _S(0.935, 0.537, Color(0xFFFFF7B0), 14, 1),
  _S(0.064, 0.568, Color(0xFFFFD54A), 11, 2),
  _S(0.164, 0.588, Color(0xFFFFFFFF), 12, 1),
  _S(0.343, 0.572, Color(0xFFFF7EB6), 14, 2),
  _S(0.533, 0.577, Color(0xFF5CD0F7), 11, 1),
  _S(0.662, 0.622, Color(0xFFFFD54A), 20, 2),
  _S(0.765, 0.583, Color(0xFFFFD54A), 12, 1),
  _S(0.931, 0.651, Color(0xFFFFF7B0), 14, 0),
  _S(0.125, 0.756, Color(0xFFFF7EB6), 14, 1),
  _S(0.276, 0.707, Color(0xFF5CD0F7), 14, 0),
  _S(0.395, 0.730, Color(0xFF5CD0F7), 14, 0),
  _S(0.494, 0.708, Color(0xFF5CD0F7), 18, 2),
  _S(0.591, 0.721, Color(0xFFFF7EB6), 20, 2),
  _S(0.823, 0.747, Color(0xFFFF7EB6), 16, 0),
  _S(0.959, 0.751, Color(0xFFFF7EB6), 18, 1),
  _S(0.021, 0.807, Color(0xFFFFD54A), 11, 0),
  _S(0.248, 0.875, Color(0xFF5CD0F7), 11, 0),
  _S(0.414, 0.852, Color(0xFFFFF7B0), 18, 2),
  _S(0.516, 0.833, Color(0xFFC9A3FF), 18, 1),
  _S(0.669, 0.836, Color(0xFFFFB066), 20, 0),
  _S(0.814, 0.852, Color(0xFFFFF7B0), 20, 2),
  _S(0.924, 0.806, Color(0xFFFFFFFF), 11, 1),
  _S(0.018, 0.963, Color(0xFF5CD0F7), 18, 1),
  _S(0.247, 0.901, Color(0xFFFFF7B0), 20, 1),
  _S(0.323, 0.912, Color(0xFFFFD54A), 16, 1),
  _S(0.558, 0.915, Color(0xFFFFFFFF), 12, 2),
  _S(0.632, 0.974, Color(0xFF9BE06A), 16, 1),
  _S(0.730, 0.963, Color(0xFFFF7EB6), 12, 1),
  _S(0.908, 0.940, Color(0xFF9BE06A), 12, 2),
];

// -------------------------------------------------------------- buttons

enum TalkBtnKind { listen, mic, ok }

/// Web `.bigbtn` (Mochiy Pop One 18px, white, gradient, hard shadow).
class TalkBigButton extends StatelessWidget {
  const TalkBigButton({
    super.key,
    required this.kind,
    required this.label,
    required this.onTap,
    this.glow,
  });

  final TalkBtnKind kind;
  final String label;
  final VoidCallback? onTap;

  /// Optional extra outer glow (used by the live mic pulse).
  final List<BoxShadow>? glow;

  static const _grad = {
    TalkBtnKind.listen: [Color(0xFF5CD0F7), Color(0xFF0A6EA3)],
    TalkBtnKind.mic: [Color(0xFFFF9F5A), Color(0xFFD35A0E)],
    TalkBtnKind.ok: [Color(0xFF7FE3A0), Color(0xFF2A9D5A)],
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.97,
        pressedOffset: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _grad[kind]!,
            ),
            boxShadow: [
              const BoxShadow(color: Color(0x4D000000), offset: Offset(0, 5)),
              ...?glow,
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Mochiy Pop One',
              fontSize: 18,
              height: 1.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Web end-screen `.btn`: orange gradient pill (or the white variant).
class TalkBtn extends StatelessWidget {
  const TalkBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.white = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool white;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Pressable(
        onTap: onTap,
        pressedScale: 1,
        pressedOffset: 3,
        child: ShineSweep(
          opacity: white ? 0.0 : 0.35,
          period: const Duration(milliseconds: 5200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: white ? Colors.white : null,
              gradient: white
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFC94D), Color(0xFFC77800)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: white
                      ? const Color(0xFFC9C9C9)
                      : const Color(0xFF8A5400),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                height: 1.25,
                color: white ? talkNavy : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Talk's `.quitbtn`: dark translucent pill with a gold border.
class TalkQuitButton extends StatelessWidget {
  const TalkQuitButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x59000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: talkGold, width: 2),
        ),
        child: const Text(
          'やめる',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.3,
            height: 1.25,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Talk's `#bgmBtn`: 40×40 rounded square at left:118px (🔊 / 🔇).
class TalkBgmButton extends StatefulWidget {
  const TalkBgmButton({super.key});

  @override
  State<TalkBgmButton> createState() => _TalkBgmButtonState();
}

class _TalkBgmButtonState extends State<TalkBgmButton> {
  @override
  Widget build(BuildContext context) {
    final on = AudioService.instance.isBgmOn;
    return Pressable(
      onTap: () async {
        await AudioService.instance.toggleBgm();
        if (mounted) setState(() {});
      },
      pressedScale: 0.92,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xD9FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: talkGold, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x4D3C2878), offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          on ? '🔊' : '🔇',
          style: const TextStyle(fontSize: 18, height: 1),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- texts

/// `-webkit-text-stroke` text: fill, then a centred stroke on top.
class StrokeText extends StatelessWidget {
  const StrokeText(
    this.text, {
    super.key,
    required this.style,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(text, textAlign: TextAlign.center, style: style),
        Text(
          text,
          textAlign: TextAlign.center,
          style: style.copyWith(
            color: null,
            shadows: const [],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
          ),
        ),
      ],
    );
  }
}

/// Web `.feedback`: Mochiy Pop One 30px at top 40%, `@keyframes fb` (1s):
/// rises 10px → 0 while growing .8 → 1.1, then drifts up and fades.
/// Driven by the kit's [FeedbackController].
class TalkFeedback extends StatefulWidget {
  const TalkFeedback({super.key, required this.controller});

  final FeedbackController controller;

  @override
  State<TalkFeedback> createState() => _TalkFeedbackState();
}

class _TalkFeedbackState extends State<TalkFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
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
    final h = MediaQuery.sizeOf(context).height;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: h * 0.40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = _c.value;
                if (t == 0 || t == 1) return const SizedBox.shrink();
                // `ease` timing across each keyframe segment.
                const ease = Cubic(0.25, 0.1, 0.25, 1);
                double o, dy, s;
                if (t < 0.3) {
                  final k = ease.transform(t / 0.3);
                  o = k;
                  dy = 10 * (1 - k);
                  s = 0.8 + 0.3 * k;
                } else {
                  final k = ease.transform((t - 0.3) / 0.7);
                  o = 1 - k;
                  dy = -10 * k;
                  s = 1.1 - 0.1 * k;
                }
                return Opacity(
                  opacity: o.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: s,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: Text(
                widget.controller.text,
                textAlign: TextAlign.center,
                softWrap: false, // live: white-space:nowrap
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'Mochiy Pop One',
                  fontSize: 30,
                  height: 1.25,
                  color: widget.controller.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
