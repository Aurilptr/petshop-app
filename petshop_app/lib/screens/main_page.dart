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
  
  // Kita ubah _pages jadi getter atau method biar dinamis, 
  // tapi list biasa juga oke asalkan kita rebuild body-nya.
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    CartService.loadCart(); 
    _initPages();
  }

  void _initPages() {
    _pages = [
      HomeTab(userData: widget.userData),
      const ShopTab(),
      ServicesTab(userData: widget.userData),
      OrdersTab(userId: widget.userData['id']),
      ProfileTab(userData: widget.userData), 
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; 
      // Trik: Re-init pages supaya halaman OrdersTab mereload data API
      // setiap kali kita pindah tab.
      _initPages(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 1, 
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(userId: widget.userData['id']),
                ),
              ).then((value) {
                // INI FIX PENTING:
                // Saat kembali dari Keranjang (mungkin habis checkout), 
                // kita paksa refresh halaman MainPage agar data pesanan muncul.
                setState(() {
                  _initPages();
                });
              });
            },
          ),
        ],
      ),
      
      // FIX UTAMA: Hapus IndexedStack.
      // Gunakan langsung _pages[...] agar halaman dibangun ulang (refresh) saat pindah tab.
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        currentIndex: _selectedIndex, 
        selectedItemColor: Colors.pink, 
        onTap: _onItemTapped, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Belanja'),
          BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), activeIcon: Icon(Icons.pets), label: 'Layanan'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'Hi, ${widget.userData['nama_lengkap']}! 🐾';
      case 1: return 'Belanja Produk';
      case 2: return 'Pesan Layanan';
      case 3: return 'Riwayat Pesanan';
      case 4: return 'Profil Saya';
      default: return 'PawMate';
    }
  }
}