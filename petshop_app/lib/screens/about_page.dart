// File: lib/screens/about_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  // Fungsi untuk membuka URL
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    print("[AboutPage] Launching URL: $urlString");
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print("[AboutPage] Failed to launch URL");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuka link: $urlString')),
          );
        }
      } else {
        print("[AboutPage] URL Launched successfully");
      }
    } catch (e) {
      print("[AboutPage] Error launching URL: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Tentang Aplikasi", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 80, color: _accentColor), // Icon Teal
              const SizedBox(height: 10),
              Text(
                "PawMate App v1.0",
                style: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold, color: _textWhite),
              ),
              const SizedBox(height: 10),
              Text(
                "Aplikasi Petshop terlengkap untuk kebutuhan anabul kesayangan Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _fontFamily, color: _textGrey),
              ),
              const SizedBox(height: 30),

              // --- TOMBOL DEMO YOUTUBE ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(context, 'https://youtu.be/436O0XnT3yQ?si=TAcETSQnmoNIIQSh'),
                  icon: const Icon(Icons.play_circle_fill),
                  label: Text("Tonton Demo Aplikasi", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Tetap Merah untuk YouTube
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: Colors.redAccent.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- CARD API PUBLIK ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sumber Data Eksternal:",
                  style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite),
                ),
              ),
              const SizedBox(height: 10),
              _buildApiCard(
                context: context,
                title: "Dog Facts API",
                subtitle: "Penyedia fakta unik tentang anjing",
                url: "https://dog-api.kinduff.com",
                icon: Icons.pets,
                color: Colors.orangeAccent,
              ),
              _buildApiCard(
                context: context,
                title: "Cat Fact API",
                subtitle: "Penyedia fakta unik tentang kucing",
                url: "https://catfact.ninja",
                icon: Icons.pets_outlined,
                color: Colors.blueAccent,
              ),

              const SizedBox(height: 30),

              // --- BIODATA DEVELOPER ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dikembangkan Oleh:",
                  style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite),
                ),
              ),
              const SizedBox(height: 10),
              
              _buildDevCard("Auril Putri Amanda", "15-2023-023", Icons.person),
              const SizedBox(height: 10),
              _buildDevCard("Rizky Aqil Hibatullah", "15-2023-052", Icons.person_outline),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk API Card (Dark Theme)
  Widget _buildApiCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      color: _bgLight, // Card Gelap
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14, color: _textWhite)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white54),
        onTap: () => _launchUrl(context, url),
      ),
    );
  }

  // Widget Helper untuk Dev Card (Dark Theme)
  Widget _buildDevCard(String nama, String npm, IconData icon) {
    return Card(
      elevation: 2,
      color: _bgLight, // Card Gelap
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accentColor.withOpacity(0.1), // Background Avatar Teal Transparan
          child: Icon(icon, color: _accentColor), // Icon Teal
        ),
        title: Text(nama, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        subtitle: Text(npm, style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
      ),
    );
  }
}