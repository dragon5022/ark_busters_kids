import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';

/// Live site `readyGo()` (`#encPop`): トークモン jumps in with
/// 「トークモンが あらわれた！」 and its voice; play starts 1.7s later.
Future<void> showTalkEncounter(BuildContext context) async {
  final nav = Navigator.of(context);
  final player = AudioPlayer();
  unawaited(() async {
    try {
      await player.setVolume(0.95);
      await player.play(AssetSource('audio/voice/talk/talkpopvoice.mp3'));
    } catch (_) {
      // The web falls back to a synthesized "appear" jingle.
      await AudioService.instance.playSfx('start');
    }
  }());
  nav.push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => const _Encounter(),
    transitionsBuilder: (_, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  ));
  await Future<void>.delayed(const Duration(milliseconds: 1700));
  nav.pop();
  unawaited(Future<void>.delayed(const Duration(seconds: 3), player.dispose));
}

class _Encounter extends StatefulWidget {
  const _Encounter();

  @override
  State<_Encounter> createState() => _EncounterState();
}

class _EncounterState extends State<_Encounter> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  // Extra: a warm aura that breathes behind the monster.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final imgW = math.min(w * 0.58, 290.0);
    // @keyframes encIn (.5s cubic-bezier(.25,1.7,.5,1)):
    // y80 s.4 o0 → 60% y-12 s1.12 → y0 s1.
    const curve = Cubic(0.25, 1.7, 0.5, 1);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_c, _glow]),
              builder: (context, child) {
                final t = curve.transform(_c.value);
                final g = 0.78 + 0.08 * _glow.value;
                return Opacity(
                  opacity: (_c.value / 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 80 * (1 - t)),
                    child: Transform.scale(
                      scale: 0.4 + 0.6 * t,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: imgW * g,
                            height: imgW * g,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0x73FF8A3D), Color(0x00FF8A3D)],
                              ),
                            ),
                          ),
                          child!,
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: ArtShadow(
                color: const Color(0x99000000),
                offset: const Offset(0, 12),
                blur: 30,
                child: Image.asset(
                  'assets/images/misc/talk pop t.webp',
                  width: imgW,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/monsters/talkmon/トーク敵.webp',
                    width: imgW,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xCC10122E),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xEBFFFFFF), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        offset: Offset(0, 8),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Text(
                    'トークモンが あらわれた！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DotGothic16', // web #encMsg
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
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
      ),
    );
  }
}
