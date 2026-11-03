import 'package:flutter/material.dart';

/// Material 3 theme. Seed and text colours chosen for WCAG AA contrast.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0), brightness: brightness);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, visualDensity: VisualDensity.standard);
  return base.copyWith(
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: scheme.outlineVariant)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
      errorMaxLines: 3,
      helperMaxLines: 3,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 13),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(6)),
    ),
    dataTableTheme: DataTableThemeData(headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
    focusColor: scheme.primary.withValues(alpha: 0.16),
  );
}
