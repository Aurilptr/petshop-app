// File: lib/screens/tabs/services_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../booking_form_page.dart'; 

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

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[ServicesTab] InitState Called. User: ${widget.userData['nama_lengkap']}");
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    print("[ServicesTab] Fetching services list...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      print("[ServicesTab] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        List<dynamic> allItems = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Ambil hanya yang tipenya 'layanan'
            _services = allItems.where((item) => item['tipe'] == 'layanan').toList();
            _isLoading = false;
          });
          print("[ServicesTab] Loaded ${_services.length} services.");
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        print("[ServicesTab] Failed to load services.");
      }
    } catch (e) {
      print("[ServicesTab] Error fetching services: $e");
      if (mounted) setState(() => _isLoading = false);
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
      backgroundColor: _bgDark, // Background Gelap
      
      // TAMPILAN GRID 2 KOLOM
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : _services.isEmpty
              ? Center(child: Text("Belum ada layanan.", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.75, 
                  ),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: _bgLight, // Card Gelap
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // GAMBAR DI ATAS
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.multiply), 
                                child: Image(
                                  image: _getImage(service['gambar_url']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, color: _textGrey),
                                ),
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
                                  style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  formatRupiah.format(service['harga']),
                                  style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                
                                // TOMBOL BOOKING
                                SizedBox(
                                  width: double.infinity,
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      print("[ServicesTab] Booking Clicked: ${service['nama']}");
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
                                      backgroundColor: _accentColor, // Tombol Teal
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                    ),
                                    child: Text("Booking Sekarang", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.bold)),
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