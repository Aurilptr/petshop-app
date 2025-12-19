// File: lib/screens/add_pet_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPetPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? petToEdit; 

  const AddPetPage({super.key, required this.userId, this.petToEdit});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _warnaController = TextEditingController();
  final _usiaController = TextEditingController();
  
  String _selectedJenis = 'Kucing';
  String _selectedAvatar = 'assets/images/cat_avatar.jpeg'; 
  
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

  final List<String> _avatars = [
    'assets/images/cat_avatar.jpeg',
    'assets/images/dog_avatar.jpeg',
    'assets/images/hamster_avatar.jpeg',
    'assets/images/rabbit_avatar.jpeg',
    'assets/images/turtle_avatar.jpeg',
    'assets/images/bird_avatar.jpeg',
    'assets/images/pig_avatar.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    print("[AddPetPage] InitState Called. Edit Mode: ${widget.petToEdit != null}");
    
    // LOGIKA ISI FORM OTOMATIS (EDIT MODE)
    if (widget.petToEdit != null) {
      _namaController.text = widget.petToEdit!['nama_hewan'] ?? '';
      _warnaController.text = widget.petToEdit!['warna'] ?? '';
      _usiaController.text = widget.petToEdit!['usia'] ?? '';
      
      String fotoLama = widget.petToEdit!['foto_url'] ?? '';
      if (fotoLama.isNotEmpty && _avatars.contains(fotoLama)) {
        _selectedAvatar = fotoLama;
      } else {
        _selectedAvatar = 'assets/images/cat_avatar.jpeg';
      }

      String jenisDb = widget.petToEdit!['jenis'] ?? 'Kucing';
      List<String> opsi = ['Kucing', 'Anjing', 'Kelinci', 'Hamster', 'Burung', 'Kura-kura', 'Babi'];
      if (opsi.contains(jenisDb)) {
        _selectedJenis = jenisDb;
      }
    }
  }

  Future<void> _submitPet() async {
    print("[AddPetPage] Submit button clicked.");
    if (!_formKey.currentState!.validate()) {
      print("[AddPetPage] Validation failed.");
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      bool isEdit = widget.petToEdit != null;
      
      final url = isEdit 
          ? Uri.parse('$_apiUrl/api/pets/${widget.petToEdit!['id']}') // PUT (Edit)
          : Uri.parse('$_apiUrl/api/pets'); // POST (Tambah)

      print("[AddPetPage] Sending request to: $url");

      final body = json.encode({
        'user_id': widget.userId,
        'nama_hewan': _namaController.text,
        'jenis': _selectedJenis,
        'warna': _warnaController.text,
        'usia': _usiaController.text,
        'foto_url': _selectedAvatar 
      });

      final response = await (isEdit 
          ? http.put(url, headers: {'Content-Type': 'application/json'}, body: body)
          : http.post(url, headers: {'Content-Type': 'application/json'}, body: body));

      print("[AddPetPage] Response Status: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[AddPetPage] Success!");
        Navigator.pop(context, true); // Kirim sinyal sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Data hewan diupdate!" : "Hewan berhasil didaftarkan!"), backgroundColor: Colors.green)
        );
      } else {
        print("[AddPetPage] Failed: ${response.body}");
        throw Exception('Gagal menyimpan: ${response.statusCode}');
      }
    } catch (e) {
      print("[AddPetPage] Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.petToEdit != null;

    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text(isEdit ? "Edit Hewan" : "Tambah Peliharaan", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)), 
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
            children: [
              Text("Pilih Avatar Lucu:", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
              const SizedBox(height: 15),
              
              // AVATAR SELECTOR
              SizedBox(
                height: 90, 
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final imgPath = _avatars[index];
                    final isSelected = _selectedAvatar == imgPath;
                    return GestureDetector(
                      onTap: () {
                        print("[AddPetPage] Avatar selected: $imgPath");
                        setState(() => _selectedAvatar = imgPath);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: _accentColor, width: 3) : Border.all(color: Colors.white.withOpacity(0.2)),
                          color: isSelected ? _accentColor.withOpacity(0.2) : Colors.transparent,
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          backgroundImage: AssetImage(imgPath),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // INPUT FIELDS (Dark Glass Style)
              _buildDarkInput(_namaController, "Nama Hewan", Icons.pets),
              const SizedBox(height: 15),

              _buildDarkDropdown(),
              const SizedBox(height: 15),

              _buildDarkInput(_warnaController, "Warna / Ciri Khas", Icons.color_lens),
              const SizedBox(height: 15),

              _buildDarkInput(_usiaController, "Usia (Contoh: 1 Tahun)", Icons.cake),
              const SizedBox(height: 40),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor, // Teal Button
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    shadowColor: _accentColor.withOpacity(0.4)
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(isEdit ? "UPDATE DATA" : "SIMPAN DATA", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget: Input Field Gelap
  Widget _buildDarkInput(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white54),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
      ),
      validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
    );
  }

  // Helper Widget: Dropdown Gelap
  Widget _buildDarkDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedJenis,
      dropdownColor: _bgLight, // Warna dropdown menu saat dibuka
      style: TextStyle(fontFamily: _fontFamily, color: Colors.white),
      decoration: InputDecoration(
        labelText: "Jenis Hewan",
        labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white54),
        prefixIcon: Icon(Icons.category, color: _accentColor),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
      ),
      items: ['Kucing', 'Anjing', 'Hamster', 'Kelinci', 'Kura-kura', 'Burung', 'Babi']
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      onChanged: (val) {
        print("[AddPetPage] Type changed to: $val");
        setState(() => _selectedJenis = val!);
      },
    );
  }
}