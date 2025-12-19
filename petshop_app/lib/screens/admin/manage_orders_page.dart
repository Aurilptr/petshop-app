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
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  List<dynamic> _allOrders = [];
  
  late TabController _tabController;
  final List<String> _tabs = ['Perlu Cek', 'Perlu Kemas', 'Dikirim', 'Selesai', 'Dibatalkan'];
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
    print("[ManageOrders] InitState Called.");
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    print("[ManageOrders] Fetching order list...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/admin/orders'));
      print("[ManageOrders] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allOrders = json.decode(response.body);
            _isLoading = false;
          });
          print("[ManageOrders] Loaded ${_allOrders.length} orders.");
        }
      } else {
        print("[ManageOrders] Failed to load orders.");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("[ManageOrders] Error fetching orders: $e");
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
    print("[ManageOrders] Updating status ID: $id -> $status (Reason: $reason)");
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/api/admin/orders/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'reason': reason}),
      );

      print("[ManageOrders] Update Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        _fetchOrders(); 
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status berhasil diupdate!"), backgroundColor: Colors.green));
      } else {
        throw Exception("Failed to update");
      }
    } catch (e) {
      print("[ManageOrders] Error update status: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal update status"), backgroundColor: Colors.red));
    }
  }

  void _showRejectDialog(int orderId) {
    print("[ManageOrders] Show Reject Dialog for Order ID: $orderId");
    String? selectedReason;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        title: Text("Tolak Pesanan", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Pilih alasan penolakan:", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
              _buildRadioOption("Stok Habis", selectedReason, (v) => setState(() => selectedReason = v)),
              _buildRadioOption("Pembayaran Tidak Valid", selectedReason, (v) => setState(() => selectedReason = v)),
              _buildRadioOption("Alamat Tidak Terjangkau", selectedReason, (v) => setState(() => selectedReason = v)),
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
                _updateStatus(orderId, 'batal', reason: selectedReason);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text("Tolak", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
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
        title: Text("Kelola Pesanan", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
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
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor))
        : TabBarView(
            controller: _tabController,
            children: _tabs.map((tabName) {
              final orders = _getOrdersByStatus(tabName);
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 10),
                      Text("Tidak ada pesanan di tab $tabName", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                    ],
                  )
                );
              }
              
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
                          Text("Order #${order['id']}", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 14, color: _textWhite)),
                          Text(order['date'], style: TextStyle(fontFamily: _fontFamily, fontSize: 10, color: _textGrey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(order['customer'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
                      Text(order['items'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(formatRupiah.format(order['total']), style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            
            // Info Pembayaran
            if (tabName == 'Perlu Cek') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.payment, size: 16, color: Colors.orangeAccent),
                  const SizedBox(width: 5),
                  Text("${order['bank'] ?? '-'} (VA: ${order['va'] ?? '-'})", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orangeAccent)),
                ]),
              )
            ],

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
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 8),
            
            // --- TOMBOL AKSI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (tabName == 'Perlu Cek' && order['status'] == 'pending')
                  ElevatedButton(
                    onPressed: () => _updateStatus(order['id'], 'diproses'), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                    child: Text("Terima Bayar", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold))
                  ),
                
                if (tabName == 'Perlu Kemas')
                  ElevatedButton(
                    onPressed: () => _updateStatus(order['id'], 'dikirim'), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                    child: Text("Kirim Barang", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold))
                  ),

                if (tabName == 'Dikirim')
                  ElevatedButton(
                    onPressed: () => _updateStatus(order['id'], 'selesai'), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                    child: Text("Selesai", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold))
                  ),

                const SizedBox(width: 10),
                if (tabName == 'Perlu Cek' || tabName == 'Perlu Kemas')
                  OutlinedButton(
                    onPressed: () => _showRejectDialog(order['id']), 
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), 
                    child: Text("Tolak", style: TextStyle(fontFamily: _fontFamily))
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}