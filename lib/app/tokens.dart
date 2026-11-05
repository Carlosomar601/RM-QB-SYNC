import 'package:flutter/material.dart';

/// Foundation palette from "RMQBSync · Guía Visual del Sistema" (§1).
/// This is the ONLY file allowed to contain color hex literals; views bind to
/// [RmTokens] (semantic) or the [ColorScheme] built from it.
abstract final class RmColors {
  static const primaryLight = Color(0xFF5B7392);
  static const primaryDark = Color(0xFF6F95C1);
  static const textLight = Color(0xFF1F2A44);
  static const white = Color(0xFFFFFFFF);
  static const shadow = Color(0x33000000);
  static const scrim = Color(0x8C000000);
}

/// Spacing scale: 4px base.
abstract final class RmSpace {
  // 8px system with a 4px half-step.
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Corner radii: 8 inputs/buttons, 12 cards, pill for status chips.
abstract final class RmRadius {
  static const control = 8.0;
  static const card = 12.0;
  static const pill = 999.0;
}

/// Semantic theme tokens (§4). Bind components to these, never to hexes.
@immutable
class RmTokens extends ThemeExtension<RmTokens> {
  const RmTokens({
    required this.background,
    required this.sidebar,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceGuide,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.focus,
    required this.interactive,
    required this.interactiveHover,
    required this.interactivePressed,
    required this.onInteractive,
    required this.navSelected,
    required this.link,
    required this.successBg,
    required this.successText,
    required this.successIcon,
    required this.warningBg,
    required this.warningText,
    required this.warningIcon,
    required this.dangerBg,
    required this.dangerText,
    required this.dangerIcon,
    required this.infoBg,
    required this.infoText,
    required this.infoIcon,
  });

  final Color background;

  /// Navigation sidebar surface.
  final Color sidebar;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceGuide;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color focus;
  final Color interactive;
  final Color interactiveHover;
  final Color interactivePressed;
  final Color onInteractive;
  final Color navSelected;

  /// Text-only actions and links (TextButton, inline links).
  final Color link;
  final Color successBg;
  final Color successText;
  final Color successIcon;
  final Color warningBg;
  final Color warningText;
  final Color warningIcon;
  final Color dangerBg;
  final Color dangerText;
  final Color dangerIcon;
  final Color infoBg;
  final Color infoText;
  final Color infoIcon;

  // Values from "RMQBSync · Guía Visual del Sistema" (palette §1). Colors not
  // in the guide (secondary text, status text/icons, hover/pressed, sidebar)
  // are derived from it; anything that differs from the guide does so for
  // WCAG AA and is marked "AA" (verified in test/app/theme_test.dart).
  static const light = RmTokens(
    background: Color(0xFFF8F9FC), // Fondo
    sidebar: Color(0xFFEEF3FA),
    surface: Color(0xFFFFFFFF), // Superficie
    surfaceAlt: Color(0xFFF1F5FB),
    surfaceGuide: Color(0xFFDDEFFF), // Info
    textPrimary: Color(0xFF1F2A44), // Texto principal
    textSecondary: Color(0xFF56617A),
    textMuted: Color(0xFF56617A),
    border: Color(0xFFDDE7F0), // Borde
    focus: Color(0xFF5B7392),
    interactive: Color(0xFF5B7392), // Primario (white text 4.87:1)
    interactiveHover: Color(0xFF4F6685),
    interactivePressed: Color(0xFF445A77),
    onInteractive: Color(0xFFFFFFFF),
    navSelected: Color(0xFFE9F2FF), // Primario suave
    // AA: Primario as text is 4.14:1 on Info; one step deeper for links.
    link: Color(0xFF4F6685),
    successBg: Color(0xFFD6F4DF), // Éxito
    successText: Color(0xFF1B6338),
    successIcon: Color(0xFF2A8C50),
    warningBg: Color(0xFFFFF4D6), // Advertencia
    warningText: Color(0xFF6E4A00),
    warningIcon: Color(0xFFB07800),
    dangerBg: Color(0xFFFDE0E0), // Peligro
    dangerText: Color(0xFF952626),
    dangerIcon: Color(0xFFC73B3B),
    infoBg: Color(0xFFDDEFFF), // Info
    infoText: Color(0xFF1B5585),
    infoIcon: Color(0xFF2F7DBA),
  );

