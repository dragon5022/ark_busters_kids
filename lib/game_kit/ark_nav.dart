import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../screens/meta/meta_screens.dart';
import '../widgets/effects.dart';
import '../widgets/pressable.dart';

/// Web `#arkNav`: dark bar with a gold top border opening the ArkPanel.
///
/// The hub uses 76px icons with Japanese labels; game start screens use the
/// compact variant (50px icons, English labels, `padding:8px 4px`).
class ArkBottomNav extends StatelessWidget {
  const ArkBottomNav({super.key, this.compact = false});

  final bool compact;

  /// Height excluding the bottom safe area, for list padding.
  static double heightFor({bool compact = false}) => compact ? 86 : 120;

  @override
  Widget build(BuildContext context) {
    final v = compact ? 8.0 : 6.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        4,
        v,
        4,
        v + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xEB140C2D), // rgba(20,12,45,.92)
        border: Border(top: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            asset: 'assets/images/hub/collection.webp',
            label: compact ? 'Collection' : 'コレクション',
            kind: ArkPanelKind.collection,
            compact: compact,
          ),
          _NavItem(
            asset: 'assets/images/hub/profile.webp',
            label: compact ? 'Profile' : 'プロフィール',
            kind: ArkPanelKind.profile,
            compact: compact,
          ),
          _NavItem(
            asset: 'assets/images/hub/setting.webp',
            label: compact ? 'Settings' : 'せってい',
            kind: ArkPanelKind.settings,
            compact: compact,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.label,
    required this.kind,
    required this.compact,
  });

  final String asset;
  final String label;
  final ArkPanelKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = compact ? 50.0 : 76.0;
    return Flexible(
      child: Pressable(
        onTap: () => ArkPanel.show(context, kind),
        pressedScale: 0.9,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 12,
            vertical: compact ? 5 : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArtShadow(
                color: const Color(0x66000000),
                offset: const Offset(0, 1),
                blur: 2,
                child: Image.asset(
                  asset,
                  width: icon,
                  height: icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: const Color(0xFFFFD54A),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 0.48 : 0.52,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
