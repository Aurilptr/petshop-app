// File: lib/screens/search_result_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import 'booking_form_page.dart'; 

class SearchResultPage extends StatefulWidget {
  final String keyword;
  final int userId; 

  const SearchResultPage({super.key, required this.keyword, required this.userId});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  List<dynamic> _searchResults = [];

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
    print("[SearchResult] InitState. Keyword: '${widget.keyword}'");
    _searchItems();
  }

  Future<void> _searchItems() async {
    print("[SearchResult] Fetching items for search...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      print("[SearchResult] API Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        
        // Filter Client-Side
        List<dynamic> found = allItems.where((item) {
          String itemName = item['nama'].toString().toLowerCase();
          String searchKey = widget.keyword.toLowerCase();
          return itemName.contains(searchKey);
        }).toList();

        if (mounted) {
          setState(() {
            _searchResults = found;
            _isLoading = false;
          });
          print("[SearchResult] Found ${found.length} items matching '${widget.keyword}'");
        }
      } else {
        print("[SearchResult] Failed to load items.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[SearchResult] Error: $e");
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
      appBar: AppBar(
        title: Text('Hasil: "${widget.keyword}"', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 10),
                      Text('Tidak ditemukan barang "${widget.keyword}"', style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(_searchResults[index]);
                  },
                ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    bool isService = item['tipe'] == 'layanan';
    int stok = item['stok'] ?? 0;
    bool isHabis = !isService && stok <= 0;

    return Container(
      decoration: BoxDecoration(
        color: _bgLight, // Card Gelap
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
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
                  style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14, color: isHabis ? Colors.grey : _textWhite)
                ),
                const SizedBox(height: 5),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatRupiah.format(item['harga']), 
                      style: TextStyle(fontFamily: _fontFamily, color: isHabis ? Colors.grey : _accentColor, fontSize: 12, fontWeight: FontWeight.bold)
                    ),
                    if (!isService && !isHabis) 
                      Text("Stok: $stok", style: TextStyle(fontFamily: _fontFamily, fontSize: 10, color: _textGrey)),
                  ],
                ),

                const SizedBox(height: 8),
                
                // TOMBOL AKSI
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      print("[SearchResult] Item Clicked: ${item['nama']} (Service: $isService)");
                      
                      if (isService) {
                        // KE BOOKING
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingFormPage(serviceData: item, userId: widget.userId)));
                      } else {
                        // KE KERANJANG (Cek Stok Dulu)
                        int currentQty = 0;
                        try { currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty']; } catch (e) { currentQty = 0; }

                        if (currentQty >= stok) {
                          print("[SearchResult] Stock limit reached for ${item['nama']}");
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                        } else {
                          print("[SearchResult] Added to cart: ${item['nama']}");
                          CartService.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Masuk Keranjang!'), duration: const Duration(seconds: 1), backgroundColor: Colors.green));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      // Tombol Teal atau Disabled Grey
                      backgroundColor: isHabis ? Colors.white.withOpacity(0.1) : _accentColor, 
                      foregroundColor: isHabis ? Colors.white.withOpacity(0.3) : Colors.white, 
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(isHabis ? "Sold Out" : (isService ? "Booking" : "Add +"), style: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.bold)),
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