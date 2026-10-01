import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tap target that sinks while pressed, like the web `:active` rules
/// (`transform: scale(.97)` / `translateY(4px)`), with a springy release.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.pressedOffset = 0,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Scale while held (web `.wcard:active{transform:scale(.97)}`).
  final double pressedScale;

  /// Downward shift in px while held (web `translateY(3px)` buttons).
  final double pressedOffset;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
    // Runs 1→0 on release; dips below 0 at the end so the target pops back.
    reverseCurve: Curves.easeInBack,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap == null) return;
    _c.forward();
  }

  void _up(_) => _c.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: () => _c.reverse(),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final v = _t.value;
          return Transform.translate(
            offset: Offset(0, widget.pressedOffset * v),
            child: Transform.scale(
              scale: 1 - (1 - widget.pressedScale) * v,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
