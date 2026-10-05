import 'package:flutter/material.dart';

import '../../core/constants/game_modes.dart';
import '../../core/theme/app_colors.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/deco_stars.dart';
import '../../widgets/page_background.dart';
import '../listening/listening_screens.dart';
import '../sentence/sentence_screens.dart';
import '../story/story_screen.dart';
import '../talk/talk_screens.dart';
import '../vocab/vocab_screens.dart';

/// Top page (web ark-kids-top.html).
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int _cards = 0;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playHubBgm();
    ProgressService.instance.changes.addListener(_refreshCards);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStory());
  }

  @override
  void dispose() {
    ProgressService.instance.changes.removeListener(_refreshCards);
    super.dispose();
  }

  /// Web: intro opens until seen; sequel opens once when it unlocks.
  Future<void> _autoStory() async {
    final p = ProgressService.instance;
    await _refreshCards();
    if (!mounted) return;
    if (!await p.isStorySeen()) {
      if (!mounted) return;
      await StoryScreen.open(context, StoryKind.intro);
      await p.setStorySeen();
      return;
    }
    if (_cards >= ProgressService.story2Need && !await p.isStory2Seen()) {
      if (!mounted) return;
      await _openSequel();
    }
  }

  Future<void> _refreshCards() async {
    final n = await ProgressService.instance.totalCards();
    if (mounted) setState(() => _cards = n);
  }

  Future<void> _openSequel() async {
    await ProgressService.instance.setStory2Seen();
    if (!mounted) return;
    await StoryScreen.open(context, StoryKind.sequel);
  }

  Future<void> _tapSequel() async {
    if (_cards >= ProgressService.story2Need) return _openSequel();
    final left = ProgressService.story2Need - _cards;
    await showArkNotice(
      context,
      '図鑑を はんぶん（${ProgressService.story2Need}まい）あつめると、'
      'つづきの おはなしが ひらくよ！\nいまは あと $left まい！',
    );
  }

  Future<void> _openMode(GameMode mode) async {
    final Widget page = switch (mode.id) {
      GameModeId.vocab => const VocabHomeScreen(),
      GameModeId.listening => const ListeningHomeScreen(),
      GameModeId.talk => const TalkHomeScreen(),
      GameModeId.sentence => const SentenceHomeScreen(),
    };
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    // Back on the hub: games may have switched to battle music / earned cards.
    AudioService.instance.playHubBgm();
    _refreshCards();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    const topBar = 46.0;
    final navHeight = ArkBottomNav.heightFor() + pad.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg4,
      body: PageBackground(
        child: Stack(
          children: [
            const Positioned.fill(child: DecoStars()),
            // .wrap: max-width 520, side padding 16
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    pad.top + topBar + 10,
                    16,
                    navHeight + 16,
                  ),
                  children: [
                    const Reveal(
                      fromScale: 0.96,
                      child: _HeroBanner(),
                    ),
                    const SizedBox(height: 14), // hero 6 + brand 8
                    const Reveal(
                      delay: Duration(milliseconds: 120),
                      child: _BrandHeader(),
                    ),
                    const SizedBox(height: 10), // brand 4 + lead 6
                    const Reveal(
                      delay: Duration(milliseconds: 200),
                      child: _LeadBanner(),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < kGameModes.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      Reveal(
                        delay: Duration(milliseconds: 280 + 90 * i),
                        dy: 26,
                        child: _ModeCard(
                          mode: kGameModes[i],
                          shineDelay: Duration(milliseconds: 1200 + 700 * i),
                          onTap: () => _openMode(kGameModes[i]),
                        ),
                      ),
                    ],
                    const _Footer(),
                  ],
                ),
              ),
            ),
            // Soft fade so cards scrolling under the top buttons stay tidy.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: pad.top + topBar + 18,
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
              left: 12,
              right: 10,
              child: Row(
                children: [
                  _PillButton(
                    label: '📖 おはなし',
                    onTap: () => StoryScreen.open(context, StoryKind.intro),
                  ),
                  const SizedBox(width: 8),
                  // Takes nearly all free space; only shrinks on tiny phones.
                  Flexible(
                    flex: 20,
                    child: _cards >= ProgressService.story2Need
                        ? _PillButton(
                            label: '▶ つづきの おはなし',
                            gold: true,
                            onTap: _tapSequel,
                          )
                        : _PillButton(
                            label:
                                '🔒 つづき（あと${ProgressService.story2Need - _cards}まい）',
                            locked: true,
                            onTap: _tapSequel,
                          ),
                  ),
                  const Spacer(),
                  const BgmButton(),
                ],
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: ArkBottomNav()),
          ],
        ),
      ),
    );
  }
}

