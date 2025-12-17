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
  // SESUAIKAN IP
  final String _apiUrl = 'http://192.168.101.12:5000'; 
  bool _isLoading = false;
  late Map<String, dynamic> _currentPet;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
  }

  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }
    return const AssetImage('assets/images/pet_avatar.png');
  }

  Future<void> _deletePet() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Hewan?'),
        content: Text('Yakin ingin menghapus ${_currentPet['nama_hewan']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(Uri.parse('$_apiUrl/api/pets/${_currentPet['id']}'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hewan berhasil dihapus.'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kembali ke profil
      } else {
        throw Exception('Gagal menghapus: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPet['nama_hewan']),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          // --- TOMBOL EDIT ---
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // KITA KIRIM DATA LAMA (_currentPet) KE HALAMAN EDIT
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPetPage(
                    userId: _currentPet['user_id'],
                    petToEdit: _currentPet, // <--- INI KUNCINYA
                  ),
                ),
              );

              // Kalau sukses edit (result == true), kita tutup halaman detail
              // supaya halaman Profil me-refresh datanya.
              if (result == true) {
                if (!mounted) return;
                Navigator.pop(context, true); 
              }
            },
          ),
          // --- TOMBOL HAPUS ---
          IconButton(
            icon: const Icon(Icons.delete),
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
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.pink[100],
                backgroundImage: _getImage(_currentPet['foto_url']),
              ),
            ),
            const SizedBox(height: 20),
            Text(_currentPet['nama_hewan'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(20)),
              child: Text(_currentPet['jenis'] ?? '-', style: TextStyle(fontSize: 16, color: Colors.orange[800], fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Text("Warna: ${_currentPet['warna'] ?? '-'}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 5),
            Text("Usia: ${_currentPet['usia'] ?? '-'}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}