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
  final String _apiUrl = 'http://127.0.0.1:5000';

  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;
  final Color _inputFill = Colors.white.withOpacity(0.05); // Glass Input

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[SettingsPage] InitState. User ID: ${widget.userId}");
    _fetchUserData();
  }

  // 1. Ambil Data User Terbaru dari Database
  Future<void> _fetchUserData() async {
    print("[SettingsPage] Fetching user profile...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/users/${widget.userId}'));
      print("[SettingsPage] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _namaController.text = data['nama_lengkap'] ?? '';
            _emailController.text = data['email'] ?? '';
            _hpController.text = data['no_hp'] ?? '';
            _alamatController.text = data['alamat'] ?? '';
            _isLoading = false;
          });
          print("[SettingsPage] User data loaded: ${data['nama_lengkap']}");
        }
      }
    } catch (e) {
      print("[SettingsPage] Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat data profil"), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Simpan Data (Update)
  Future<void> _saveProfile() async {
    print("[SettingsPage] Save Profile button clicked.");
    if (!_formKey.currentState!.validate()) {
      print("[SettingsPage] Validation failed.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bodyData = {
        'nama_lengkap': _namaController.text,
        'no_hp': _hpController.text,
        'alamat': _alamatController.text,
      };

      print("[SettingsPage] Sending update request: $bodyData");

      final response = await http.put(
        Uri.parse('$_apiUrl/api/users/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData),
      );

      print("[SettingsPage] Update Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil disimpan! ✅"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Kembali ke menu profil
      } else {
        throw Exception('Gagal update profile.');
      }
    } catch (e) {
      print("[SettingsPage] Error saving profile: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Pengaturan Akun", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Informasi Pribadi", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite)),
                    const SizedBox(height: 20),
                    
                    // --- NAMA LENGKAP ---
                    _buildDarkInput(
                      controller: _namaController,
                      label: "Nama Lengkap",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 15),

                    // --- EMAIL (Read Only) ---
                    TextFormField(
                      controller: _emailController,
                      readOnly: true, // Tidak bisa diedit
                      style: TextStyle(fontFamily: _fontFamily, color: Colors.white54), // Teks agak redup
                      decoration: InputDecoration(
                        labelText: "Email (Tidak bisa diubah)",
                        labelStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white30),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white30),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2), // Lebih gelap dari input biasa
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- NO HP ---
                    _buildDarkInput(
                      controller: _hpController,
                      label: "Nomor WhatsApp / HP",
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      hint: "08xxxxxxxxxx",
                    ),
                    const SizedBox(height: 30),

                    Text("Alamat Pengiriman", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite)),
                    const SizedBox(height: 20),

                    // --- ALAMAT ---
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 3, 
                      style: TextStyle(fontFamily: _fontFamily, color: _textWhite),
                      decoration: InputDecoration(
                        labelText: "Alamat Lengkap",
                        labelStyle: TextStyle(fontFamily: _fontFamily, color: _textGrey),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40), 
                          child: Icon(Icons.location_on_outlined, color: _accentColor),
                        ),
                        filled: true,
                        fillColor: _inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
                        hintText: "Jalan, No Rumah, Kelurahan, Kecamatan...",
                        hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white24),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor, // Tombol Teal
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                          shadowColor: _accentColor.withOpacity(0.4),
                        ),
                        child: Text("SIMPAN PERUBAHAN", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget Helper: Input Field Gelap
  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontFamily: _fontFamily, color: _textWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: _fontFamily, color: _textGrey),
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: _inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor)),
        hintText: hint,
        hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white24),
      ),
      validator: (val) => val!.isEmpty ? "$label tidak boleh kosong" : null,
    );
  }
}