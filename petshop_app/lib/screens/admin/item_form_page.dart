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

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;
  final Color _inputFill = Colors.white.withOpacity(0.05); // Glass Input

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

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
    print("[ItemForm] InitState. Edit Mode: ${widget.itemToEdit != null}");
    
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
    print("[ItemForm] Submit button clicked.");
    if (!_formKey.currentState!.validate()) {
      print("[ItemForm] Validation failed.");
      return;
    }
    
    setState(() => _isLoading = true);

    final body = json.encode({
      'nama': _namaController.text,
      'tipe': _selectedTipe,
      'harga': int.parse(_hargaController.text),
      'stok': int.parse(_stokController.text),
      'deskripsi': _deskripsiController.text,
      'gambar_url': _gambarUrl
    });

    print("[ItemForm] Sending Data: $body");

    try {
      final isEdit = widget.itemToEdit != null;
      final url = isEdit 
          ? Uri.parse('$_apiUrl/api/items/${widget.itemToEdit!['id']}')
          : Uri.parse('$_apiUrl/api/items');

      print("[ItemForm] Request URL: $url");

      final response = await (isEdit 
          ? http.put(url, headers: {'Content-Type': 'application/json'}, body: body)
          : http.post(url, headers: {'Content-Type': 'application/json'}, body: body));

      print("[ItemForm] Response Status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Item diupdate!' : 'Item ditambahkan!'), backgroundColor: Colors.green)
        );
      } else {
        throw Exception('Gagal menyimpan data: ${response.statusCode}');
      }
    } catch (e) {
      print("[ItemForm] Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text(widget.itemToEdit != null ? "Edit Item" : "Tambah Item", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pilih Gambar:", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 10),
              
              // IMAGE SELECTOR
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _assetImages.length,
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () {
                      print("[ItemForm] Image selected: ${_assetImages[i]}");
                      setState(() => _gambarUrl = _assetImages[i]);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _gambarUrl == _assetImages[i] ? _accentColor : Colors.white.withOpacity(0.1), 
                          width: 3
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: _bgLight,
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.asset(_assetImages[i], width: 70, fit: BoxFit.cover)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // NAMA BARANG
              _buildDarkInput(_namaController, "Nama Barang / Layanan", Icons.label),
              const SizedBox(height: 15),

              // DROPDOWN TIPE
              DropdownButtonFormField<String>(
                value: _selectedTipe,
                dropdownColor: _bgLight, // Dropdown Gelap
                style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Tipe",
                  labelStyle: TextStyle(fontFamily: _fontFamily, color: _textGrey),
                  prefixIcon: Icon(Icons.category, color: _accentColor),
                  filled: true,
                  fillColor: _inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
                ),
                items: ['produk', 'layanan'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _selectedTipe = val!),
              ),
              const SizedBox(height: 15),

              // HARGA & STOK (Row)
              Row(
                children: [
                  Expanded(
                    child: _buildDarkInput(_hargaController, "Harga (Rp)", Icons.money, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDarkInput(_stokController, "Stok", Icons.inventory, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // DESKRIPSI
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Deskripsi Singkat",
                  labelStyle: TextStyle(fontFamily: _fontFamily, color: _textGrey),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description, color: _accentColor),
                  ),
                  filled: true,
                  fillColor: _inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
                ),
              ),
              const SizedBox(height: 30),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor, // Teal Button
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: _accentColor.withOpacity(0.4)
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text("SIMPAN DATA", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper: Input Field Gelap
  Widget _buildDarkInput(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: _fontFamily, color: _textGrey),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
      ),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
    );
  }
}