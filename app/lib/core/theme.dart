import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores tomados de diseno/template/styles.css
class AppColors {
  static const primary = Color(0xFF12358B);
  static const primaryDark = Color(0xFF08296F);
  static const secondary = Color(0xFF2F75E8);
  static const brandCyan = Color(0xFF1FAAC7);
  static const surface = Color(0xFFF6F8FD);
  static const card = Color(0xFFFFFFFF);
  static const softBlue = Color(0xFFEAF1FF);
  static const border = Color(0xFFDDE5F2);
  static const cardBorder = Color(0xFFEDF0F6);
  static const text = Color(0xFF122033);
  static const muted = Color(0xFF677386);
  static const success = Color(0xFF087A55);
  static const successBg = Color(0xFFE1F6ED);
  static const warning = Color(0xFF9A5B00);
  static const warningBg = Color(0xFFFFF1CB);
  static const danger = Color(0xFFC3262E);
  static const dangerBg = Color(0xFFFFE4E4);
  static const shadow = Color(0x14143064); // rgba(20,48,100,.08)
}

/// Estilo monoespaciado para codigos, cantidades y montos.
TextStyle mono({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color ?? AppColors.text);

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final text = GoogleFonts.hankenGroteskTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  const radius10 = BorderRadius.all(Radius.circular(10));

  OutlineInputBorder borde(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: radius10, borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.card,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: text,
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: borde(AppColors.border),
      enabledBorder: borde(AppColors.border),
      focusedBorder: borde(AppColors.secondary, 2),
      errorBorder: borde(AppColors.danger),
      focusedErrorBorder: borde(AppColors.danger, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const RoundedRectangleBorder(borderRadius: radius10),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.softBlue,
        side: const BorderSide(color: Color(0xFFD7E4FF)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: const RoundedRectangleBorder(borderRadius: radius10),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
