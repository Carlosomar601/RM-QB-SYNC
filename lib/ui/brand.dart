import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Brand assets (RM Ledger Sync). The multicolor logo is never recolored.
abstract final class BrandAssets {
  static const icon = 'assets/icons/app_icon.png';
  static const iconLarge = 'assets/brand/icon_light.png';
  static const wordmarkDark = 'assets/brand/wordmark_dark.png';
}

/// Small app icon for the title bar / navigation.
class BrandIcon extends StatelessWidget {
  const BrandIcon({super.key, this.size = 26});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset(BrandAssets.icon, width: size, height: size, semanticLabel: AppInfo.displayName);
}

/// Login / welcome header: the horizontal wordmark on dark surfaces, the
/// light rounded icon plus the product name on light surfaces.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle, this.compact = false});
  final String? subtitle;

  /// Smaller mark for dense screens (login) so the form fits at 125-150% scaling.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dark)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 280 : 340),
              child: Image.asset(BrandAssets.wordmarkDark, semanticLabel: 'Logo ${AppInfo.displayName}'),
            ),
          )
        else ...[
          Image.asset(BrandAssets.iconLarge, height: compact ? 60 : 88, semanticLabel: 'Logo ${AppInfo.displayName}'),
          SizedBox(height: compact ? 8 : 12),
          Text(AppInfo.displayName, textAlign: TextAlign.center, style: compact ? t.headlineSmall : t.headlineMedium),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: t.bodySmall?.color)),
        ],
      ],
    );
  }
}
