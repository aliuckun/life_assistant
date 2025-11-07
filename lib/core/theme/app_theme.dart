// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Uygulamanın temel açık teması
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor:
        Colors.grey[900], // Resimdeki koyu arka planı simüle et
    brightness: Brightness.dark, // Koyu tema modu
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey[600],
    ),
    // ... Diğer tema ayarları
  );
}
