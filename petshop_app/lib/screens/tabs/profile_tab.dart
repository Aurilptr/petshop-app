// File: lib/screens/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORTS HALAMAN LAIN
import '../login_page.dart'; 
import '../add_pet_page.dart'; 
import '../pet_detail_page.dart'; 
import '../about_page.dart';    
import '../settings_page.dart'; // Pastikan ini ada

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic> userData; // Data awal dari Login

  const ProfileTab({super.key, required this.userData});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final String _apiUrl = 'http://127.0.0.1:5000'; // IP KAMU
  
  bool _isLoading = true;
  List<dynamic> _pets = [];
  
  // Variabel lokal untuk menampung data user yang bisa berubah (Update Realtime)
  late Map<String, dynamic> _currentUser;

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi data user dari widget ke state lokal
    _currentUser = widget.userData;
    
    // 2. Ambil data hewan
    _fetchMyPets(_currentUser['id']);
  }

  // Fungsi untuk mengambil data hewan
  Future<void> _fetchMyPets(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/pets/user/$userId'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pets = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // FUNGSI BARU: Refresh Data User setelah Edit Profil
  Future<void> _refreshUserData() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${_currentUser['id']}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _currentUser = json.decode(response.body); // Update tampilan header
          });
        }
      }
    } catch (e) {
      print("Gagal refresh user: $e");
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return NetworkImage(url);
      } else {
        return AssetImage(url);
      }
    }
    return const AssetImage('assets/images/pet_avatar.png'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER PROFIL (PINKY STYLE) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[400]!, Colors.pink[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.pink),
                  ),
                  const SizedBox(height: 15),
                  
                  // Gunakan _currentUser agar berubah saat diedit
                  Text(
                    "Halo, ${_currentUser['nama_lengkap']}!", 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  Text(
                    _currentUser['email'], 
                    style: const TextStyle(color: Colors.white70)
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- HEADER MY PETS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Hewan Peliharaan Saya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddPetPage(userId: _currentUser['id'])),
                      );
                      if (result == true) _fetchMyPets(_currentUser['id']);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Tambah"),
                    style: TextButton.styleFrom(foregroundColor: Colors.pink),
                  ),
                ],
              ),
            ),

            // --- LIST HEWAN ---
            SizedBox(
              height: 160, 
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _pets.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, size: 40, color: Colors.grey[300]),
                              const Text("Belum ada hewan.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: _pets.length,
                          itemBuilder: (context, index) {
                            final pet = _pets[index];
                            return GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => PetDetailPage(pet: pet)),
                                );
                                if (result == true) _fetchMyPets(_currentUser['id']);
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Hero(
                                      tag: 'pet-${pet['id']}',
                                      child: CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.pink[50],
                                        backgroundImage: _getImage(pet['foto_url']),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(pet['nama_hewan'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                    Text(pet['jenis'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 20),

            // --- MENU LIST ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.settings, 
                    title: "Pengaturan Akun", 
                    subtitle: "Ubah profil & alamat",
                    color: Colors.blue,
                    onTap: () async {
                      // 3. Panggil halaman Setting dan tunggu hasilnya
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage(userId: _currentUser['id'])),
                      );
                      // 4. Setelah balik, refresh data user
                      _refreshUserData();
                    }
                  ),
                  
                  _buildMenuTile(
                    icon: Icons.info_outline, 
                    title: "Tentang Aplikasi", 
                    subtitle: "Versi 1.0.0",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
                    }
                  ),

                  const SizedBox(height: 10),
                  
                  // LOGOUT
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                      title: const Text("Keluar Akun", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                      onTap: _logout,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Menu
  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}