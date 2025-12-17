// File: lib/screens/tabs/shop_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/cart_service.dart';

class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU
  bool _isLoading = true;
  List<dynamic> _products = [];
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Ambil SEMUA produk (tanpa limit 5)
            _products = allItems.where((item) => item['tipe'] == 'produk').toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _products.isEmpty 
            ? const Center(child: Text("Belum ada produk."))
            : RefreshIndicator(
                onRefresh: _fetchProducts,
                child: GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Proporsi kartu
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) => _buildProductCard(_products[index]),
                ),
              ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    int stok = item['stok'] ?? 0;
    bool isHabis = stok <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GAMBAR
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: ColorFiltered(
                    colorFilter: isHabis 
                        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Image(
                      image: _getImage(item['gambar_url']),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (isHabis)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(5)),
                      child: const Text("HABIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          
          // INFO
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isHabis ? Colors.grey : Colors.black)),
                const SizedBox(height: 5),
                
                // --- HARGA & STOK SEJAJAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah.format(item['harga']), style: TextStyle(color: isHabis ? Colors.grey : Colors.pink[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    if (!isHabis) 
                      Text("Stok: $stok", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                // -----------------------------

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      // CEK CART SERVICE DULU
                      int currentQty = 0;
                      try {
                        currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty'];
                      } catch (e) { currentQty = 0; }

                      if (currentQty >= stok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                      } else {
                        CartService.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['nama']} masuk keranjang!'), duration: const Duration(seconds: 1), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHabis ? Colors.grey : Colors.pink, 
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isHabis ? "Sold Out" : "Add +", style: const TextStyle(fontSize: 12)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}