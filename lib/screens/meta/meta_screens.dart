import 'dart:math' as math;

import 'package:ark_core/auth.dart';
import 'package:ark_core/purchase.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/content_repository.dart';
import '../../services/kids_store.dart';
import '../../services/progress_service.dart';
import '../../widgets/pressable.dart';

/// Web `#arkPanel` / `.ark-sheet`: the white, gold-bordered sheet that the
/// bottom bar (コレクション・プロフィール・せってい) opens over the hub.
enum ArkPanelKind { collection, profile, settings }

class ArkPanel extends StatefulWidget {
  const ArkPanel._(this.kind);

  final ArkPanelKind kind;

  static Future<void> show(BuildContext context, ArkPanelKind kind) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: const Color(0x99140C2D), // rgba(20,12,45,.6)
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => ArkPanel._(kind),
      transitionBuilder: (_, anim, _, child) {
        final t = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(t),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ArkPanel> createState() => _ArkPanelState();
}

class _Mon {
  const _Mon(this.key, this.name, this.image, this.poseBase);

  final String key;
  final String name;
  final String image;
  final String poseBase;
}

// Web MONS (ark-kids-top.html). Gramon uses its transparent cut-out
// (グラ友) instead of the web's boxed `gramon fri.png`, matching the others.
const _mons = <_Mon>[
  _Mon('vocamon', 'ボキャモン', 'assets/images/monsters/vocamon/vocamon-friend.webp',
      'assets/images/monsters/vocamon/vocamon-pose'),
  _Mon('lismon', 'リスモン', 'assets/images/monsters/lismon/lismon-friend.webp',
      'assets/images/monsters/lismon/lismon-pose'),
  _Mon('gramon', 'グラモン', 'assets/images/monsters/gramon/グラ友.webp',
      'assets/images/monsters/gramon/gramon-pose'),
  _Mon('talkmon', 'トークモン', 'assets/images/monsters/talkmon/トーク友.webp',
      'assets/images/monsters/talkmon/talkmon-pose'),
];

/// Free version shows at most 5 unlocked poses per monster.
const _freePoseLimit = 5;

const _purpleDeep = Color(0xFF5B21B6);
const _hint = Color(0xFF7A7390);

class _ArkPanelState extends State<ArkPanel> {
  late final ArkPanelKind _kind = widget.kind;
  _Mon? _monster; // collection → monster detail

  // Loaded progress
  List<String> _friends = [];
  String _name = '';
  int _totalCards = 0;
  bool _se = true;
  bool _voice = true;
  int _sRank = 0;
  bool _syncing = false;
  String _syncMsg = '';

  final _progress = ProgressService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final friends = await _progress.friends();
    final name = await _progress.getPlayerName();
    final total = await _progress.totalCards();
    final se = await _progress.isSeOn();
    final voice = await _progress.isVoiceOn();
    final s = _monster == null ? 0 : await _progress.sRankCount(_monster!.key);
    if (!mounted) return;
    setState(() {
      _friends = friends;
      _name = name;
      _totalCards = total;
      _se = se;
      _voice = voice;
      _sRank = s;
    });
  }

  void _openMonster(_Mon m) {
    setState(() => _monster = m);
    _load();
  }

