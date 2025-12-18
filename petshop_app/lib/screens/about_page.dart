// File: lib/screens/about_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Fungsi untuk membuka URL dengan parameter BuildContext agar bisa menampilkan SnackBar
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuka link: $urlString')),
          );
        }
      }
    } catch (e) {
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
              const SizedBox(height: 30),

              // --- TOMBOL DEMO YOUTUBE ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(context, 'https://youtu.be/436O0XnT3yQ?si=TAcETSQnmoNIIQSh'),
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

              const SizedBox(height: 30),

              // --- CARD API PUBLIK ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sumber Data Eksternal:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              _buildApiCard(
                context: context,
                title: "Dog Facts API",
                subtitle: "Penyedia fakta unik tentang anjing",
                url: "https://dog-api.kinduff.com",
                icon: Icons.pets,
                color: Colors.orange,
              ),
              _buildApiCard(
                context: context,
                title: "Cat Fact API",
                subtitle: "Penyedia fakta unik tentang kucing",
                url: "https://catfact.ninja",
                icon: Icons.pets_outlined,
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              // --- BIODATA DEVELOPER ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Dikembangkan Oleh:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  // Widget Helper untuk API Card
  Widget _buildApiCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
        onTap: () => _launchUrl(context, url),
      ),
    );
  }

  // Widget Helper untuk Dev Card
  Widget _buildDevCard(String nama, String npm, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink[50],
          child: Icon(icon, color: Colors.pink),
        ),
        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(npm),
      ),
    );
  }
}