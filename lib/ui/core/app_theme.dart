import 'package:flutter/material.dart';

ThemeData buildAttendanceTheme() {
  const seed = Color(0xFF28745A);

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F7F3),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF7F7F3),
      foregroundColor: Color(0xFF1E2A24),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF1E2A24),
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: const Color(0xFF1E2A24),
      displayColor: const Color(0xFF1E2A24),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedLabelStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      type: BottomNavigationBarType.fixed,
    ),
  );
}
