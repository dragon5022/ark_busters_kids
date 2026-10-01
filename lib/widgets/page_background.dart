import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'web_sparkle_background.dart';

/// Same as web body: CSS radial purple + twinkle layer (no custom bg image).
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: WebSparkleBackground(child: child),
    );
  }
}
