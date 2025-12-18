// File: lib/screens/admin/item_form_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ItemFormPage extends StatefulWidget {
  final Map<String, dynamic>? itemToEdit;

  const ItemFormPage({super.key, this.itemToEdit});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _deskripsiController = TextEditingController();
  
  String _selectedTipe = 'produk';
  String _gambarUrl = 'assets/images/whiskas.jpeg'; 
  bool _isLoading = false;
  final String _apiUrl = 'http://127.0.0.1:5000'; 

  final List<String> _assetImages = [
    'assets/images/whiskas.jpeg', 'assets/images/royal_canin.jpeg',
    'assets/images/shampoo.jpeg', 'assets/images/kandang.jpeg',
    'assets/images/kalung.jpeg', 'assets/images/grooming.jpeg',
    'assets/images/hotel_pet.jpeg', 'assets/images/vaksin.jpeg',
    'assets/images/cat_avatar.jpeg', 'assets/images/dog_avatar.jpeg'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      _namaController.text = widget.itemToEdit!['nama'];
      _hargaController.text = widget.itemToEdit!['harga'].toString();
      _stokController.text = widget.itemToEdit!['stok'].toString();
      _deskripsiController.text = widget.itemToEdit!['deskripsi'] ?? '';
      _selectedTipe = widget.itemToEdit!['tipe'];
      _gambarUrl = widget.itemToEdit!['gambar_url'] ?? _gambarUrl;
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final body = json.encode({
      'nama': _namaController.text,
      'tipe': _selectedTipe,
      'harga': int.parse(_hargaController.text),
      'stok': int.parse(_stokController.text),
      'deskripsi': _deskripsiController.text,
      'gambar_url': _gambarUrl
    });

    try {
      final isEdit = widget.itemToEdit != null;
      final url = isEdit 
          ? Uri.parse('$_apiUrl/api/items/${widget.itemToEdit!['id']}')
          : Uri.parse('$_apiUrl/api/items');

      final response = await (isEdit 
          ? http.put(url, headers: {'Content-Type': 'application/json'}, body: body)
          : http.post(url, headers: {'Content-Type': 'application/json'}, body: body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Item diupdate!' : 'Item ditambahkan!'), backgroundColor: Colors.green));
      } else {
        throw Exception('Gagal menyimpan data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(widget.itemToEdit != null ? "Edit Item" : "Tambah Item"), backgroundColor: Colors.pink, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pilih Gambar:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _assetImages.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => setState(() => _gambarUrl = _assetImages[i]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(color: _gambarUrl == _assetImages[i] ? Colors.pink : Colors.grey.shade300, width: 3),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset(_assetImages[i], width: 70, fit: BoxFit.cover)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: "Nama Barang / Layanan", prefixIcon: const Icon(Icons.label, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedTipe,
                decoration: InputDecoration(labelText: "Tipe", prefixIcon: const Icon(Icons.category, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: ['produk', 'layanan'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _selectedTipe = val!),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Harga (Rp)", prefixIcon: const Icon(Icons.money, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      validator: (val) => val!.isEmpty ? "Isi harga" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Stok", prefixIcon: const Icon(Icons.inventory, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      validator: (val) => val!.isEmpty ? "Isi stok" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: InputDecoration(labelText: "Deskripsi Singkat", prefixIcon: const Icon(Icons.description, color: Colors.pink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SIMPAN DATA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}