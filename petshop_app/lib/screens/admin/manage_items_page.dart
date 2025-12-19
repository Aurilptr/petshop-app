// File: lib/screens/admin/manage_items_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'item_form_page.dart';

class ManageItemsPage extends StatefulWidget {
  const ManageItemsPage({super.key});

  @override
  State<ManageItemsPage> createState() => _ManageItemsPageState();
}

class _ManageItemsPageState extends State<ManageItemsPage> {
  final String _apiUrl = 'http://127.0.0.1:5000';
  bool _isLoading = true;
  List<dynamic> _items = [];
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
    print("[ManageItems] InitState Called.");
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    print("[ManageItems] Fetching items list...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      print("[ManageItems] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _items = json.decode(response.body);
            _isLoading = false;
          });
          print("[ManageItems] Loaded ${_items.length} items.");
        }
      } else {
        print("[ManageItems] Failed to load items.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[ManageItems] Error fetching items: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    print("[ManageItems] Request delete item ID: $id");
    
    // Dialog Konfirmasi (Dark Theme)
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text("Hapus Item?", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        content: Text("Item ini akan dihapus permanen.", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: Text("Batal", style: TextStyle(fontFamily: _fontFamily, color: _textGrey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text("Hapus", style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(Uri.parse('$_apiUrl/api/items/$id'));
      print("[ManageItems] Delete Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        _fetchItems();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dihapus"), backgroundColor: Colors.green));
      } else {
        throw Exception("Gagal menghapus");
      }
    } catch (e) {
      print("[ManageItems] Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Kelola Produk & Jasa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor, // Tombol Tambah Teal
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          print("[ManageItems] Navigating to Add Item Page");
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemFormPage()));
          _fetchItems();
        },
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor)) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                color: _bgLight, // Card Gelap
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.white.withOpacity(0.05))
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      item['gambar_url'] ?? 'assets/images/pet_avatar.png', 
                      width: 60, 
                      height: 60, 
                      fit: BoxFit.cover, 
                      errorBuilder: (c,e,s) => const Icon(Icons.image, size: 50, color: Colors.grey)
                    ),
                  ),
                  title: Text(item['nama'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _accentColor.withOpacity(0.5))
                            ),
                            child: Text(
                              item['tipe'].toString().toUpperCase(), 
                              style: TextStyle(fontFamily: _fontFamily, fontSize: 10, color: _accentColor, fontWeight: FontWeight.bold)
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("Stok: ${item['stok']}", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(formatRupiah.format(item['harga']), style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () async {
                          print("[ManageItems] Edit item: ${item['nama']}");
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => ItemFormPage(itemToEdit: item)));
                          _fetchItems();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteItem(item['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}