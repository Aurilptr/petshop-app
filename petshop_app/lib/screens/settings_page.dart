// File: lib/screens/settings_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  final int userId;

  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // IP KAMU
  final String _apiUrl = 'http://192.168.101.12:5000';

  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // Controller untuk Form
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. Ambil Data User Terbaru dari Database
  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${widget.userId}'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _namaController.text = data['nama_lengkap'] ?? '';
          _emailController.text = data['email'] ?? '';
          _hpController.text = data['no_hp'] ?? '';
          _alamatController.text = data['alamat'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data profil")));
      setState(() => _isLoading = false);
    }
  }

  // 2. Simpan Data (Update)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/api/users/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_lengkap': _namaController.text,
          'no_hp': _hpController.text,
          'alamat': _alamatController.text,
          // Email biasanya tidak boleh diganti sembarangan, jadi tidak kita kirim
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil disimpan! ✅"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke menu profil
      } else {
        throw Exception('Gagal update');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Akun"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Informasi Pribadi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // --- NAMA LENGKAP ---
                    TextFormField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val!.isEmpty ? "Nama tidak boleh kosong" : null,
                    ),
                    const SizedBox(height: 15),

                    // --- EMAIL (Read Only) ---
                    TextFormField(
                      controller: _emailController,
                      readOnly: true, // Tidak bisa diedit
                      decoration: InputDecoration(
                        labelText: "Email (Tidak bisa diubah)",
                        prefixIcon: const Icon(Icons.email_outlined),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- NO HP ---
                    TextFormField(
                      controller: _hpController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Nomor WhatsApp / HP",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: "08xxxxxxxxxx",
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text("Alamat Pengiriman", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // --- ALAMAT ---
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 3, // Kotak lebih besar
                      decoration: InputDecoration(
                        labelText: "Alamat Lengkap",
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40), // Biar ikon ada di atas
                          child: Icon(Icons.location_on_outlined),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: "Jalan, No Rumah, Kelurahan, Kecamatan...",
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("SIMPAN PERUBAHAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}