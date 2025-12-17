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
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU
  bool _isLoading = true;
  List<dynamic> _allBookings = [];
  
  late TabController _tabController;
  final List<String> _tabs = ['Perlu Konfirmasi', 'Jadwal Aktif', 'Selesai', 'Dibatalkan'];
  
  // Format Rupiah
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/bookings'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allBookings = json.decode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getBookingsByStatus(String tabName) {
    switch (tabName) {
      case 'Perlu Konfirmasi': return _allBookings.where((b) => b['status'] == 'pending').toList();
      case 'Jadwal Aktif': return _allBookings.where((b) => b['status'] == 'confirmed').toList();
      case 'Selesai': return _allBookings.where((b) => b['status'] == 'finished').toList();
      case 'Dibatalkan': return _allBookings.where((b) => b['status'] == 'batal').toList();
      default: return [];
    }
  }

  Future<void> _updateStatus(int id, String status, {String? reason}) async {
    try {
      await http.put(
        Uri.parse('$_apiUrl/api/admin/bookings/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'reason': reason}),
      );
      _fetchBookings(); 
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status booking diupdate!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update"), backgroundColor: Colors.red));
    }
  }

  void _showRejectDialog(int id) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tolak Booking?"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih alasan:"),
              RadioListTile(title: const Text("Jadwal Penuh"), value: "Jadwal Penuh", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
              RadioListTile(title: const Text("Petugas Berhalangan"), value: "Petugas Berhalangan", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
              RadioListTile(title: const Text("Diluar Jam Operasional"), value: "Diluar Jam Operasional", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(onPressed: () { if (selectedReason != null) { _updateStatus(id, 'batal', reason: selectedReason); Navigator.pop(ctx); } }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text("Tolak"))
        ],
      ),
    );
  }

  // --- INI FUNGSI YANG TADI ERROR KARENA GAK DIPAKE ---
  // Sekarang kita pakai buat warnain badge status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'finished': return Colors.green;
      case 'batal': return Colors.red;
      default: return Colors.grey;
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
      backgroundColor: Colors.pink[50],
      appBar: AppBar(title: const Text("Kelola Booking Jasa"), backgroundColor: Colors.pink, foregroundColor: Colors.white, elevation: 0, bottom: TabBar(controller: _tabController, isScrollable: true, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, tabs: _tabs.map((t) => Tab(text: t)).toList())),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink)) 
        : TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              final bookings = _getBookingsByStatus(tabName);
              if (bookings.isEmpty) return Center(child: Text("Tidak ada jadwal di tab $tabName"));

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
    String status = booking['status'] ?? 'pending'; // Ambil status buat warna

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    const Icon(Icons.calendar_month, color: Colors.pink, size: 20),
                    const SizedBox(width: 5),
                    Text(booking['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                // Lencana Status (Disini kita pake _getStatusColor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status))
                  ),
                  child: Text(
                    status.toUpperCase(), 
                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                )
              ],
            ),
            
            const Divider(),
            
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
                      Text(booking['service'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink)),
                      Text(formatRupiah.format(price), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Pemilik: ${booking['customer']}", style: const TextStyle(fontSize: 12)),
                      Text("Hewan: ${booking['pet']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text("Jam: ${booking['time']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
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
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Text("Alasan: $cancelReason", style: const TextStyle(color: Colors.red, fontSize: 12)),
              )
            ],
            
            const SizedBox(height: 12),
            
            // TOMBOL AKSI
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tabName == 'Perlu Konfirmasi') ...[
                  OutlinedButton(onPressed: () => _showRejectDialog(booking['id']), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Tolak")),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(onPressed: () => _updateStatus(booking['id'], 'confirmed'), icon: const Icon(Icons.check_circle, size: 16), label: const Text("Terima"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                ],

                if (tabName == 'Jadwal Aktif')
                  ElevatedButton.icon(onPressed: () => _updateStatus(booking['id'], 'finished'), icon: const Icon(Icons.done_all, size: 16), label: const Text("Selesai"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
              ],
            )
          ],
        ),
      ),
    );
  }
}