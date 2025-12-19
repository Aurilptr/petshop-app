// File: lib/screens/main_page.dart

import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/shop_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/profile_tab.dart';
import 'cart_page.dart'; 
import '../services/cart_service.dart'; 

class MainPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MainPage({super.key, required this.userData});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; 
  late List<Widget> _pages;

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna BottomBar
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[MainPage] InitState. User: ${widget.userData['nama_lengkap']}");
    CartService.loadCart(); 
    _initPages();
  }

  void _initPages() {
    print("[MainPage] Initializing Pages...");
    _pages = [
      HomeTab(userData: widget.userData),
      const ShopTab(),
      ServicesTab(userData: widget.userData),
      OrdersTab(userId: widget.userData['id']),
      ProfileTab(userData: widget.userData), 
    ];
  }

  void _onItemTapped(int index) {
    print("[MainPage] Tab Changed to Index: $index");
    setState(() {
      _selectedIndex = index; 
      // Trik: Re-init pages supaya halaman OrdersTab mereload data API setiap kali kita pindah tab.
      _initPages(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    // Logic untuk menyembunyikan AppBar di Home & Profile karena mereka punya Header sendiri
    bool showAppBar = _selectedIndex != 0 && _selectedIndex != 4;

    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      
      // AppBar hanya muncul di Tab Shop, Services, dan Orders
      appBar: showAppBar ? AppBar(
        title: Text(
          _getTitle(_selectedIndex), 
          style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)
        ),
        backgroundColor: _bgDark, 
        foregroundColor: _textWhite, 
        elevation: 0, 
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: _accentColor),
            onPressed: () {
              print("[MainPage] Navigate to CartPage");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(userId: widget.userData['id']),
                ),
              ).then((value) {
                print("[MainPage] Returned from CartPage. Refreshing...");
                setState(() {
                  _initPages();
                });
              });
            },
          ),
        ],
      ) : null, // Jika Home/Profile, AppBar null (hilang)
      
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: BottomNavigationBar(
          backgroundColor: _bgLight, // Warna Navy
          type: BottomNavigationBarType.fixed, 
          currentIndex: _selectedIndex, 
          selectedItemColor: _accentColor, // Warna Teal saat aktif
          unselectedItemColor: Colors.grey, 
          selectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontFamily: _fontFamily, fontSize: 11),
          onTap: _onItemTapped, 
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Belanja'),
            BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), activeIcon: Icon(Icons.pets), label: 'Layanan'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1: return 'Belanja Produk';
      case 2: return 'Pesan Layanan';
      case 3: return 'Riwayat Pesanan';
      default: return 'PawMate';
    }
  }
}