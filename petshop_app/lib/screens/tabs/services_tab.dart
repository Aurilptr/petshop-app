// File: lib/screens/tabs/services_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../booking_form_page.dart'; // Pastikan file ini ada

class ServicesTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ServicesTab({super.key, required this.userData});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  List<dynamic> _services = [];

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        setState(() {
          // Ambil hanya yang tipenya 'layanan'
          _services = allItems.where((item) => item['tipe'] == 'layanan').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }
    return const AssetImage('assets/images/pet_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // TAMPILAN GRID 2 KOLOM (KAYA MARKETPLACE)
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text("Belum ada layanan."))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Kolom
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75, // Perbandingan lebar:tinggi
                  ),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: Border.all(color: Colors.pink.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // GAMBAR DI ATAS
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: Image(
                                image: _getImage(service['gambar_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // TEXT DI BAWAH
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service['nama'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formatRupiah.format(service['harga']),
                                  style: TextStyle(color: Colors.pink[600], fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                // TOMBOL BOOKING
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // KE HALAMAN FORMULIR
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingFormPage(
                                            serviceData: service,
                                            userId: widget.userData['id'],
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text("Booking Sekarang", style: TextStyle(fontSize: 12)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}