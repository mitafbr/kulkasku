import 'package:flutter/material.dart';

/// Palet warna sayuran Kulkasku.
class AppColors {
  static const cream = Color(0xFFF3EFE7);
  static const paper = Color(0xFFFBF8F2);
  static const ink = Color(0xFF1F2A1B);
  static const muted = Color(0xFF6E7A63);
  static const line = Color(0xFFE6DDC8);

  static const leaf = Color(0xFF2F7D3A);
  static const leafDark = Color(0xFF1F5A28);
  static const leafLight = Color(0xFFA8D86E);
  static const lettuce = Color(0xFFDDEFC8);

  static const carrot = Color(0xFFE8701A);
  static const carrotDark = Color(0xFFB8520A);
  static const carrotLight = Color(0xFFFFE6CF);

  static const tomato = Color(0xFFD93A2B);
  static const tomatoDark = Color(0xFFA9241A);
  static const tomatoLight = Color(0xFFFBE1DC);

  // Kulkas F3: sage + gagang kayu
  static const sage = Color(0xFFA3BA87);
  static const sageLight = Color(0xFFC3D5AB);
  static const sageDark = Color(0xFF93AB78);
  static const sageInk = Color(0xFF4F663D);
  static const wood = Color(0xFF9C6A42);
  static const woodLight = Color(0xFFC08A5C);
  static const woodDark = Color(0xFF7A4E2E);

  // Maskot Mumu
  static const mumuRed = Color(0xFFE9402F);
  static const mumuRedDark = Color(0xFFC82E22);
  static const mumuOutline = Color(0xFF8A3A2E);
  static const mumuStem = Color(0xFFFFF8EE);
  static const mumuEye = Color(0xFF33231D);
  static const blush = Color(0xFFFF8F86);

  static Color hex(String h) {
    final s = h.replaceAll('#', '');
    return Color(int.parse(s.length == 6 ? 'FF$s' : s, radix: 16));
  }
}

class AppText {
  static TextStyle display(double size, {Color color = AppColors.ink, bool italic = true}) =>
      TextStyle(
        fontFamily: 'DMSerifDisplay',
        fontSize: size,
        color: color,
        height: 1.05,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static TextStyle body(double size,
          {Color color = AppColors.ink, FontWeight weight = FontWeight.w700, double? height}) =>
      TextStyle(fontFamily: 'Nunito', fontSize: size, color: color, fontWeight: weight, height: height);

  static TextStyle label({Color color = AppColors.muted, double size = 11}) =>
      TextStyle(fontFamily: 'Nunito', fontSize: size, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: color);
}

/// Bentuk daun: dua sudut bulat besar, dua sudut kecil.
BorderRadius leafRadius(double r, {bool flip = false}) {
  final big = Radius.circular(r);
  final small = Radius.circular(r * 0.25);
  return flip
      ? BorderRadius.only(topLeft: small, topRight: big, bottomLeft: big, bottomRight: small)
      : BorderRadius.only(topLeft: big, topRight: small, bottomLeft: small, bottomRight: big);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      primary: AppColors.leaf,
      secondary: AppColors.carrot,
      surface: AppColors.paper,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );
  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: c, width: w),
      );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Nunito', bodyColor: AppColors.ink, displayColor: AppColors.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(AppColors.line),
      border: border(AppColors.line),
      focusedBorder: border(AppColors.leaf, 2),
      errorBorder: border(const Color(0xFFE46A4B), 1.6),
      focusedErrorBorder: border(const Color(0xFFE46A4B), 2),
      hintStyle: AppText.body(14, color: AppColors.muted, weight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF22301F),
      contentTextStyle: AppText.body(14, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.leaf : const Color(0xFFD9D2C3)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
