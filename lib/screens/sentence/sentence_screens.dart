import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/content/game_packs.dart';
import '../../game_kit/game_kit.dart';
import '../../services/audio_service.dart';
import '../../services/content_repository.dart';
import '../../widgets/page_background.dart';
import 'sentence_battle.dart';
import 'sentence_records.dart';
import 'sentence_widgets.dart';

/// Sentence Buster (Grammar Busters, グラモン) — web `#startScreen`:
/// key visual → 英検の級をえらぶ → 5級/4級/3級 shields (endless best inside)
/// → あそびかたをえらぶ → 10問コース / エンドレスコース.
class SentenceHomeScreen extends StatefulWidget {
  const SentenceHomeScreen({super.key});

  @override
  State<SentenceHomeScreen> createState() => _SentenceHomeScreenState();
}

class _SentenceHomeScreenState extends State<SentenceHomeScreen> {
  SentencePack? _pack;
  String _grade = 'g5';
  Map<String, int> _bests = const {};
  bool _busy = false; // web __rgLock

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBattleBgm();
    _load();
    _loadBests();
  }

  Future<void> _load() async {
    try {
      final repo = ContentRepository.instance;
      final pack = repo.sentence ?? await repo.loadSentence();
      if (mounted) setState(() => _pack = pack);
    } catch (e) {
      debugPrint('sentence pack failed: $e');
    }
  }

  Future<void> _loadBests() async {
    final b = await SentenceRecords.endlessBests();
    if (mounted) setState(() => _bests = b);
  }

  void _selectGrade(String g) {
    AudioService.instance.playSfx('start');
    setState(() => _grade = g);
  }

  Future<void> _begin(SenCourse course) async {
    final pack = _pack;
    if (pack == null || _busy) return;
    _busy = true;
    await AnswerFx.battleFlash(context);
    if (!mounted) return;
    await showGramEncounter(context);
    if (!mounted) return;
    // Web: BGM ducks to .17 while #startScreen is hidden, .35 when shown.
    AudioService.instance.setBgmVolume(0.17);
    final goHome = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => ShakeScope(
          child: SentenceBattleScreen(pack: pack, grade: _grade, course: course),
        ),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
    _busy = false;
    AudioService.instance.setBgmVolume(AudioService.battleBgmVolume);
    if (!mounted) return;
    if (goHome == true) {
      Navigator.of(context).pop();
      return;
    }
    _loadBests(); // web showBests() in backToSelect()
  }

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
                    Reveal(
                      delay: next(),
                      fromScale: 0.95,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: size.height * 0.25 < 180
                                ? 180
                                : size.height * 0.25,
                          ),
                          child: ArtShadow(
                            color: const Color(0x66000000),
                            offset: const Offset(0, 6),
                            blur: 14,
                            child: Image.asset(
                              SenAssets.keyVisual,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Reveal(
                      delay: next(),
                      child: const SenBanner(SenAssets.bannerKyuu),
                    ),
                    const SizedBox(height: 6),
                    Reveal(
                      delay: next(),
                      child: ShieldTabs(
                        selected: _grade,
                        bests: _bests,
                        onSelect: _selectGrade,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Reveal(
                      delay: next(),
                      child: const SenBanner(SenAssets.bannerAsobi),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: next(),
                      dy: 24,
                      child: ModeCardButton(
                        asset: SenAssets.tabTen,
                        onTap: () => _begin(SenCourse.ten),
                        lockPack: 'sentence',
                        lockGroup: _grade,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: next(),
                      dy: 24,
                      child: ModeCardButton(
                        asset: SenAssets.tabEndless,
                        shineDelay: const Duration(milliseconds: 900),
                        onTap: () => _begin(SenCourse.endless),
                        lockPack: 'sentence',
                        lockIndex: 1,
                        lockGroup: _grade,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      colors: [Color(0xE65A3AB3), Color(0x005A3AB3)],
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
                  ArkHomeButton(onTap: () => Navigator.of(context).maybePop()),
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