  static const dark = RmTokens(
    background: Color(0xFF16202C), // Fondo
    sidebar: Color(0xFF1B2532),
    surface: Color(0xFF1F2A38), // Superficie
    surfaceAlt: Color(0xFF253244),
    // Guidance panels: a calmer navy than Info so body text and links stay AA.
    surfaceGuide: Color(0xFF26405A),
    textPrimary: Color(0xFFEAF2FF), // Texto principal
    textSecondary: Color(0xFFCAD5E2),
    textMuted: Color(0xFFCAD5E2),
    border: Color(0xFF2B3B4C), // Borde
    focus: Color(0xFF8FB3DC),
    // AA: white on Primario #6F95C1 is 3.11:1, so filled buttons use a deeper
    // shade of the same blue (4.99:1). #6F95C1 hue is kept for accents.
    interactive: Color(0xFF4A72A0),
    interactiveHover: Color(0xFF436896),
    interactivePressed: Color(0xFF3D5F8A),
    onInteractive: Color(0xFFFFFFFF),
    navSelected: Color(0xFF334A66), // Primario suave
    link: Color(0xFF9DC0E8),
    successBg: Color(0xFF2E6B4B), // Éxito
    successText: Color(0xFFE3F7EA),
    successIcon: Color(0xFF6FD39B),
    warningBg: Color(0xFF7A5A1D), // Advertencia
    warningText: Color(0xFFFFF1D6),
    warningIcon: Color(0xFFF2C14E),
    dangerBg: Color(0xFF7A3B3B), // Peligro
    dangerText: Color(0xFFFFE3E3),
    dangerIcon: Color(0xFFF28B8B),
    infoBg: Color(0xFF2F5E7E), // Info
    infoText: Color(0xFFE3F2FF),
    infoIcon: Color(0xFF7FC1F0),
  );

  @override
  RmTokens copyWith({
    Color? background,
    Color? sidebar,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceGuide,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? focus,
    Color? interactive,
    Color? interactiveHover,
    Color? interactivePressed,
    Color? onInteractive,
    Color? navSelected,
    Color? link,
    Color? successBg,
    Color? successText,
    Color? successIcon,
    Color? warningBg,
    Color? warningText,
    Color? warningIcon,
    Color? dangerBg,
    Color? dangerText,
    Color? dangerIcon,
    Color? infoBg,
    Color? infoText,
    Color? infoIcon,
  }) =>
      RmTokens(
        background: background ?? this.background,
        sidebar: sidebar ?? this.sidebar,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        surfaceGuide: surfaceGuide ?? this.surfaceGuide,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        focus: focus ?? this.focus,
        interactive: interactive ?? this.interactive,
        interactiveHover: interactiveHover ?? this.interactiveHover,
        interactivePressed: interactivePressed ?? this.interactivePressed,
        onInteractive: onInteractive ?? this.onInteractive,
        navSelected: navSelected ?? this.navSelected,
        link: link ?? this.link,
        successBg: successBg ?? this.successBg,
        successText: successText ?? this.successText,
        successIcon: successIcon ?? this.successIcon,
        warningBg: warningBg ?? this.warningBg,
        warningText: warningText ?? this.warningText,
        warningIcon: warningIcon ?? this.warningIcon,
        dangerBg: dangerBg ?? this.dangerBg,
        dangerText: dangerText ?? this.dangerText,
        dangerIcon: dangerIcon ?? this.dangerIcon,
        infoBg: infoBg ?? this.infoBg,
        infoText: infoText ?? this.infoText,
        infoIcon: infoIcon ?? this.infoIcon,
      );

  @override
  RmTokens lerp(covariant RmTokens? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RmTokens(
      background: l(background, other.background),
      sidebar: l(sidebar, other.sidebar),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      surfaceGuide: l(surfaceGuide, other.surfaceGuide),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      border: l(border, other.border),
      focus: l(focus, other.focus),
      interactive: l(interactive, other.interactive),
      interactiveHover: l(interactiveHover, other.interactiveHover),
      interactivePressed: l(interactivePressed, other.interactivePressed),
      onInteractive: l(onInteractive, other.onInteractive),
      navSelected: l(navSelected, other.navSelected),
      link: l(link, other.link),
      successBg: l(successBg, other.successBg),
      successText: l(successText, other.successText),
      successIcon: l(successIcon, other.successIcon),
      warningBg: l(warningBg, other.warningBg),
      warningText: l(warningText, other.warningText),
      warningIcon: l(warningIcon, other.warningIcon),
      dangerBg: l(dangerBg, other.dangerBg),
      dangerText: l(dangerText, other.dangerText),
      dangerIcon: l(dangerIcon, other.dangerIcon),
      infoBg: l(infoBg, other.infoBg),
      infoText: l(infoText, other.infoText),
      infoIcon: l(infoIcon, other.infoIcon),
    );
  }
}

/// Semantic status used by chips, banners and icons.
enum RmTone { success, warning, danger, info, neutral }

extension RmTokensX on BuildContext {
  RmTokens get rm => Theme.of(this).extension<RmTokens>() ?? RmTokens.light;
}

extension RmToneColors on RmTokens {
  ({Color bg, Color fg, Color icon}) tone(RmTone t) => switch (t) {
        RmTone.success => (bg: successBg, fg: successText, icon: successIcon),
        RmTone.warning => (bg: warningBg, fg: warningText, icon: warningIcon),
        RmTone.danger => (bg: dangerBg, fg: dangerText, icon: dangerIcon),
        RmTone.info => (bg: infoBg, fg: infoText, icon: infoIcon),
        RmTone.neutral => (bg: surfaceAlt, fg: textSecondary, icon: textMuted),
      };
}
