// File: lib/screens/admin/manage_bookings_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> with SingleTickerProviderStateMixin {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  List<dynamic> _allBookings = [];
  
  late TabController _tabController;
  final List<String> _tabs = ['Perlu Konfirmasi', 'Jadwal Aktif', 'Selesai', 'Dibatalkan'];
  
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
    print("[ManageBookings] InitState Called.");
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    print("[ManageBookings] Fetching booking list...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/bookings'));
      print("[ManageBookings] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allBookings = json.decode(response.body);
            _isLoading = false;
          });
          print("[ManageBookings] Loaded ${_allBookings.length} bookings.");
        }
      } else {
        print("[ManageBookings] Failed to load bookings.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[ManageBookings] Error fetching bookings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getBookingsByStatus(String tabName) {
    switch (tabName) {
      case 'Perlu Konfirmasi':
        return _allBookings.where((b) => 
            b['status'] == 'pending' || 
            b['status'] == 'menunggu_pembayaran' || 
            b['status'] == 'diproses'
        ).toList();
        
      case 'Jadwal Aktif':
        return _allBookings.where((b) => 
            b['status'] == 'confirmed' || 
            b['status'] == 'diterima'
        ).toList();
        
      case 'Selesai':
        return _allBookings.where((b) => 
            b['status'] == 'finished' || 
            b['status'] == 'selesai'
        ).toList();
        
      case 'Dibatalkan':
        return _allBookings.where((b) => b['status'] == 'batal').toList();
        
      default:
        return [];
    }
  }

  Future<void> _updateStatus(int id, String status, {String? reason}) async {
    print("[ManageBookings] Updating status ID: $id -> $status (Reason: $reason)");
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/api/admin/bookings/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'reason': reason}),
      );

      print("[ManageBookings] Update Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        _fetchBookings(); 
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status booking diupdate!"), backgroundColor: Colors.green));
      } else {
        throw Exception("Failed to update");
      }
    } catch (e) {
      print("[ManageBookings] Error update status: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update"), backgroundColor: Colors.red));
    }
  }

  void _showRejectDialog(int id) {
    print("[ManageBookings] Show Reject Dialog for ID: $id");
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text("Tolak Booking?", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pilih alasan:", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
              _buildRadioOption("Jadwal Penuh", selectedReason, (v) => setState(() => selectedReason = v)),
              _buildRadioOption("Petugas Berhalangan", selectedReason, (v) => setState(() => selectedReason = v)),
              _buildRadioOption("Diluar Jam Operasional", selectedReason, (v) => setState(() => selectedReason = v)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text("Batal", style: TextStyle(fontFamily: _fontFamily, color: _textGrey))
          ),
          ElevatedButton(
            onPressed: () { 
              if (selectedReason != null) { 
                _updateStatus(id, 'batal', reason: selectedReason); 
                Navigator.pop(ctx); 
              } 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), 
            child: Text("Tolak", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String? groupValue, Function(String?) onChanged) {
    return RadioListTile<String>(
      title: Text(value, style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
      value: value,
      groupValue: groupValue,
      activeColor: _accentColor,
      onChanged: onChanged,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orangeAccent;
      case 'confirmed': return Colors.blueAccent;
      case 'finished': return Colors.greenAccent;
      case 'batal': return Colors.redAccent;
      default: return _textGrey;
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
      appBar: AppBar(
        title: Text("Kelola Booking Jasa", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: _accentColor,
          labelColor: _accentColor,
          labelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          unselectedLabelColor: _textGrey,
          unselectedLabelStyle: TextStyle(fontFamily: _fontFamily),
          tabs: _tabs.map((t) => Tab(text: t)).toList()
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor)) 
        : TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              final bookings = _getBookingsByStatus(tabName);
              if (bookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 60, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 10),
                      Text("Tidak ada jadwal di tab $tabName", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                    ],
                  )
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (ctx, i) => _buildBookingCard(bookings[i], tabName),
              );
            }).toList(),
          ),
    );
  }

  Widget _buildBookingCard(dynamic booking, String tabName) {
    String? cancelReason = booking['cancel_reason'];
    int price = booking['price'] ?? 0;
    String status = booking['status'] ?? 'pending'; 

    return Card(
      color: _bgLight, // Card Gelap
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withOpacity(0.05))
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- HEADER: TANGGAL & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: _accentColor, size: 20),
                    const SizedBox(width: 5),
                    Text(booking['date'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14, color: _textWhite)),
                  ],
                ),
                // Lencana Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status).withOpacity(0.5))
                  ),
                  child: Text(
                    status.toUpperCase(), 
                    style: TextStyle(fontFamily: _fontFamily, color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                )
              ],
            ),
            
            Divider(color: Colors.white.withOpacity(0.1)),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Layanan
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(image: _getImage(booking['image']), width: 70, height: 70, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                
                // Info Utama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['service'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
                      Text(formatRupiah.format(price), style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Pemilik: ${booking['customer']}", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
                      Text("Hewan: ${booking['pet']}", style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)),
                      
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text("Jam: ${booking['time']}", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent)),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
            
            // Alasan Penolakan
            if (tabName == 'Dibatalkan' && cancelReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))),
                child: Text("Alasan: $cancelReason", style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontSize: 12)),
              )
            ],
            
            const SizedBox(height: 12),
            
            // TOMBOL AKSI
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tabName == 'Perlu Konfirmasi') ...[
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(booking['id']), 
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent, 
                      side: const BorderSide(color: Colors.redAccent), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ), 
                    child: Text("Tolak", style: TextStyle(fontFamily: _fontFamily))
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(booking['id'], 'confirmed'), 
                    icon: const Icon(Icons.check_circle, size: 16), 
                    label: Text("Terima", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))
                  ),
                ],

                if (tabName == 'Jadwal Aktif')
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(booking['id'], 'finished'), 
                    icon: const Icon(Icons.done_all, size: 16), 
                    label: Text("Selesai", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}