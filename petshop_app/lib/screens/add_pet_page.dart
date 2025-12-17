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
  // SESUAIKAN IP
  final String _apiUrl = 'http://192.168.101.12:5000'; 

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
    // LOGIKA ISI FORM OTOMATIS (EDIT MODE)
    if (widget.petToEdit != null) {
      _namaController.text = widget.petToEdit!['nama_hewan'] ?? '';
      _warnaController.text = widget.petToEdit!['warna'] ?? '';
      _usiaController.text = widget.petToEdit!['usia'] ?? '';
      
      // Ambil foto lama (Pakai pengaman ?? '' biar ga error kalau null)
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      bool isEdit = widget.petToEdit != null;
      
      final url = isEdit 
          ? Uri.parse('$_apiUrl/api/pets/${widget.petToEdit!['id']}') // PUT (Edit)
          : Uri.parse('$_apiUrl/api/pets'); // POST (Tambah)

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

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true); // Kirim sinyal sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Data hewan diupdate!" : "Hewan berhasil didaftarkan!"))
        );
      } else {
        throw Exception('Gagal menyimpan: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.petToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Hewan" : "Tambah Peliharaan"), 
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black, 
        elevation: 1
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Pilih Avatar Lucu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              SizedBox(
                height: 90, 
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final imgPath = _avatars[index];
                    final isSelected = _selectedAvatar == imgPath;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = imgPath),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.pink, width: 3) : Border.all(color: Colors.grey.shade200),
                          color: isSelected ? Colors.pink.withOpacity(0.1) : Colors.transparent,
                        ),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(imgPath),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: "Nama Hewan", prefixIcon: const Icon(Icons.pets), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Isi nama hewan" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedJenis,
                decoration: InputDecoration(labelText: "Jenis Hewan", prefixIcon: const Icon(Icons.category), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: ['Kucing', 'Anjing', 'Hamster', 'Kelinci', 'Kura-kura', 'Burung', 'Babi']
                    .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedJenis = val!),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _warnaController,
                decoration: InputDecoration(labelText: "Warna / Ciri Khas", prefixIcon: const Icon(Icons.color_lens), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Isi ciri khas" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _usiaController,
                decoration: InputDecoration(labelText: "Usia (Contoh: 1 Tahun)", prefixIcon: const Icon(Icons.cake), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                validator: (val) => val!.isEmpty ? "Isi usia" : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPet,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(isEdit ? "UPDATE DATA" : "SIMPAN DATA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}