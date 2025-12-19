import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Palet Warna (Sama dengan Login Page agar transisi mulus)
  final Color _bgStart = const Color(0xFF0F2027); 
  final Color _bgEnd = const Color(0xFF203A43); 
  final Color _accentColor = const Color(0xFF4CA1AF); 

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    print("[SplashScreen] App Started. Waiting for timer...");
    Timer(
      // Mengubah durasi menjadi 3 detik (standar UX modern)
      const Duration(seconds: 3),
      () {
        print("[SplashScreen] Navigating to LoginPage");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menggunakan Container dengan Gradient untuk Background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgEnd], // Gradasi Biru Gelap
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Logo Putih
            Icon(
              Icons.pets, 
              size: 100, 
              color: Colors.white.withOpacity(0.9)
            ),
            
            const SizedBox(height: 25),
            
            // Nama Aplikasi (Style Premium)
            const Text(
              'PAWMATE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 5.0, // Memberikan kesan mewah/modern
              ),
            ),

            const SizedBox(height: 10),

            // Tagline Kecil (Opsional, agar tidak sepi)
            Text(
              'Your Pet, Our Passion',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Indicator (Warna Aksen Cyan/Teal)
            CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}