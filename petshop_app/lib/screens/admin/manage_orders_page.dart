// File: lib/screens/admin/manage_orders_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ManageOrdersPage extends StatefulWidget {
  const ManageOrdersPage({super.key});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> with SingleTickerProviderStateMixin {
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU
  bool _isLoading = true;
  List<dynamic> _allOrders = [];
  
  late TabController _tabController;
  final List<String> _tabs = ['Perlu Cek', 'Perlu Kemas', 'Dikirim', 'Selesai', 'Dibatalkan'];
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/orders'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allOrders = json.decode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getOrdersByStatus(String tabName) {
    switch (tabName) {
      case 'Perlu Cek': return _allOrders.where((o) => o['status'] == 'pending' || o['status'] == 'menunggu_pembayaran').toList();
      case 'Perlu Kemas': return _allOrders.where((o) => o['status'] == 'diproses').toList();
      case 'Dikirim': return _allOrders.where((o) => o['status'] == 'dikirim').toList();
      case 'Selesai': return _allOrders.where((o) => o['status'] == 'selesai').toList();
      case 'Dibatalkan': return _allOrders.where((o) => o['status'] == 'batal').toList();
      default: return [];
    }
  }

  Future<void> _updateStatus(int id, String status, {String? reason}) async {
    try {
      await http.put(
        Uri.parse('$_apiUrl/api/admin/orders/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'reason': reason}),
      );
      _fetchOrders(); 
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status berhasil diupdate!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status"), backgroundColor: Colors.red));
    }
  }

  void _showRejectDialog(int orderId) {
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tolak Pesanan"),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih alasan penolakan:"),
              RadioListTile(title: const Text("Stok Habis"), value: "Stok Habis", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
              RadioListTile(title: const Text("Pembayaran Tidak Valid"), value: "Pembayaran Tidak Valid", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
              RadioListTile(title: const Text("Alamat Tidak Terjangkau"), value: "Alamat Tidak Terjangkau", groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (selectedReason != null) {
                _updateStatus(orderId, 'batal', reason: selectedReason);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Tolak"),
          )
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text("Kelola Pesanan"), 
        backgroundColor: Colors.pink, 
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink))
        : TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              final orders = _getOrdersByStatus(tabName);
              if (orders.isEmpty) return Center(child: Text("Tidak ada pesanan di tab $tabName"));
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (ctx, i) => _buildOrderCard(orders[i], tabName),
              );
            }).toList(),
          ),
    );
  }

  Widget _buildOrderCard(dynamic order, String tabName) {
    String? cancelReason = order['cancel_reason'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- GAMBAR BARANG ---
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    image: _getImage(order['image']),
                    width: 70, height: 70, fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                
                // --- KONTEN TENGAH ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(order['date'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(order['customer'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(order['items'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formatRupiah.format(order['total']), style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            
            // Info Pembayaran (Hanya di tab perlu cek)
            if (tabName == 'Perlu Cek') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.payment, size: 16, color: Colors.orange),
                  const SizedBox(width: 5),
                  Text("${order['bank'] ?? '-'} (VA: ${order['va'] ?? '-'})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              )
            ],

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
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            // --- TOMBOL AKSI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tabName == 'Perlu Cek' && order['status'] == 'pending')
                  ElevatedButton(onPressed: () => _updateStatus(order['id'], 'diproses'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Terima Bayar")),
                
                if (tabName == 'Perlu Kemas')
                  ElevatedButton(onPressed: () => _updateStatus(order['id'], 'dikirim'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Kirim Barang")),

                if (tabName == 'Dikirim')
                  ElevatedButton(onPressed: () => _updateStatus(order['id'], 'selesai'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Selesai")),

                const SizedBox(width: 10),
                if (tabName == 'Perlu Cek' || tabName == 'Perlu Kemas')
                  OutlinedButton(onPressed: () => _showRejectDialog(order['id']), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Tolak")),
              ],
            )
          ],
        ),
      ),
    );
  }
}