  Future<void> _rename() async {
    final n = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: _name),
    );
    if (n == null || n.trim().isEmpty) return;
    await _progress.setPlayerName(n);
    _load();
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _syncMsg = 'こうしんちゅう…';
    });
    final report = await ContentRepository.instance.checkForUpdates(force: true);
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncMsg = report.messageJa;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: size.height * 0.82,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.gold, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      offset: Offset(0, 12),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey('$_kind/${_monster?.key}'),
                              child: _body(),
                            ),
                          ),
                        ),
                      ),
                      // .ark-x: top 10 / right 12 of the sheet (inside 4px border)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Pressable(
                          onTap: () => Navigator.of(context).pop(),
                          pressedScale: 0.9,
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEEEEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '✕',
                              style: TextStyle(color: _purpleDeep, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_monster != null) return _monsterBody(_monster!);
    return switch (_kind) {
      ArkPanelKind.collection => _collectionBody(),
      ArkPanelKind.profile => _profileBody(),
      ArkPanelKind.settings => _settingsBody(),
    };
  }

  Widget _collectionBody() {
    return Column(
      children: [
        const _Title('ずかん  Collection'),
        _Grid(
          children: [
            for (final m in _mons)
              _friends.contains(m.key)
                  ? _MonCard(
                      image: m.image,
                      label: m.name,
                      onTap: () => _openMonster(m),
                    )
                  : _MonCard(image: null, silhouette: m.image, label: '？？？'),
          ],
        ),
        const _Hint('モンスターを たおすと なかまに なって ここに あつまるよ！'),
      ],
    );
  }

  Widget _monsterBody(_Mon m) {
    final unlocked = _sRank ~/ 10;
    final next = 10 - _sRank % 10;
    final shown = math.min(unlocked, _freePoseLimit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _ArkButton(
            label: '← ずかんへ',
            compact: true,
            onTap: () => setState(() => _monster = null),
          ),
        ),
        const SizedBox(height: 10),
        _Title(m.name),
        _Row('S ランク', '$_sRank かい'),
        _Row('つぎのポーズまで', 'あと $next かい S'),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
          child: Text(
            'かいほうされた ポーズ：$shown こ（むりょうばんは $_freePoseLimitまいまで）',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _hint, fontSize: 12, height: 1.7),
          ),
        ),
        _Grid(
          children: [
            _MonCard(image: m.image, label: 'きほん'),
            for (var n = 1; n <= shown; n++)
              _MonCard(image: '${m.poseBase}$n.webp', label: 'ポーズ$n'),
          ],
        ),
        if (unlocked == 0)
          const _Hint('Sランクを 10かい とると あたらしい ポーズが でるよ！'),
      ],
    );
  }

  Widget _profileBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('マイページ  Profile'),
        _Row('なまえ', _name.isEmpty ? 'なまえ みせってい' : _name),
        _ArkButton(label: 'なまえを かえる', onTap: _rename),
        _Row('なかま', '${_friends.length} / ${_mons.length}'),
        _Row('あつめた ポーズ', '$_totalCards'),
        // School-issued login; hidden until Firebase is configured.
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: ArkAccountRow(),
        ),
      ],
    );
  }

  Widget _settingsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('せってい  Settings'),
        _Row(
          'こうかおん',
          null,
          trailing: _ArkToggle(
            on: _se,
            onTap: () async {
              await _progress.setSeOn(!_se);
              _load();
            },
          ),
        ),
        _Row(
          'えいごの こえ',
          null,
          trailing: _ArkToggle(
            on: _voice,
            onTap: () async {
              await _progress.setVoiceOn(!_voice);
              _load();
            },
          ),
        ),
        if (KidsStore.showPurchaseUi)
          ValueListenableBuilder<bool>(
            valueListenable: PurchaseService.instance.isUnlocked,
            builder: (context, unlocked, _) => unlocked
                ? const _Row('ぜんぶの もんだい', 'あそべるよ ✅')
                : _ArkButton(
                    label: 'ぜんぶの もんだいを あそぶ',
                    // Parent gate first; restore / codes are in the sheet.
                    onTap: () => KidsStore.openPaywall(context),
                  ),
          ),
        const SizedBox(height: 8),
        _ArkButton(
          label: _syncing ? 'こうしんちゅう…' : 'もんだいデータを こうしん',
          onTap: _syncing ? null : _sync,
        ),
        if (_syncMsg.isNotEmpty) _Hint(_syncMsg),
      ],
    );
  }
}

/// `.ark-sheet h2`
class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _purpleDeep,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// `.ark-hint`
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _hint, fontSize: 12, height: 1.7),
      ),
    );
  }
}

/// `.ark-grid`: two columns, 12px gap.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      },
    );
  }
}

/// `.ark-card` (`.got` when [image] is set, `.lock` otherwise).
class _MonCard extends StatelessWidget {
  const _MonCard({
    required this.image,
    required this.label,
    this.silhouette,
    this.onTap,
  });

  final String? image;

  /// Locked cards show this monster as a dark shape (web leaves it blank).
  final String? silhouette;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final got = image != null;
    final card = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: got ? const Color(0xFFFFF8E6) : const Color(0xFFF5F1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: got ? const Color(0xFFFFB300) : const Color(0xFFD9CFFB),
          width: 3,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: got
                ? Image.asset(image!, fit: BoxFit.contain)
                : silhouette == null
                    ? const SizedBox.expand()
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF3A3150),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(silhouette!, fit: BoxFit.contain),
                      ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: _purpleDeep,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
    if (!got) {
      // .ark-card.lock{filter:grayscale(1);opacity:.55}
      return Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: card,
        ),
      );
    }
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// `.ark-row`: label left, bold value right, dashed bottom border.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0xFF444444),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return CustomPaint(
      painter: const _DashedBottom(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            trailing ??
                Text(
                  value ?? '',
                  style: style.copyWith(fontWeight: FontWeight.w900),
                ),
          ],
        ),
      ),
    );
  }
}

class _DashedBottom extends CustomPainter {
  const _DashedBottom();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 1;
    final y = size.height - 0.5;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.ark-btn`: purple pill, centred.
class _ArkButton extends StatelessWidget {
  const _ArkButton({required this.label, required this.onTap, this.compact = false});

  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 0 : 8),
        child: Pressable(
          onTap: onTap,
          pressedScale: 0.95,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: onTap == null
                  ? AppColors.purple.withValues(alpha: 0.5)
                  : AppColors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.ark-toggle`: ON / OFF pill.
class _ArkToggle extends StatelessWidget {
  const _ArkToggle({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? AppColors.purple : const Color(0xFFB9B3C9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          on ? 'ON' : 'OFF',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Replaces the web `prompt('なまえを いれてね')`.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.gold, width: 4),
      ),
      title: const Text(
        'なまえを いれてね',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _purpleDeep,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 12,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        _ArkButton(
          label: 'けってい',
          onTap: () => Navigator.of(context).pop(_c.text),
        ),
      ],
    );
  }
}
