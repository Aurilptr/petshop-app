// File: lib/screens/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// IMPORTS HALAMAN LAIN
import '../login_page.dart'; 
import '../add_pet_page.dart'; 
import '../pet_detail_page.dart'; 
import '../about_page.dart';    
import '../settings_page.dart'; 

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic> userData; // Data awal dari Login

  const ProfileTab({super.key, required this.userData});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  
  bool _isLoading = true;
  List<dynamic> _pets = [];
  
  late Map<String, dynamic> _currentUser;

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card/Header
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _glassWhite = Colors.white.withOpacity(0.05); // Efek Kaca

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[ProfileTab] InitState Called. User ID: ${widget.userData['id']}");
    
    // 1. Inisialisasi data user dari widget ke state lokal
    _currentUser = widget.userData;
    
    // 2. Ambil data hewan
    _fetchMyPets(_currentUser['id']);
  }

  // Fungsi untuk mengambil data hewan
  Future<void> _fetchMyPets(int userId) async {
    print("[ProfileTab] Fetching pets for user ID: $userId...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/pets/user/$userId'));
      print("[ProfileTab] Pets API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _pets = json.decode(response.body);
            _isLoading = false;
          });
          print("[ProfileTab] Loaded ${_pets.length} pets.");
        }
      } else {
        if (mounted) setState(() { _isLoading = false; });
        print("[ProfileTab] Failed to load pets.");
      }
    } catch (e) {
      print("[ProfileTab] Error fetching pets: $e");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Refresh Data User setelah Edit Profil
  Future<void> _refreshUserData() async {
    print("[ProfileTab] Refreshing user profile data...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${_currentUser['id']}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _currentUser = json.decode(response.body); 
          });
          print("[ProfileTab] User profile updated: ${_currentUser['nama_lengkap']}");
        }
      }
    } catch (e) {
      print("[ProfileTab] Failed refresh user: $e");
    }
  }

  void _logout() {
    print("[ProfileTab] Logout button clicked");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text('Konfirmasi Logout', style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin keluar dari aplikasi?', style: TextStyle(fontFamily: _fontFamily, color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Batal', style: TextStyle(fontFamily: _fontFamily, color: Colors.grey))
          ),
          TextButton(
            onPressed: () {
              print("[ProfileTab] Logging out...");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text('Keluar', style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
      backgroundColor: _bgDark, // Background Gelap
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER PROFIL (GRADIENT NAVY) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgDark, _bgLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: _glassWhite,
                    child: Icon(Icons.person, size: 60, color: _accentColor),
                  ),
                  const SizedBox(height: 15),
                  
                  Text(
                    "Halo, ${_currentUser['nama_lengkap']}!", 
                    style: TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentUser['email'], 
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.white70)
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
                  Text("Hewan Peliharaan Saya", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton.icon(
                    onPressed: () async {
                      print("[ProfileTab] Add Pet Clicked");
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddPetPage(userId: _currentUser['id'])),
                      );
                      if (result == true) _fetchMyPets(_currentUser['id']);
                    },
                    icon: Icon(Icons.add, size: 18, color: _accentColor),
                    label: Text("Tambah", style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // --- LIST HEWAN ---
            SizedBox(
              height: 160, 
              child: _isLoading 
                  ? Center(child: CircularProgressIndicator(color: _accentColor))
                  : _pets.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets, size: 40, color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 10),
                              Text("Belum ada hewan.", style: TextStyle(fontFamily: _fontFamily, color: Colors.white54)),
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
                                print("[ProfileTab] Pet Clicked: ${pet['nama_hewan']}");
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
                                  color: _bgLight, // Card Gelap
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Hero(
                                      tag: 'pet-${pet['id']}',
                                      child: CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.white.withOpacity(0.05),
                                        backgroundImage: _getImage(pet['foto_url']),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(pet['nama_hewan'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                    Text(pet['jenis'] ?? '-', style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: Colors.white54)),
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
                    iconColor: Colors.blueAccent,
                    onTap: () async {
                      print("[ProfileTab] Settings Menu Clicked");
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage(userId: _currentUser['id'])),
                      );
                      _refreshUserData();
                    }
                  ),
                  
                  _buildMenuTile(
                    icon: Icons.info_outline, 
                    title: "Tentang Aplikasi", 
                    subtitle: "Versi 1.0.0",
                    iconColor: Colors.purpleAccent,
                    onTap: () {
                      print("[ProfileTab] About Menu Clicked");
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
                    }
                  ),

                  const SizedBox(height: 10),
                  
                  // LOGOUT
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: _bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.logout, color: Colors.redAccent),
                      ),
                      title: Text("Keluar Akun", style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
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
  Widget _buildMenuTile({required IconData icon, required String title, required String subtitle, required Color iconColor, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bgLight, // Card Gelap
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}