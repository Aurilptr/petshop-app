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
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU
  bool _isLoading = false;
  final Set<int> _selectedItemIds = {}; 
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void _updateCart() { setState(() {}); }
  
  void _toggleSelection(int itemId) {
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
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 barang!'), backgroundColor: Colors.orange));
      return;
    }
    _fetchUserDataAndNavigate();
  }

  Future<void> _fetchUserDataAndNavigate() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${widget.userId}'));
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        List<Map<String, dynamic>> selectedItems = CartService.items.where((item) => _selectedItemIds.contains(item['id'])).toList();

        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutPage(userId: widget.userId, userData: userData, items: selectedItems))).then((_) {
          setState(() { _selectedItemIds.clear(); });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteItem(int id, String namaBarang) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Hapus Barang?'), content: Text('Hapus $namaBarang?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), TextButton(onPressed: () { CartService.removeItem(id); if (_selectedItemIds.contains(id)) _selectedItemIds.remove(id); _updateCart(); Navigator.pop(ctx); }, child: const Text('Hapus', style: TextStyle(color: Colors.red)))]));
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
      appBar: AppBar(title: const Text('Keranjang Belanja'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: cartItems.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]), const SizedBox(height: 10), const Text('Keranjang kosong', style: TextStyle(color: Colors.grey))]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final isSelected = _selectedItemIds.contains(item['id']);
                
                // Ambil stok dari item (Default 999 jika tidak ada info)
                int stokTersedia = item['stok'] ?? 999; 

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Checkbox(value: isSelected, activeColor: Colors.pink, onChanged: (val) => _toggleSelection(item['id'])),
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image(image: _getImage(item['gambar_url']), width: 60, height: 60, fit: BoxFit.cover)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2),
                              Text(formatRupiah.format(item['harga']), style: TextStyle(color: Colors.pink[600])),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteItem(item['id'], item['nama'])),
                                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20), onPressed: () { CartService.decreaseQty(item['id']); _updateCart(); }),
                                  Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  
                                  // --- TOMBOL TAMBAH (DIBATASI STOK) ---
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline, color: item['qty'] >= stokTersedia ? Colors.grey : Colors.pink, size: 20),
                                    onPressed: item['qty'] >= stokTersedia 
                                      ? () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencapai batas stok!'))); } 
                                      : () { CartService.addItem(item); _updateCart(); },
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
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('Total Terpilih', style: TextStyle(color: Colors.grey)), Text(formatRupiah.format(_selectedTotalPrice), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink))]),
          ElevatedButton(
            onPressed: _isLoading ? null : _processCheckout, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('CHECKOUT (${_selectedItemIds.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}