import 'package:flutter/material.dart';

final ThemeData theme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1E1E2C),
  primaryColor: const Color(0xFF5C2D91),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF5C2D91),
    secondary: Color(0xFFC76DFF),
    background: Color(0xFF1E1E2C),
    surface: Color(0xFF2B2B3D),
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.white70,
    onSurface: Colors.white,
    onError: Colors.white,
  ),
  textTheme: const TextTheme(
  titleLarge: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Montserrat'),
  titleMedium: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Montserrat'),
  bodyLarge: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Montserrat'),
  bodyMedium: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Montserrat'),
  labelSmall: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'Montserrat'),
),
  appBarTheme: const AppBarTheme(
    color: Color(0xFF1E1E2C),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Montserrat'),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFFC76DFF),
    textTheme: ButtonTextTheme.primary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFC76DFF),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontFamily: 'Montserrat'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFC76DFF)),
      textStyle: const TextStyle(fontFamily: 'Montserrat'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFC76DFF),
    foregroundColor: Colors.white,
  ),
  cardColor: const Color(0xFF2B2B3D),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF0D1B2A),
    labelStyle: TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.greenAccent),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);