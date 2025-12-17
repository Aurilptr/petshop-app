// File: lib/screens/about_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchYoutube() async {
    // Link YouTube Demo
    final Uri url = Uri.parse('https://youtu.be/436O0XnT3yQ?si=TAcETSQnmoNIIQSh'); 
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 80, color: Colors.pink),
              const SizedBox(height: 10),
              const Text(
                "PawMate App v1.0",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              const SizedBox(height: 10),
              const Text(
                "Aplikasi Petshop terlengkap untuk kebutuhan anabul kesayangan Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- BIODATA DEVELOPER ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Dikembangkan Oleh:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              
              _buildDevCard("Auril Putri Amanda", "15-2023-023", Icons.person),
              const SizedBox(height: 10),
              _buildDevCard("Rizky Aqil Hibatullah", "15-2023-052", Icons.person_outline),

              const SizedBox(height: 40),

              // --- TOMBOL DEMO YOUTUBE ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _launchYoutube,
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text("Tonton Demo Aplikasi"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevCard(String nama, String npm, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.pink[50], child: Icon(icon, color: Colors.pink)),
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(npm),
      ),
    );
  }
}