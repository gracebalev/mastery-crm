import 'package:material_ui/material_ui.dart';

const brandPurple = Color(0xFF6D3CEB);
const ink = Color(0xFF171521);
const mutedInk = Color(0xFF6F6B7A);
const placeholderInk = Color(0xFFAAA6B2);
const canvasColor = Color(0xFFF6F5F8);
const borderColor = Color(0xFFE8E5ED);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPurple,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvasColor,
    fontFamily: 'Plus Jakarta Sans',
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 41 / 28,
      ),
      headlineSmall: TextStyle(
        color: ink,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 41 / 28,
      ),
      titleLarge: TextStyle(
        color: ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: ink, fontSize: 14),
      bodySmall: TextStyle(color: mutedInk, fontSize: 12),
      labelLarge: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: borderColor),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(
        color: placeholderInk,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: brandPurple, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