/// `.hero`: framed key art on a transparent background, drawn as-is.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  // kidtop.png is 600×313
  static const aspect = 600 / 313;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: Image.asset(
        'assets/images/hub/kidtop.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// `.brand` / `.brand-title` / `.kids` / `.brand-name`
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  static const _titleShadows = <Shadow>[
    Shadow(offset: Offset(2, 2), color: AppColors.purple),
    Shadow(offset: Offset(3, 3), color: AppColors.blueDeep),
    Shadow(blurRadius: 16, color: Color(0x99FFFFFF)),
  ];

  static const _kidsShadows = <Shadow>[
    Shadow(offset: Offset(2, 2), color: AppColors.yellowDeep),
    Shadow(offset: Offset(3, 3), color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Bungee',
              fontSize: 34,
              height: 1,
              letterSpacing: 0.68, // 0.02em
              color: Colors.white,
              shadows: _titleShadows,
            ),
            children: [
              TextSpan(text: 'ARK BUSTERS '),
              TextSpan(
                text: 'KIDS',
                style: TextStyle(color: AppColors.gold, shadows: _kidsShadows),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 5),
        Text(
          'アーク総合学院',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.cream,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8, // 0.12em
          ),
        ),
      ],
    );
  }
}

/// `.lead`: white card, gold border, Mochiy Pop One.
class _LeadBanner extends StatelessWidget {
  const _LeadBanner();

  @override
  Widget build(BuildContext context) {
    const star = Text(
      '★',
      style: TextStyle(color: AppColors.yellow, fontSize: 20, height: 1),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, offset: Offset(0, 5)),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          star,
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'たたかうモンスターを\nえらんでね',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Mochiy Pop One',
                fontSize: 17,
                height: 1.4,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(width: 8),
          star,
        ],
      ),
    );
  }
}

/// `.wcard`: full-width card art, radius 14, drop shadow, press to .97.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.onTap,
    required this.shineDelay,
  });

  final GameMode mode;
  final VoidCallback onTap;
  final Duration shineDelay;

  // card-*.png are 800×267
  static const aspect = 800 / 267;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ShineSweep(
            delay: shineDelay,
            period: const Duration(milliseconds: 5600),
            opacity: 0.38,
            child: AspectRatio(
              aspectRatio: aspect,
              child: Image.asset(
                mode.cardAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.footer`
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Opacity(
        opacity: 0.85,
        child: Text(
          'ARK SOGO GAKUIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Bungee',
            fontSize: 11,
            letterSpacing: 3.08, // 0.28em
            color: Colors.white,
            shadows: [Shadow(offset: Offset(1, 1), color: AppColors.purple)],
          ),
        ),
      ),
    );
  }
}

/// `#story-btn` (white) / `#story2-btn` (gold, or `.locked` translucent).
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.gold = false,
    this.locked = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool gold;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Color text;
    final BoxDecoration deco;
    if (gold) {
      text = const Color(0xFF6B3B00);
      deco = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9A8), Color(0xFFF1B53A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x4D000000), offset: Offset(0, 3)),
        ],
      );
    } else if (locked) {
      text = const Color(0xFF5B4B7A);
      deco = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x4D3C2878), offset: Offset(0, 3)),
        ],
      );
    } else {
      text = AppColors.purpleDeep;
      deco = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x663C2878), offset: Offset(0, 3)),
        ],
      );
    }
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: deco,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
