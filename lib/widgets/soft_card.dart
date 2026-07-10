import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color = AppColors.white,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Adjust background color if it's the default white/surface
    Color effectiveColor = color;
    if (color == AppColors.white || color == AppColors.surface) {
      effectiveColor = theme.cardColor;
    } else if (isDark) {
      // If it's a "Soft" color, we should probably dim it or use a darker version in dark mode
      // For now, let's keep them but maybe wrap with a slight opacity or blend
      effectiveColor = Color.alphaBlend(theme.colorScheme.surface.withValues(alpha: 0.8), color);
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
