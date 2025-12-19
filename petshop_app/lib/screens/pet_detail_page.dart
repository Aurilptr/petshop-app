// File: lib/screens/pet_detail_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'add_pet_page.dart';

class PetDetailPage extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = false;
  late Map<String, dynamic> _currentPet;

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card/Header
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
    print("[PetDetailPage] InitState. Pet: ${_currentPet['nama_hewan']}");
  }

  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }
    return const AssetImage('assets/images/pet_avatar.png');
  }

  Future<void> _deletePet() async {
    print("[PetDetailPage] Delete button clicked for ${_currentPet['nama_hewan']}");
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text('Hapus Hewan?', style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        content: Text('Yakin ingin menghapus ${_currentPet['nama_hewan']}?', style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('Batal', style: TextStyle(fontFamily: _fontFamily, color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('Hapus', style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(Uri.parse('$_apiUrl/api/pets/${_currentPet['id']}'));
      print("[PetDetailPage] Delete Response: ${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hewan berhasil dihapus.'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kembali ke profil
      } else {
        throw Exception('Gagal menghapus: ${response.statusCode}');
      }
    } catch (e) {
      print("[PetDetailPage] Delete Error: $e");
      if (!mounted) return;
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
        title: Text(_currentPet['nama_hewan'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // --- TOMBOL EDIT ---
          IconButton(
            icon: Icon(Icons.edit, color: _accentColor),
            onPressed: () async {
              print("[PetDetailPage] Edit button clicked");
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPetPage(
                    userId: _currentPet['user_id'],
                    petToEdit: _currentPet, 
                  ),
                ),
              );

              // Kalau sukses edit (result == true), kita tutup halaman detail
              // supaya halaman Profil me-refresh datanya.
              if (result == true) {
                print("[PetDetailPage] Edit successful, returning to profile.");
                if (!mounted) return;
                Navigator.pop(context, true); 
              }
            },
          ),
          // --- TOMBOL HAPUS ---
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _isLoading ? null : _deletePet,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Hero(
              tag: 'pet-${_currentPet['id']}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor, width: 4), // Border Teal
                  boxShadow: [BoxShadow(color: _accentColor.withOpacity(0.3), blurRadius: 20)]
                ),
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: _bgLight,
                  backgroundImage: _getImage(_currentPet['foto_url']),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              _currentPet['nama_hewan'], 
              style: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: _textWhite)
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accentColor.withOpacity(0.3))
              ),
              child: Text(
                _currentPet['jenis'] ?? '-', 
                style: TextStyle(fontFamily: _fontFamily, fontSize: 16, color: _accentColor, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 30),
            
            // Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgLight,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.05))
              ),
              child: Column(
                children: [
                  _buildInfoRow("Warna / Ciri", _currentPet['warna'] ?? '-'),
                  Divider(color: Colors.white.withOpacity(0.1), height: 30),
                  _buildInfoRow("Usia", _currentPet['usia'] ?? '-'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 14)),
        Text(value, style: TextStyle(fontFamily: _fontFamily, color: _textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}