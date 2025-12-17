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
  final String _apiUrl = 'http://192.168.101.12:5000';
  bool _isLoading = true;
  List<dynamic> _items = [];
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      if (response.statusCode == 200) {
        if (mounted) setState(() { _items = json.decode(response.body); _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Item?"),
        content: const Text("Item ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(Uri.parse('$_apiUrl/api/items/$id'));
      if (response.statusCode == 200) {
        _fetchItems();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dihapus"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(title: const Text("Kelola Produk & Jasa"), backgroundColor: Colors.pink, foregroundColor: Colors.white, elevation: 0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemFormPage()));
          _fetchItems();
        },
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink)) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(item['gambar_url'] ?? 'assets/images/pet_avatar.png', width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
                  title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['tipe'].toUpperCase()} • Stok: ${item['stok']}\n${formatRupiah.format(item['harga'])}", style: TextStyle(color: Colors.pink[400], fontWeight: FontWeight.bold)),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => ItemFormPage(itemToEdit: item)));
                          _fetchItems();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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