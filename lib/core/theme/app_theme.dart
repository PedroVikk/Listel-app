import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens do "Digital Atelier" — raios, gradientes e sombras tintadas.
/// Ficam expostos via ThemeExtension para uso em qualquer widget.
@immutable
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double glassBlur;
  final double glassOpacity;
  final Color primary;
  final Color primaryContainer;

  const AppDesignTokens({
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.glassBlur,
    required this.glassOpacity,
    required this.primary,
    required this.primaryContainer,
  });

  /// Gradiente principal de CTAs — 135° do primary → primaryContainer.
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryContainer],
      );

  /// Sombra tintada para FAB e elementos flutuantes (primary 8%, blur 32, y 12).
  List<BoxShadow> get tintedShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  @override
  AppDesignTokens copyWith({
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? glassBlur,
    double? glassOpacity,
    Color? primary,
    Color? primaryContainer,
  }) =>
      AppDesignTokens(
        radiusSm: radiusSm ?? this.radiusSm,
        radiusMd: radiusMd ?? this.radiusMd,
        radiusLg: radiusLg ?? this.radiusLg,
        radiusXl: radiusXl ?? this.radiusXl,
        glassBlur: glassBlur ?? this.glassBlur,
        glassOpacity: glassOpacity ?? this.glassOpacity,
        primary: primary ?? this.primary,
        primaryContainer: primaryContainer ?? this.primaryContainer,
      );

  @override
  AppDesignTokens lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      radiusXl: radiusXl,
      glassBlur: glassBlur,
      glassOpacity: glassOpacity,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
    );
  }
}

class AppTheme {
  static ThemeData light(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return _build(colorScheme);
  }

  static ThemeData dark(Color primaryColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final tokens = AppDesignTokens(
      radiusSm: 16,
      radiusMd: 24,
      radiusLg: 32,
      radiusXl: 48,
      glassBlur: 20,
      glassOpacity: 0.70,
      primary: colorScheme.primary,
      primaryContainer: colorScheme.primaryContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [tokens],
      textTheme: GoogleFonts.nunitoTextTheme(),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
        ),
        color: colorScheme.surfaceContainerLowest,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow
            .withValues(alpha: tokens.glassOpacity),
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        space: 0,
        thickness: 0,
        color: Colors.transparent,
      ),
    );
  }
}
