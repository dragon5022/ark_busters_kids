import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/effects.dart';
import '../../widgets/page_background.dart';
import '../../widgets/pressable.dart';

/// Vertical-scroll picture story (web `#storyOverlay` / `#storyOverlay2`).
enum StoryKind { intro, sequel }

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.kind});

  final StoryKind kind;

  /// Fades in over the hub like the web overlay; pops when closed.
  static Future<void> open(BuildContext context, StoryKind kind) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => StoryScreen(kind: kind),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panels = kind == StoryKind.intro ? _intro : _sequel;
    final close = kind == StoryKind.intro ? 'スキップ ▶' : 'とじる ✕';
    return Scaffold(
      backgroundColor: const Color(0xFF120C33),
      body: PageBackground(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top,
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                for (final p in panels)
                  _Panel(panel: p, onDone: () => Navigator.of(context).pop()),
              ],
            ),
            // .story-skip: fixed top:12px right:12px
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 12,
              child: _SkipButton(
                label: close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPanel {
  const _StoryPanel({
    required this.num,
    this.image,
    required this.text,
    this.hint = false,
    this.tail,
    this.button,
  });

  final String num;
  final String? image;

  /// `\n` = `<br>`, `{…}` = `<span class="hi">…</span>`.
  final String text;
  final bool hint;

  /// Small lilac line under the text (web inline `font-size:16px` span).
  final String? tail;
  final String? button;
}

const _img = 'assets/images/story';

// Text copied from ark-kids-top.html.
const _intro = <_StoryPanel>[
  _StoryPanel(
    num: '1 / 5',
    image: '$_img/s1.webp',
    hint: true,
    text: '{奏（かなで）}と {詩（うた）}は、\nなかよし きょうだい。\n\n'
        'いつもは げんき いっぱいなのに、\nテストの 日は いつもしょんぼり。\n\n'
        '「やれば できるよ！」\n\n'
        'お父さんも お母さんも\nはげまして くれるけれど、\n\n'
        '奏は {リスニング}が\n詩は {ぶんぽう}が、だいの にがて。\n\n'
        '「どうせ ぼくたち、できないもん……」\n\n'
        'おちこむ ふたりを 見て、\nお父さんと お母さんも かおを くもらせた。',
  ),
  _StoryPanel(
    num: '2 / 5',
    image: '$_img/s2.webp',
    text: '親子は、まちで ちょっぴり話題の じゅく\n{「ARK（アーク）」}の とびらを ひらいた。\n\n'
        'むかえて くれたのは、\nにっこり わらう {かずえ先生}。\n\n'
        '「だいじょうぶ。\nここなら きっと かわれるよ」',
  ),
  _StoryPanel(
    num: '3 / 5',
    image: '$_img/s3.webp',
    text: 'ふしぎと、 かずえ先生の ことばに\nむねが あつく なる。\n\n'
        '――そのとき。\n\n'
        'つくえの 上の\n{英語の本}が、ピカッと ひかる。\n\n'
        'ドドドドッ！！\n\n'
        '本の 中から、4体の\n{おそろしい モンスター}が とびだしてきた！\n\n'
        '「うわあああ！？」\n\n'
        'おもわず さけぶ 奏と 詩。\nけれど……あら ふしぎ。\nおとなには 見えないみたい。',
  ),
  _StoryPanel(
    num: '4 / 5',
    image: '$_img/s4.webp',
    text: 'かずえ先生は、お父さんと お母さんに\n{バスターズブック} を わたした。\n\n'
        'とたんに、モンスターの すがたが\n見えたのか、おどろく ふたり。\n\n'
        '「あ、あれは なんなの？」\n\n'
        '奏が たずねると、\nかずえ先生は かおを くもらせた。\n\n'
        '「あの子たちは、\nもとは {心の きれいな ようせい} だったの。\n'
        'でも、みんなの『英語、きらい』って きもちを\n'
        'すいこみすぎて、 たましいが けがれて\nぼうそうして しまったの」\n\n'
        'かずえ先生は、 {バスターズペン} を\n子どもたちに さしだして言う。\n\n'
        '「おねがい。 どうか みんなで、\n{あの子たちを 助けて あげて？}」',
  ),
  _StoryPanel(
    num: '5 / 5',
    image: '$_img/s5.webp',
    button: 'ぼうけんスタート！',
    text: '顔を 見あわせる 奏と 詩。\nまだ ゆうきは 出ない。\n'
        'だって 英語は にがてで、\nやっても どうせ できないと 思って いるから。\n'
        'でも――\n「{かぞく みんなが、いっしょなら。}」\n'
        'お父さんと お母さんが、こくりと うなずく。\n'
        '「「「「{へんしーーん！！}」」」」 ピカーッ！！\n'
        '親子そろって、{バスターズの せいふく}に へんしん！\n'
        '「いくぞ、詩！」「うん、おにいちゃん！」\n'
        'やるき まんまん。家族みんなで、モンスターに むかって いく！\n\n'
        'さあ、キミも いっしょに {冒険を はじめよう！}',
  ),
];

const _sequel = <_StoryPanel>[
  _StoryPanel(
    num: 'つづきの おはなし ・ なかまの ひみつ',
    image: '$_img/s6.webp',
    hint: true,
    text: 'じつは モンスターたちは、\nほんとうの {ボス}に あやつられて いただけ だった。\n'
        'たたかって、{のろいを といて} あげると――\n'
        'モンスターは にっこり。\nみんな、たいせつな {なかま}に なった！',
  ),
  _StoryPanel(
    num: '中学生編',
    image: '$_img/s7.webp',
    text: '月日は ながれ、奏と 詩は {中学生}に なった。\n'
        'すると、なかまたちが きゅうに さけんだ――\n'
        '「気を つけて！ ぼくたちを あやつって いた、\n'
        '{ほんとうの ボス}が……\nまた、おそってくる!!」',
  ),
  _StoryPanel(
    num: '2',
    image: '$_img/teen-bosses.webp',
    text: 'あらわれたのは、{5教科の 大きな ボス}たち。\n'
        'せかいじゅうを 「べんきょう、できない…」で\nうめつくそうと たくらんでいる。\n'
        'その ねらいは――なんと、この {地球（ちきゅう）}！',
  ),
  _StoryPanel(
    num: '3',
    tail: '（つづく）',
    button: 'とじる',
    text: '大きく なった {親子バスターズ}の、\nあたらしい たたかいが、いま はじまる。\n'
        'その なも――{ARK BUSTERS TEEN（アーク バスターズ ティーン）}！',
  ),
];

/// `.spanel`: min-height 80vh, centred, padding 46px 20px.
class _Panel extends StatelessWidget {
  const _Panel({required this.panel, required this.onDone});

  final _StoryPanel panel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: h * 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 46),
        child: ScrollReveal(
          child: LayoutBuilder(
            builder: (context, c) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // .pnum
                Text(
                  panel.num,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD96B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                if (panel.image != null) ...[
                  // img.schar: width 66%, max 300px, purple drop-shadow
                  const SizedBox(height: 4),
                  SizedBox(
                    width: math.min(c.maxWidth * 0.66, 300),
                    child: ArtShadow(
                      color: const Color(0x8C7828C8),
                      offset: const Offset(0, 8),
                      blur: 20,
                      child: Image.asset(
                        panel.image!,
                        fit: BoxFit.fitWidth,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _StoryText(text: panel.text),
                if (panel.tail != null)
                  Text(
                    panel.tail!,
                    style: const TextStyle(
                      fontFamily: 'Mochiy Pop One',
                      fontSize: 16,
                      height: 1.85,
                      color: Color(0xFFCDB6FF),
                    ),
                  ),
                if (panel.hint) const _ScrollHint(),
                if (panel.button != null) ...[
                  const SizedBox(height: 14),
                  _StartButton(label: panel.button!, onTap: onDone),
                  const SizedBox(height: 44), // margin: 14px auto 44px
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `.stext`: Mochiy Pop One 21px / 1.85, white with shadow, `.hi` in gold.
/// Scales down only when the widest line would not fit the phone width.
class _StoryText extends StatelessWidget {
  const _StoryText({required this.text});

  final String text;

  static const _base = 21.0;
  static const _min = 15.0;

  static List<TextSpan> _spans(String text) {
    final out = <TextSpan>[];
    final re = RegExp(r'\{([^}]*)\}');
    var i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) out.add(TextSpan(text: text.substring(i, m.start)));
      out.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(color: Color(0xFFFFD96B)),
      ));
      i = m.end;
    }
    if (i < text.length) out.add(TextSpan(text: text.substring(i)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = math.min(430.0, c.maxWidth);
        final plain = text.replaceAll(RegExp(r'[{}]'), '');
        var widest = 0.0;
        for (final line in plain.split('\n')) {
          final tp = TextPainter(
            text: TextSpan(text: line, style: _style(_base)),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          widest = math.max(widest, tp.width);
        }
        final size = widest > maxW
            ? math.max(_min, (_base * maxW / widest).floorToDouble())
            : _base;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Text.rich(
            TextSpan(style: _style(size), children: _spans(text)),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  static TextStyle _style(double size) => TextStyle(
        fontFamily: 'Mochiy Pop One',
        fontSize: size,
        height: 1.85,
        color: Colors.white,
        shadows: const [
          Shadow(offset: Offset(0, 2), blurRadius: 7, color: Color(0x8C000000)),
        ],
      );
}

/// `.scroll-hint`: bobs 7px every 1.6s.
class _ScrollHint extends StatefulWidget {
  const _ScrollHint();

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 7 * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
        child: const Text(
          '▼ したに スクロールしてね',
          style: TextStyle(color: Color(0xFFCDB6FF), fontSize: 13),
        ),
      ),
    );
  }
}

/// `.story-start`: gold gradient pill with white border and hard shadow.
class _StartButton extends StatefulWidget {
  const _StartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  // Gentle breathing glow to invite the tap.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      pressedScale: 1,
      pressedOffset: 3,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final g = Curves.easeInOut.transform(_glow.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                const BoxShadow(color: Color(0x4D000000), offset: Offset(0, 6)),
                BoxShadow(
                  color: const Color(0xFFFFD96B).withValues(alpha: 0.25 + 0.3 * g),
                  blurRadius: 14 + 12 * g,
                ),
              ],
            ),
            child: child,
          );
        },
        child: ShineSweep(
          period: const Duration(milliseconds: 3200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE9A8), Color(0xFFF1B53A)],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Mochiy Pop One',
                fontSize: 22,
                color: Color(0xFF6B3B00),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.story-skip`
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCF3D), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x663C2878), offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5B21B6),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
