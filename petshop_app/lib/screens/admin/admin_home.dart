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
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU
  
  Map<String, dynamic> _stats = {
    'revenue': 0, 'total_orders': 0, 'total_bookings': 0, 'total_users': 0
  };
  
  // Variabel ini sekarang AKAN DIGUNAKAN di build()
  bool _isLoading = true;

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/stats'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stats = json.decode(response.body);
            _isLoading = false; // Matikan loading saat data dapat
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50], 
      appBar: AppBar(
        title: const Text('Admin Dashboard 🎀'),
        backgroundColor: Colors.pink, 
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      // --- PERBAIKAN DISINI: GUNAKAN _isLoading ---
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.pink)) // Tampilkan Loading
          : RefreshIndicator( // Tampilkan Konten jika sudah selesai loading
              onRefresh: _fetchStats,
              color: Colors.pink,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER PROFILE
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30, 
                            backgroundColor: Colors.pink[100], 
                            child: const Icon(Icons.admin_panel_settings, color: Colors.pink, size: 30)
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Halo, ${widget.userData['nama_lengkap']}!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                              const Text("Semangat kerjanya ya! ✨", style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // STATISTIK CARDS
                    const Text("Ringkasan Toko", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                    const SizedBox(height: 15),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard("Pendapatan", formatRupiah.format(_stats['revenue']), Icons.monetization_on, Colors.green),
                        _buildStatCard("Pesanan", "${_stats['total_orders']}", Icons.shopping_bag, Colors.blue),
                        _buildStatCard("Booking", "${_stats['total_bookings']}", Icons.calendar_month, Colors.orange),
                        _buildStatCard("User", "${_stats['total_users']}", Icons.people, Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // MENU NAVIGASI
                    const Text("Menu Utama", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                    const SizedBox(height: 15),
                    
                    _buildMenuTile(
                      title: "Kelola Pesanan",
                      subtitle: "Cek pembayaran & kirim barang",
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageOrdersPage())),
                    ),
                    _buildMenuTile(
                      title: "Kelola Booking",
                      subtitle: "Jadwal grooming & penitipan",
                      icon: Icons.pets,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageBookingsPage())),
                    ),
                    _buildMenuTile(
                      title: "Kelola Produk",
                      subtitle: "Tambah/Edit barang & layanan",
                      icon: Icons.inventory_2,
                      color: Colors.pink,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageItemsPage())),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}