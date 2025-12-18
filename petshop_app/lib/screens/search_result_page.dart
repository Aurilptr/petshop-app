// File: lib/screens/search_result_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/cart_service.dart';
import 'booking_form_page.dart'; // Import buat booking

class SearchResultPage extends StatefulWidget {
  final String keyword;
  final int userId; // Butuh ID buat booking

  const SearchResultPage({super.key, required this.keyword, required this.userId});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; // IP KAMU
  bool _isLoading = true;
  List<dynamic> _searchResults = [];

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _searchItems();
  }

  Future<void> _searchItems() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));

      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        
        // Filter Client-Side
        List<dynamic> found = allItems.where((item) {
          String itemName = item['nama'].toString().toLowerCase();
          String searchKey = widget.keyword.toLowerCase();
          return itemName.contains(searchKey);
        }).toList();

        setState(() {
          _searchResults = found;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: Text('Hasil: "${widget.keyword}"'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text('Tidak ditemukan barang "${widget.keyword}"', style: const TextStyle(color: Colors.grey)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: isHabis ? Colors.grey : Colors.black)),
                const SizedBox(height: 5),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah.format(item['harga']), style: TextStyle(color: isHabis ? Colors.grey : Colors.pink[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    if (!isService && !isHabis) 
                      Text("Stok: $stok", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 8),
                
                // TOMBOL AKSI
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      if (isService) {
                        // KE BOOKING
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingFormPage(serviceData: item, userId: widget.userId)));
                      } else {
                        // KE KERANJANG (Cek Stok Dulu)
                        int currentQty = 0;
                        try { currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty']; } catch (e) { currentQty = 0; }

                        if (currentQty >= stok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                        } else {
                          CartService.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masuk Keranjang!'), duration: Duration(seconds: 1), backgroundColor: Colors.green));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHabis ? Colors.grey : (isService ? Colors.blue : Colors.pink), 
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isHabis ? "Sold Out" : (isService ? "Booking" : "Add +"), style: const TextStyle(fontSize: 12)),
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