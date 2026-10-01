import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/deco_stars.dart';
import '../widgets/effects.dart';
import '../widgets/page_background.dart';
import '../widgets/pressable.dart';
import 'ark_nav.dart';
import 'ark_ui.dart';

/// The start screen shared by all four games (web `#startScreen`):
/// key visual → 「英検の級をえらぶ」 → 5級/4級/3級 tabs →
/// 「あそびかたをえらぶ」 → image mode cards → compact bottom bar.
class GameStartLayout extends StatelessWidget {
  const GameStartLayout({
    super.key,
    required this.keyVisual,
    required this.onHome,
    required this.modes,
    this.grades = const ['5級', '4級', '3級'],
    this.selectedGrade,
    this.onGrade,
    this.below = const [],
  });

  /// e.g. `assets/images/hub/voca-top.webp`
  final String keyVisual;
  final VoidCallback onHome;

  /// Usually [ModeCardButton]s.
  final List<Widget> modes;
  final List<String> grades;

  /// Index into [grades]; the grade section is hidden when [onGrade] is null.
  final int? selectedGrade;
  final ValueChanged<int>? onGrade;

  /// Extra widgets under the mode cards (best scores, notes…).
  final List<Widget> below;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    const topBar = 46.0;
    var i = 0;
    Duration next() => Duration(milliseconds: 60 + 70 * i++);

    return Scaffold(
      backgroundColor: const Color(0xFF120C33),
      body: PageBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: DecoStars()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    pad.top + topBar + 4,
                    14,
                    ArkBottomNav.heightFor(compact: true) + pad.bottom + 16,
                  ),
                  children: [
                    // .keyvisual: max 96% wide, max 25vh tall, drop shadow
                    Reveal(
                      delay: next(),
                      fromScale: 0.95,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: math.max(180, size.height * 0.25),
                          ),
                          child: ArtShadow(
                            color: const Color(0x66000000),
                            offset: const Offset(0, 6),
                            blur: 14,
                            child: Image.asset(keyVisual, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                    if (onGrade != null) ...[
                      const SizedBox(height: 6),
                      Reveal(
                        delay: next(),
                        child: const _Banner('assets/images/hub/banner-kyuu.webp'),
                      ),
                      const SizedBox(height: 6),
                      Reveal(
                        delay: next(),
                        child: GradeTabs(
                          grades: grades,
                          selected: selectedGrade ?? 0,
                          onSelect: onGrade!,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Reveal(
                      delay: next(),
                      child: const _Banner('assets/images/hub/banner-asobi.webp'),
                    ),
                    const SizedBox(height: 12),
                    for (var m = 0; m < modes.length; m++) ...[
                      if (m > 0) const SizedBox(height: 12),
                      Reveal(delay: next(), dy: 24, child: modes[m]),
                    ],
                    ...below,
                  ],
                ),
              ),
            ),
            // Fade behind the fixed top buttons.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + topBar + 14,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xF55A3AB3), Color(0xD95A3AB3), Color(0x005A3AB3)],
                      stops: [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: pad.top + 8,
              left: 8,
              right: 10,
              child: Row(
                children: [
                  ArkHomeButton(onTap: onHome),
                  const Spacer(),
                  const BgmButton(size: 40),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ArkBottomNav(compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section ribbon image (banner-kyuu / banner-asobi, 2172×445).
class _Banner extends StatelessWidget {
  const _Banner(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.96,
        child: Image.asset(asset, fit: BoxFit.fitWidth),
      ),
    );
  }
}

/// Web `#startScreen .tab`: glossy 5級 (blue) / 4級 (orange) / 3級 (red).
class GradeTabs extends StatelessWidget {
  const GradeTabs({
    super.key,
    required this.grades,
    required this.selected,
    required this.onSelect,
  });

  final List<String> grades;
  final int selected;
  final ValueChanged<int> onSelect;

  static const _gradients = [
    [Color(0xFFBFE0FF), Color(0xFF2E6FE0), Color(0xFF1450B0)],
    [Color(0xFFFFE6A8), Color(0xFFF3A52A), Color(0xFFD98014)],
    [Color(0xFFFFC2CF), Color(0xFFEC3F5E), Color(0xFFC01F3E)],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          // .tab{flex:1 1 0; max-width:118px}, 10px gaps
          const gap = 10.0;
          final share = (c.maxWidth - gap * (grades.length - 1)) / grades.length;
          final w = math.min(118.0, share);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < grades.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: w,
                  child: _GradeTab(
                    label: grades[i],
                    colors: _gradients[i % _gradients.length],
                    active: i == selected,
                    onTap: () => onSelect(i),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GradeTab extends StatelessWidget {
  const _GradeTab({
    required this.label,
    required this.colors,
    required this.active,
    required this.onTap,
  });

  final String label;
  final List<Color> colors;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        height: 64,
        // .tab.active{transform:translateY(-3px) scale(1.06)}
        transform: Matrix4.identity()
          ..translateByDouble(0, active ? -3 : 0, 0, 1)
          ..scaleByDouble(active ? 1.06 : 1, active ? 1.06 : 1, 1, 1),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          gradient: LinearGradient(
            // linear-gradient(165deg, a, b 55%, c)
            begin: const Alignment(-0.26, -1),
            end: const Alignment(0.26, 1),
            colors: colors,
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x38000000),
              offset: Offset(0, active ? 8 : 5),
            ),
            if (active)
              const BoxShadow(color: Color(0xA6FFFFFF), blurRadius: 16),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ::before gloss: top 40%, inset 8px sides
              Positioned(
                top: 3,
                left: 8,
                right: 8,
                height: 64 * 0.4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.78),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // ::after ✦
              const Positioned(
                top: 3,
                right: 9,
                child: Text(
                  '✦',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Mochiy Pop One',
                  fontSize: 30,
                  height: 1,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 2,
                      color: Color(0x4D000000),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web `.levelcard` / `.lvcard` / `.coursebtn` / `.modecard`: a full-width
/// image button (tab-*.png, 2290×687), press to .97, with a light sweep.
class ModeCardButton extends StatelessWidget {
  const ModeCardButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.shineDelay = Duration.zero,
  });

  final String asset;
  final VoidCallback? onTap;
  final Duration shineDelay;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: ShineSweep(
        delay: shineDelay + const Duration(milliseconds: 1400),
        period: const Duration(milliseconds: 6000),
        opacity: 0.35,
        child: Image.asset(asset, fit: BoxFit.fitWidth, width: double.infinity),
      ),
    );
  }
}
