// File: lib/screens/admin/admin_home.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Import halaman lain
import '../login_page.dart'; 
import 'manage_orders_page.dart';
import 'manage_bookings_page.dart';
import 'manage_items_page.dart'; 

class AdminHomePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AdminHomePage({super.key, required this.userData});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  
  Map<String, dynamic> _stats = {
    'revenue': 0, 'total_orders': 0, 'total_bookings': 0, 'total_users': 0
  };
  
  bool _isLoading = true;

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[AdminHome] InitState. Admin: ${widget.userData['nama_lengkap']}");
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    print("[AdminHome] Fetching statistics...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/stats'));
      print("[AdminHome] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = json.decode(response.body);
            _isLoading = false; 
          });
          print("[AdminHome] Stats Loaded: $_stats");
        }
      } else {
        print("[AdminHome] Failed to load stats.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[AdminHome] Error fetching stats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    print("[AdminHome] Logout clicked.");
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text('Admin Dashboard', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        backgroundColor: _bgDark, 
        foregroundColor: _textWhite,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _logout, 
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
          )
        ],
      ),
      
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _accentColor)) 
          : RefreshIndicator( 
              onRefresh: _fetchStats,
              color: _accentColor,
              backgroundColor: _bgLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER PROFILE (Dark Gradient Style)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_bgLight, _bgDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        border: Border.all(color: Colors.white.withOpacity(0.05))
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30, 
                            backgroundColor: _accentColor.withOpacity(0.2), 
                            child: Icon(Icons.admin_panel_settings, color: _accentColor, size: 30)
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Halo, ${widget.userData['nama_lengkap']}!", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite)),
                              Text("Mode Administrator Aktif ✨", style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // STATISTIK CARDS
                    Text("Ringkasan Toko", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor)),
                    const SizedBox(height: 15),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard("Pendapatan", formatRupiah.format(_stats['revenue']), Icons.monetization_on, Colors.greenAccent),
                        _buildStatCard("Pesanan", "${_stats['total_orders']}", Icons.shopping_bag, Colors.blueAccent),
                        _buildStatCard("Booking", "${_stats['total_bookings']}", Icons.calendar_month, Colors.orangeAccent),
                        _buildStatCard("User", "${_stats['total_users']}", Icons.people, Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // MENU NAVIGASI
                    Text("Menu Utama", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor)),
                    const SizedBox(height: 15),
                    
                    _buildMenuTile(
                      title: "Kelola Pesanan",
                      subtitle: "Cek pembayaran & kirim barang",
                      icon: Icons.receipt_long,
                      color: Colors.blueAccent,
                      onTap: () {
                        print("[AdminHome] Navigating to Manage Orders");
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageOrdersPage()));
                      },
                    ),
                    _buildMenuTile(
                      title: "Kelola Booking",
                      subtitle: "Jadwal grooming & penitipan",
                      icon: Icons.pets,
                      color: Colors.orangeAccent,
                      onTap: () {
                        print("[AdminHome] Navigating to Manage Bookings");
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage()));
                      },
                    ),
                    _buildMenuTile(
                      title: "Kelola Produk",
                      subtitle: "Tambah/Edit barang & layanan",
                      icon: Icons.inventory_2,
                      color: _accentColor,
                      onTap: () {
                        print("[AdminHome] Navigating to Manage Items");
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageItemsPage()));
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Stat Card (Dark Theme)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _bgLight, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite)),
          Text(title, style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
        ],
      ),
    );
  }

  // Widget Menu Tile (Dark Theme)
  Widget _buildMenuTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: _bgLight, // Card Gelap
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
        trailing: Icon(Icons.chevron_right, color: _textGrey),
        onTap: onTap,
      ),
    );
  }
}