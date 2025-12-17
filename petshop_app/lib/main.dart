import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; 

void main() {
  runApp(const PawMateApp());
}

class PawMateApp extends StatelessWidget {
  const PawMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawMate',
      theme: ThemeData(
        primarySwatch: Colors.pink, 
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins', 

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.pink), 
          ),
          prefixIconColor: Colors.pink[300], 
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.pink[200], 
            disabledForegroundColor: Colors.white70,
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.pink,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}