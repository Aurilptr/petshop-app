// File: lib/screens/tabs/orders_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../payment_page.dart'; 

class OrdersTab extends StatefulWidget {
  final int userId;
  const OrdersTab({super.key, required this.userId});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  
  late TabController _tabController;
  bool _isLoading = true;
  
  List<dynamic> _productOrders = [];
  List<dynamic> _bookingOrders = [];

  // Format Rupiah
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT SETTING ---
  final String _fontFamily = 'Helvetica'; // Diubah ke Helvetica

  @override
  void initState() {
    super.initState();
    print("[OrdersTab] InitState Called. User ID: ${widget.userId}");
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  // --- TARIK DATA DARI SERVER ---
  Future<void> _fetchAllData() async {
    print("[OrdersTab] Fetching all orders & bookings...");
    if(mounted) setState(() => _isLoading = true);
    await Future.wait([_fetchOrders(), _fetchBookings()]);
    if(mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await http.get(Uri.parse('$_apiUrl/api/orders/user/${widget.userId}'));
      print("[OrdersTab] Orders API Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        if(mounted) setState(() => _productOrders = json.decode(res.body));
        print("[OrdersTab] Loaded ${_productOrders.length} product orders.");
      }
    } catch (e) {
      debugPrint("[OrdersTab] Error fetching orders: $e");
    }
  }

  Future<void> _fetchBookings() async {
    try {
      final res = await http.get(Uri.parse('$_apiUrl/api/bookings/user/${widget.userId}'));
      print("[OrdersTab] Bookings API Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        if(mounted) setState(() => _bookingOrders = json.decode(res.body));
        print("[OrdersTab] Loaded ${_bookingOrders.length} bookings.");
      }
    } catch (e) {
      debugPrint("[OrdersTab] Error fetching bookings: $e");
    }
  }

  // --- NAVIGASI KE PEMBAYARAN ---
  void _goToPayment(int id, String type, int amount, String bank, String va) async {
    print("[OrdersTab] Navigate to Payment. ID: $id, Type: $type, Amount: $amount");
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(
      orderId: id,
      totalHarga: amount, 
      bankName: bank, 
      vaNumber: va,
      transactionType: type,
    )));
    _fetchAllData(); 
  }

  // --- LOGIKA BATALKAN ---
  Future<void> _cancelTransaction(int id, String type) async {
    print("[OrdersTab] Request cancel transaction ID: $id ($type)");
    
    List<String> reasons = type == 'booking' 
      ? ["Jadwal tidak cocok", "Hewan sakit", "Ganti layanan", "Lainnya"]
      : ["Ingin ubah pesanan", "Salah beli", "Lainnya"];

    String? finalReason = await _showCancellationDialog(reasons);
    if (finalReason == null) return;

    print("[OrdersTab] Confirmed Cancel Reason: $finalReason");

    String endpoint = type == 'order' ? 'orders' : 'bookings';
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/api/$endpoint/$id/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': finalReason}),
      );
      
      if (response.statusCode == 200) {
        print("[OrdersTab] Cancel Success");
        _fetchAllData();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dibatalkan"), backgroundColor: Colors.green));
      } else {
        print("[OrdersTab] Cancel Failed: ${response.statusCode}");
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membatalkan"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("[OrdersTab] Cancel Error: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error koneksi"), backgroundColor: Colors.red));
    }
  }

  Future<String?> _showCancellationDialog(List<String> reasonList) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String tempSelected = reasonList[0];
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: _bgLight, 
              title: Text("Alasan Pembatalan", style: TextStyle(color: Colors.white, fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasonList.map((r) => RadioListTile<String>(
                  title: Text(r, style: const TextStyle(color: Colors.white70)), 
                  value: r, 
                  groupValue: tempSelected,
                  activeColor: _accentColor,
                  onChanged: (val) => setState(() => tempSelected = val!),
                )).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("Kembali", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: Text("Konfirmasi", style: TextStyle(color: Colors.white, fontFamily: _fontFamily)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, 
      appBar: AppBar(
        title: Text("Pesanan Saya", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accentColor,
          indicatorColor: _accentColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "Barang"), Tab(text: "Jasa (Booking)")],
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor)) 
        : TabBarView(
          controller: _tabController,
          children: [
            _buildList(_productOrders, 'order'),
            _buildList(_bookingOrders, 'booking'),
          ],
        ),
    );
  }

  Widget _buildList(List<dynamic> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 10),
            Text("Belum ada riwayat $type", style: TextStyle(color: _textGrey, fontFamily: _fontFamily)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: _accentColor,
      backgroundColor: _bgLight,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final status = item['status'] ?? 'pending';
          
          bool isUnpaid = (status == 'menunggu_pembayaran');
          bool canCancel = (status == 'menunggu_pembayaran' || status == 'menunggu_konfirmasi' || status == 'pending');

          String title;
          String subtitle;

          if (type == 'order') {
            title = "Order #${item['id']}";
            var rawItems = item['items'];
            if (rawItems is List) {
              subtitle = rawItems.join(", ");
            } else if (rawItems is String) {
              subtitle = rawItems;
            } else {
              subtitle = "Barang Petshop";
            }
          } else {
            title = item['service_name'] ?? 'Layanan';
            subtitle = "${item['pet_name'] ?? '-'} (${item['pet_type'] ?? '-'})";
          }
          
          int price = type == 'order' ? (item['total_harga'] ?? 0) : (item['total_harga'] ?? item['price'] ?? 0);
          String dateStr = item['booking_date'] ?? item['date'] ?? '-';
          String timeStr = item['booking_time'] ?? ''; 
          
          String? imgUrl = type == 'booking' 
              ? item['image_url'] 
              : (item['image'] ?? item['gambar_url'] ?? item['product_image']);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _bgLight, 
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.white.withOpacity(0.05))
            ),
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        type == 'booking' ? "$dateStr • $timeStr" : dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      _statusBadge(status),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.1)),

                // CONTENT UTAMA
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.white.withOpacity(0.05), 
                          child: Builder(
                            builder: (context) {
                              if (imgUrl == null || imgUrl.isEmpty) {
                                return Icon(Icons.pets, color: _accentColor, size: 40);
                              }
                              if (imgUrl.startsWith('http')) {
                                return Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              }
                              return Image.asset(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) {
                                  return Icon(Icons.pets, color: _accentColor, size: 40);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah.format(price),
                              style: TextStyle(fontFamily: _fontFamily, fontSize: 15, fontWeight: FontWeight.bold, color: _accentColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: _textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // FOOTER ALASAN BATAL
                if (status == 'batal' && item['cancel_reason'] != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text("Alasan: ${item['cancel_reason']}", style: TextStyle(fontSize: 12, color: Colors.red[200], fontStyle: FontStyle.italic)),
                  ),

                // TOMBOL AKSI
                if (canCancel || isUnpaid)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canCancel)
                          SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () => _cancelTransaction(item['id'], type),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text("Batalkan", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (isUnpaid) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () => _goToPayment(item['id'], type, price, item['bank_name'] ?? 'Bank', item['va_number'] ?? '-'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentColor, 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text("Bayar Sekarang", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ]
                      ],
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'menunggu_pembayaran': color = Colors.orangeAccent; text = "BELUM BAYAR"; break;
      case 'menunggu_konfirmasi': color = Colors.lightBlueAccent; text = "MENUNGGU KONF."; break;
      case 'diproses': color = Colors.cyanAccent; text = "DIPROSES"; break;
      case 'dikirim': color = Colors.purpleAccent; text = "DIKIRIM"; break;
      case 'selesai': color = Colors.greenAccent; text = "SELESAI"; break;
      case 'batal': color = Colors.redAccent; text = "DIBATALKAN"; break;
      default: color = Colors.grey; text = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(fontFamily: _fontFamily, color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}