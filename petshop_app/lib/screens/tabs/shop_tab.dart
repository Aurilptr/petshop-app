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
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  List<dynamic> _products = [];
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
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    print("[ShopTab] Fetching product list...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      print("[ShopTab] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Ambil SEMUA produk (tanpa limit 5)
            _products = allItems.where((item) => item['tipe'] == 'produk').toList();
            _isLoading = false;
          });
          print("[ShopTab] Loaded ${_products.length} products.");
        }
      }
    } catch (e) {
      print("[ShopTab] Error fetching products: $e");
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
      backgroundColor: _bgDark, // Background Gelap
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor)) 
        : _products.isEmpty 
            ? Center(child: Text("Belum ada produk.", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)))
            : RefreshIndicator(
                onRefresh: _fetchProducts,
                color: _accentColor,
                backgroundColor: _bgLight,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
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
        color: _bgLight, // Card Gelap
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                      errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: _textGrey),
                    ),
                  ),
                ),
                if (isHabis)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(5)),
                      child: Text("HABIS", style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.bold)),
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
                Text(
                  item['nama'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14, color: isHabis ? Colors.grey : _textWhite),
                ),
                const SizedBox(height: 5),
                
                // --- HARGA & STOK SEJAJAR ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatRupiah.format(item['harga']),
                      style: TextStyle(fontFamily: _fontFamily, color: isHabis ? Colors.grey : _accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    if (!isHabis) 
                      Text("Stok: $stok", style: TextStyle(fontFamily: _fontFamily, fontSize: 10, color: _textGrey)),
                  ],
                ),
                // -----------------------------

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      print("[ShopTab] Add to Cart Clicked: ${item['nama']}");
                      
                      // CEK CART SERVICE DULU
                      int currentQty = 0;
                      try {
                        currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty'];
                      } catch (e) { currentQty = 0; }

                      if (currentQty >= stok) {
                        print("[ShopTab] Stock insufficient for ${item['nama']}");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                      } else {
                        print("[ShopTab] Item added to cart");
                        CartService.addItem(item);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['nama']} masuk keranjang!'), duration: const Duration(seconds: 1), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHabis ? Colors.white.withOpacity(0.1) : _accentColor, 
                      foregroundColor: isHabis ? Colors.white.withOpacity(0.3) : Colors.white, 
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isHabis ? "Sold Out" : "Add +", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.bold)),
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