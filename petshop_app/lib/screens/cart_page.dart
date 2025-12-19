// File: lib/screens/cart_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http; 
import 'dart:convert';
import '../services/cart_service.dart'; 
import 'checkout_page.dart'; 

class CartPage extends StatefulWidget {
  final int userId; 
  const CartPage({super.key, required this.userId});
  
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = false;
  final Set<int> _selectedItemIds = {}; 
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
    print("[CartPage] InitState. User ID: ${widget.userId}");
  }

  void _updateCart() { setState(() {}); }
  
  void _toggleSelection(int itemId) {
    print("[CartPage] Toggle item ID: $itemId");
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  int get _selectedTotalPrice {
    int total = 0;
    for (var item in CartService.items) {
      if (_selectedItemIds.contains(item['id'])) {
        int price = item['harga'] ?? 0;
        int qty = item['qty'] ?? 1;
        total += (price * qty);
      }
    }
    return total;
  }

  void _processCheckout() {
    print("[CartPage] Process Checkout Clicked");
    if (_selectedItemIds.isEmpty) {
      print("[CartPage] Checkout failed: No items selected");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang!'), backgroundColor: Colors.orange));
      return;
    }
    _fetchUserDataAndNavigate();
  }

  Future<void> _fetchUserDataAndNavigate() async {
    print("[CartPage] Fetching user data for checkout...");
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${widget.userId}'));
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        List<Map<String, dynamic>> selectedItems = CartService.items.where((item) => _selectedItemIds.contains(item['id'])).toList();

        if (!mounted) return;
        print("[CartPage] Navigate to CheckoutPage with ${selectedItems.length} items");
        
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => CheckoutPage(userId: widget.userId, userData: userData, items: selectedItems))
        ).then((_) {
          // Clear selection setelah balik dari checkout (opsional)
          setState(() { _selectedItemIds.clear(); });
        });
      }
    } catch (e) {
      print("[CartPage] Error fetching user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteItem(int id, String namaBarang) {
    print("[CartPage] Request delete item: $namaBarang");
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text('Hapus Barang?', style: TextStyle(fontFamily: _fontFamily, color: _textWhite)), 
        content: Text('Hapus $namaBarang dari keranjang?', style: TextStyle(fontFamily: _fontFamily, color: _textGrey)), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('Batal', style: TextStyle(fontFamily: _fontFamily, color: Colors.grey))
          ), 
          TextButton(
            onPressed: () { 
              print("[CartPage] Item deleted");
              CartService.removeItem(id); 
              if (_selectedItemIds.contains(id)) _selectedItemIds.remove(id); 
              _updateCart(); 
              Navigator.pop(ctx); 
            }, 
            child: Text('Hapus', style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent))
          )
        ]
      )
    );
  }

  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }
    return const AssetImage('assets/images/pet_avatar.png'); 
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartService.items;
    
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text('Keranjang Belanja', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: _bgDark, 
        foregroundColor: Colors.white, 
        elevation: 0,
        centerTitle: true,
      ),
      
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withOpacity(0.1)), 
                  const SizedBox(height: 10), 
                  Text('Keranjang kosong', style: TextStyle(fontFamily: _fontFamily, color: _textGrey))
                ]
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final isSelected = _selectedItemIds.contains(item['id']);
                
                int stokTersedia = item['stok'] ?? 999; 

                return Card(
                  color: _bgLight, // Card Gelap
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.05))),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.grey),
                          child: Checkbox(
                            value: isSelected, 
                            activeColor: _accentColor, // Checkbox Teal
                            checkColor: _bgDark,
                            onChanged: (val) => _toggleSelection(item['id'])
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8), 
                          child: Image(image: _getImage(item['gambar_url']), width: 60, height: 60, fit: BoxFit.cover)
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nama'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite), maxLines: 2),
                              Text(formatRupiah.format(item['harga']), style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                                    onPressed: () => _deleteItem(item['id'], item['nama'])
                                  ),
                                  
                                  // Tombol Kurang
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20), 
                                    onPressed: () { 
                                      print("[CartPage] Decrease Qty: ${item['nama']}");
                                      CartService.decreaseQty(item['id']); 
                                      _updateCart(); 
                                    }
                                  ),
                                  
                                  Text('${item['qty']}', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
                                  
                                  // Tombol Tambah
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline, color: item['qty'] >= stokTersedia ? Colors.grey : _accentColor, size: 20),
                                    onPressed: item['qty'] >= stokTersedia 
                                      ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencapai batas stok!'))); } 
                                      : () { 
                                          print("[CartPage] Increase Qty: ${item['nama']}");
                                          CartService.addItem(item); 
                                          _updateCart(); 
                                        },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgLight, 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text('Total Terpilih', style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)), 
                Text(formatRupiah.format(_selectedTotalPrice), style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor))
              ]
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _processCheckout, 
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor, // Tombol Checkout Teal
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text('CHECKOUT (${_selectedItemIds.length})', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
            ),
          ]
        ),
      ),
    );
  }
}