import 'package:flutter/material.dart';

import 'tokens.dart';

export 'tokens.dart';

/// RM Ledger Sync theme (design system v1.0). Built by hand from [RmTokens]
/// so every Material component inherits the muted, restrained palette.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? RmTokens.dark : RmTokens.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.interactive,
    onPrimary: t.onInteractive,
    primaryContainer: t.infoBg,
    onPrimaryContainer: t.infoText,
    secondary: t.interactive,
    onSecondary: t.onInteractive,
    secondaryContainer: t.navSelected,
    onSecondaryContainer: t.textPrimary,
    tertiary: t.successIcon,
    onTertiary: dark ? t.background : RmColors.white,
    tertiaryContainer: t.successBg,
    onTertiaryContainer: t.successText,
    error: t.dangerIcon,
    onError: dark ? t.background : RmColors.white,
    errorContainer: t.dangerBg,
    onErrorContainer: t.dangerText,
    surface: t.surface,
    onSurface: t.textPrimary,
    onSurfaceVariant: t.textSecondary,
    surfaceDim: t.background,
    surfaceBright: t.surface,
    surfaceContainerLowest: t.surface,
    surfaceContainerLow: t.surface,
    surfaceContainer: t.surfaceAlt,
    surfaceContainerHigh: t.surfaceAlt,
    surfaceContainerHighest: t.surfaceGuide,
    outline: t.border,
    outlineVariant: t.border,
    shadow: RmColors.shadow,
    scrim: RmColors.scrim,
    inverseSurface: dark ? t.textPrimary : RmColors.textLight,
    onInverseSurface: dark ? t.background : RmColors.white,
    inversePrimary: dark ? t.interactive : t.link,
    surfaceTint: Colors.transparent,
  );

  const fontFamily = 'Segoe UI Variable Text';
  const fallback = ['Segoe UI', 'Arial', 'sans-serif'];

  TextStyle s(double size, FontWeight w, Color c, {double height = 1.45}) =>
      TextStyle(fontSize: size, fontWeight: w, color: c, height: height, fontFamily: fontFamily, fontFamilyFallback: fallback);

  final text = TextTheme(
    // Guía Visual §2: H1 32 SemiBold 1.25, H2 24 SemiBold 1.3, H3 20 Medium
    // 1.3, H4 16 SemiBold 1.4, body 14 Regular 1.5, supporting 12 Regular
    // 1.5, caption 11 Medium 1.5.
    displaySmall: s(32, FontWeight.w600, t.textPrimary, height: 1.25),
    headlineLarge: s(32, FontWeight.w600, t.textPrimary, height: 1.25),
    headlineMedium: s(32, FontWeight.w600, t.textPrimary, height: 1.25), // H1 page title
    headlineSmall: s(24, FontWeight.w600, t.textPrimary, height: 1.3), // H2 section
    titleLarge: s(20, FontWeight.w500, t.textPrimary, height: 1.3), // H3 subsection / dialog
    titleMedium: s(16, FontWeight.w600, t.textPrimary, height: 1.4), // H4 block title
    titleSmall: s(14, FontWeight.w600, t.textPrimary, height: 1.4),
    bodyLarge: s(15, FontWeight.w400, t.textPrimary, height: 1.5),
    bodyMedium: s(14, FontWeight.w400, t.textPrimary, height: 1.5), // body
    bodySmall: s(12, FontWeight.w400, t.textSecondary, height: 1.5), // supporting
    labelLarge: s(14, FontWeight.w600, t.textPrimary, height: 1.3), // action labels
    labelMedium: s(12.5, FontWeight.w600, t.textSecondary, height: 1.3),
    labelSmall: s(11, FontWeight.w500, t.textSecondary, height: 1.5), // caption
  );

  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control));
  const minControl = Size(64, 40);
  const pad = EdgeInsets.symmetric(horizontal: 16, vertical: 10);

  // 2px focus ring, visible without relying on fill color.
  WidgetStateProperty<BorderSide?> focusSide(BorderSide rest) => WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.focused) ? BorderSide(color: t.focus, width: 2) : rest,
      );
  WidgetStateProperty<Color?> overlay(Color base) => WidgetStateProperty.resolveWith((st) {
        if (st.contains(WidgetState.pressed)) return base.withValues(alpha: 0.14);
        if (st.contains(WidgetState.hovered)) return base.withValues(alpha: 0.08);
        if (st.contains(WidgetState.focused)) return base.withValues(alpha: 0.10);
        return null;
      });
  final disabledFg = t.textMuted.withValues(alpha: 0.75);
  final disabledBg = t.border.withValues(alpha: dark ? 0.6 : 0.7);

  final filledStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(minControl),
    padding: const WidgetStatePropertyAll(pad),
    shape: WidgetStatePropertyAll(controlShape),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    elevation: const WidgetStatePropertyAll(0),
    foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.disabled) ? disabledFg : t.onInteractive),
    backgroundColor: WidgetStateProperty.resolveWith((st) {
      if (st.contains(WidgetState.disabled)) return disabledBg;
      if (st.contains(WidgetState.pressed)) return t.interactivePressed;
      if (st.contains(WidgetState.hovered)) return t.interactiveHover;
      return t.interactive;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    side: focusSide(BorderSide.none),
  );

  final outlinedStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(minControl),
    padding: const WidgetStatePropertyAll(pad),
    shape: WidgetStatePropertyAll(controlShape),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.disabled) ? disabledFg : t.textPrimary),
    backgroundColor: WidgetStateProperty.resolveWith((st) =>
        st.contains(WidgetState.hovered) || st.contains(WidgetState.pressed) ? t.surfaceAlt : t.surface),
    overlayColor: overlay(t.interactive),
    side: focusSide(BorderSide(color: t.border)),
  );

  final textStyleBtn = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(minControl),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    shape: WidgetStatePropertyAll(controlShape),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
    foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.disabled) ? disabledFg : t.link),
    overlayColor: overlay(t.link),
    side: focusSide(BorderSide.none),
  );

  OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(RmRadius.control), borderSide: BorderSide(color: c, width: w));

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    fontFamily: fontFamily,
    fontFamilyFallback: fallback,
    textTheme: text,
    extensions: [t],
  );

  return base.copyWith(
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    dividerColor: t.border,
    focusColor: t.focus.withValues(alpha: 0.18),
    hoverColor: t.surfaceAlt,
    splashFactory: NoSplash.splashFactory,
    iconTheme: IconThemeData(color: t.textSecondary, size: 20),
    appBarTheme: AppBarTheme(
      backgroundColor: t.background,
      foregroundColor: t.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: t.textSecondary, size: 20),
      actionsIconTheme: IconThemeData(color: t.textSecondary, size: 20),
      shape: Border(bottom: BorderSide(color: t.border)),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.card), side: BorderSide(color: t.border)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: filledStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filledStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedStyle),
    textButtonTheme: TextButtonThemeData(style: textStyleBtn),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.disabled) ? disabledFg : t.textSecondary),
        overlayColor: overlay(t.interactive),
        side: focusSide(BorderSide.none),
        shape: WidgetStatePropertyAll(controlShape),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(minControl),
        shape: WidgetStatePropertyAll(controlShape),
        side: focusSide(BorderSide(color: t.border)),
        backgroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.navSelected : t.surface),
        foregroundColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.link : t.textPrimary),
        iconColor: WidgetStatePropertyAll(t.link),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      // Guía §5: error fields are tinted Peligro, disabled ones grey.
      fillColor: WidgetStateColor.resolveWith((st) {
        if (st.contains(WidgetState.disabled)) return t.surfaceAlt;
        if (st.contains(WidgetState.error)) return t.dangerBg;
        return t.surface;
      }),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: const BoxConstraints(minHeight: 40),
      border: inputBorder(t.border),
      enabledBorder: inputBorder(t.border),
      focusedBorder: inputBorder(t.focus, 2),
      errorBorder: inputBorder(t.dangerIcon),
      focusedErrorBorder: inputBorder(t.dangerIcon, 2),
      disabledBorder: inputBorder(t.border),
      labelStyle: TextStyle(color: t.textSecondary),
      floatingLabelStyle: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600),
      helperStyle: TextStyle(color: t.textSecondary, fontSize: 12.5),
      hintStyle: TextStyle(color: t.textMuted),
      errorStyle: TextStyle(color: t.dangerText, fontSize: 12.5),
      prefixIconColor: t.textSecondary,
      suffixIconColor: t.textSecondary,
      errorMaxLines: 3,
      helperMaxLines: 3,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: t.border)),
        shape: WidgetStatePropertyAll(controlShape),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control), side: BorderSide(color: t.border)),
      textStyle: text.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(t.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(color: t.border)),
      ),
    ),
    // Selected choices read as "Primario suave" with a Primario outline.
    chipTheme: ChipThemeData(
      backgroundColor: t.surface,
      selectedColor: t.navSelected,
      side: WidgetStateBorderSide.resolveWith((st) => st.contains(WidgetState.selected)
          ? BorderSide(color: t.focus, width: 1.2)
          : BorderSide(color: t.border)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control)),
      labelStyle: text.bodyMedium?.copyWith(color: t.textPrimary),
      secondaryLabelStyle: text.bodyMedium?.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: t.link, size: 16),
      checkmarkColor: t.link,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: t.sidebar,
      indicatorColor: t.navSelected,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control)),
      selectedIconTheme: IconThemeData(color: t.link, size: 20),
      unselectedIconTheme: IconThemeData(color: t.textSecondary, size: 20),
      selectedLabelTextStyle: text.labelLarge?.copyWith(fontSize: 13.5, color: t.textPrimary),
      unselectedLabelTextStyle: text.bodyMedium?.copyWith(fontSize: 13.5, color: t.textSecondary),
      useIndicator: true,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: t.sidebar,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.navSelected,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control)),
      iconTheme: WidgetStateProperty.resolveWith((st) =>
          IconThemeData(size: 20, color: st.contains(WidgetState.selected) ? t.link : t.textSecondary)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.navSelected,
      iconTheme: WidgetStateProperty.resolveWith((st) =>
          IconThemeData(size: 20, color: st.contains(WidgetState.selected) ? t.textPrimary : t.textSecondary)),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: t.sidebar, surfaceTintColor: Colors.transparent),
    dataTableTheme: DataTableThemeData(
      headingTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: t.textPrimary),
      // Tabular figures so amounts line up in every financial table.
      dataTextStyle: TextStyle(fontSize: 13.5, color: t.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
      headingRowColor: WidgetStatePropertyAll(t.navSelected),
      dataRowColor: WidgetStateProperty.resolveWith((st) {
        if (st.contains(WidgetState.selected)) return t.navSelected;
        if (st.contains(WidgetState.hovered)) return t.surfaceAlt;
        return null;
      }),
      dividerThickness: 1,
      horizontalMargin: 16,
      columnSpacing: 24,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.textSecondary,
      textColor: t.textPrimary,
      selectedColor: t.textPrimary,
      selectedTileColor: t.navSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control)),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: t.textSecondary,
      collapsedIconColor: t.textSecondary,
      textColor: t.textPrimary,
      collapsedTextColor: t.textPrimary,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.card), side: BorderSide(color: t.border)),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 13),
      decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(6)),
      waitDuration: const Duration(milliseconds: 400),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 14),
      actionTextColor: dark ? RmTokens.light.link : RmTokens.dark.link,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RmRadius.control)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.interactive,
      linearTrackColor: t.border,
      circularTrackColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((st) {
        if (st.contains(WidgetState.disabled)) return disabledBg;
        return st.contains(WidgetState.selected) ? t.interactive : null;
      }),
      checkColor: WidgetStatePropertyAll(t.onInteractive),
      side: BorderSide(color: t.textSecondary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.interactive : t.textSecondary),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.onInteractive : t.textSecondary),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.interactive : t.surfaceAlt),
      trackOutlineColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? t.interactive : t.border),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: t.link,
      unselectedLabelColor: t.textSecondary,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.bodyMedium,
      indicatorColor: t.focus,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: t.border,
    ),
    scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(t.textSecondary.withValues(alpha: 0.35))),
    badgeTheme: BadgeThemeData(backgroundColor: t.dangerIcon, textColor: dark ? t.background : RmColors.white),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
