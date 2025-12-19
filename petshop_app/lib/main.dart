// File: lib/main.dart

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; 

void main() {
  runApp(const PawMateApp());
}

class PawMateApp extends StatelessWidget {
  const PawMateApp({super.key});

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Surface/Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawMate',
      
      // --- TEMA GLOBAL DARK MODE ---
      theme: ThemeData(
        brightness: Brightness.dark, // Mengaktifkan mode gelap
        primaryColor: _bgDark,
        scaffoldBackgroundColor: _bgDark, // Default background semua halaman
        fontFamily: _fontFamily, // Default font semua teks

        // Skema Warna
        colorScheme: ColorScheme.dark(
          primary: _accentColor,
          secondary: _accentColor,
          surface: _bgLight,
          background: _bgDark,
          onPrimary: _bgDark, // Warna teks di atas tombol primary
          onSurface: _textWhite, // Warna teks di atas surface
        ),

        // Style AppBar Global
        appBarTheme: AppBarTheme(
          backgroundColor: _bgDark,
          foregroundColor: _textWhite,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _textWhite
          ),
          iconTheme: IconThemeData(color: _textWhite),
        ),

        // Style Input Field Global (Glassmorphism / Outline Teal)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05), // Glass effect
          labelStyle: TextStyle(color: _textGrey),
          hintStyle: TextStyle(color: Colors.white24),
          prefixIconColor: _accentColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _accentColor, width: 2), // Teal saat aktif
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
        
        // Style ElevatedButton Global (Tombol Utama)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor, // Teal
            foregroundColor: _textWhite, 
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.white.withOpacity(0.1), 
            disabledForegroundColor: Colors.white30,
            textStyle: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16
            ),
          ),
        ),
        
        // Style TextButton Global
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _accentColor, // Teks tombol jadi Teal
            textStyle: TextStyle(
              fontFamily: _fontFamily,
              fontWeight: FontWeight.bold
            ),
          ),
        ),

        // Style Checkbox Global
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _accentColor;
            }
            return null; // Default
          }),
          checkColor: MaterialStateProperty.all(_bgDark),
        ),

        // Style Bottom Navigation Bar Global
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _bgLight,
          selectedItemColor: _accentColor,
          unselectedItemColor: _textGrey,
          selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontFamily: _fontFamily),
        ),
      ),
      
      home: const SplashScreen(),
    );
  }
}