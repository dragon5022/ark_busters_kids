import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/audio_service.dart';
import '../widgets/effects.dart';
import '../widgets/pressable.dart';

/// Shared buttons and dialogs used by the hub and every game.

/// Web `#arkHomeBtn`: white pill "🏠 もどる" (top-left on game pages).
class ArkHomeButton extends StatelessWidget {
  const ArkHomeButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x4D3C2878), offset: Offset(0, 3)),
          ],
        ),
        child: const Text(
          '🏠 もどる',
          style: TextStyle(
            color: AppColors.purpleDeep,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Web `.bgm-btn`: white circle with gold border; toggles BGM (🔊 / 🔇).
class BgmButton extends StatefulWidget {
  const BgmButton({super.key, this.size = 46});

  final double size;

  @override
  State<BgmButton> createState() => _BgmButtonState();
}

class _BgmButtonState extends State<BgmButton> {
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
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, offset: Offset(0, 3)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, a) =>
              ScaleTransition(scale: a, child: child),
          child: Text(
            on ? '🔊' : '🔇',
            key: ValueKey(on),
            style: TextStyle(fontSize: widget.size * 0.43, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Web `.btn`: gold pill with a hard dark-gold shadow (`.white` variant).
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.white = false,
    this.color,
    this.textColor,
    this.shadowColor,
    this.fontSize = 17,
    this.padding = const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
    this.shine = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool white;
  final Color? color;
  final Color? textColor;
  final Color? shadowColor;
  final double fontSize;
  final EdgeInsets padding;

  /// Adds a periodic light sweep (use on the main call-to-action).
  final bool shine;

  static const navy = Color(0xFF1F3864);
  static const gold = Color(0xFFFFC93C);

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (white ? Colors.white : gold);
    final shadow =
        shadowColor ?? (white ? const Color(0xFFC9C9C9) : const Color(0xFF8A6800));
    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 5))],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Zen Maru Gothic',
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          color: textColor ?? navy,
        ),
      ),
    );
    if (shine) body = ShineSweep(opacity: 0.5, child: body);
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Pressable(
        onTap: onTap,
        pressedScale: 1,
        pressedOffset: 3,
        child: body,
      ),
    );
  }
}

/// Web `.quitbtn`: translucent pill in the battle HUD.
class QuitButton extends StatelessWidget {
  const QuitButton({super.key, required this.onTap, this.label = 'やめる'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 1,
      pressedOffset: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Zen Maru Gothic',
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Web `.timerwrap` / `.timerbar`: green → gold → pink bar.
class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.fraction, this.width = 230});

  /// Remaining time, 1 → 0.
  final double fraction;
  final double width;

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 100),
        widthFactor: f,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF6A), Color(0xFFFFC93C), Color(0xFFFF5E8A)],
            ),
            // Glows when time is running out.
            boxShadow: f < 0.3
                ? const [BoxShadow(color: Color(0x99FF5E8A), blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }
}

/// Styled replacement for the web `confirm()`. Resolves true on "はい".
Future<bool> showArkConfirm(
  BuildContext context,
  String text, {
  String yes = 'はい',
  String no = 'いいえ',
}) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: const Color(0x99140C2D),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => _ArkDialog(
      text: text,
      actions: [
        _DialogButton(
          label: no,
          color: const Color(0xFFB9B3C9),
          onTap: () => Navigator.of(context).pop(false),
        ),
        _DialogButton(
          label: yes,
          color: AppColors.purple,
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
    transitionBuilder: _popIn,
  );
  return r ?? false;
}

/// Styled replacement for the web `alert()`.
Future<void> showArkNotice(BuildContext context, String text) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: const Color(0x99140C2D),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => _ArkDialog(
      text: text,
      actions: [
        _DialogButton(
          label: 'OK',
          color: AppColors.purple,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    ),
    transitionBuilder: _popIn,
  );
}

Widget _popIn(
  BuildContext context,
  Animation<double> anim,
  Animation<double> _,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      ),
      child: child,
    ),
  );
}

class _ArkDialog extends StatelessWidget {
  const _ArkDialog({required this.text, required this.actions});

  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.gold, width: 4),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      height: 1.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
