import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../payment_page.dart'; // Pastikan path ini sesuai dengan projectmu

class OrdersTab extends StatefulWidget {
  final int userId;
  const OrdersTab({super.key, required this.userId});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  // --- PENTING: Sesuaikan IP Address ini dengan Backend kamu ---
  final String _apiUrl = 'http://192.168.101.12:5000'; 
  
  late TabController _tabController;
  bool _isLoading = true;
  
  List<dynamic> _productOrders = [];
  List<dynamic> _bookingOrders = [];

  // Format Rupiah
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  // --- TARIK DATA DARI SERVER ---
  Future<void> _fetchAllData() async {
    if(mounted) setState(() => _isLoading = true);
    await Future.wait([_fetchOrders(), _fetchBookings()]);
    if(mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await http.get(Uri.parse('$_apiUrl/api/orders/user/${widget.userId}'));
      if (res.statusCode == 200) {
        if(mounted) setState(() => _productOrders = json.decode(res.body));
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    }
  }

  Future<void> _fetchBookings() async {
    try {
      final res = await http.get(Uri.parse('$_apiUrl/api/bookings/user/${widget.userId}'));
      if (res.statusCode == 200) {
        if(mounted) setState(() => _bookingOrders = json.decode(res.body));
      }
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
    }
  }

  // --- NAVIGASI KE PEMBAYARAN ---
  void _goToPayment(int id, String type, int amount, String bank, String va) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentPage(
      orderId: id,
      totalHarga: amount, 
      bankName: bank, 
      vaNumber: va,
      transactionType: type,
    )));
    _fetchAllData(); // Refresh saat kembali
  }

  // --- LOGIKA BATALKAN ---
  Future<void> _cancelTransaction(int id, String type) async {
    List<String> reasons = type == 'booking' 
      ? ["Jadwal tidak cocok", "Hewan sakit", "Ganti layanan", "Lainnya"]
      : ["Ingin ubah pesanan", "Salah beli", "Lainnya"];

    String? finalReason = await _showCancellationDialog(reasons);
    if (finalReason == null) return;

    String endpoint = type == 'order' ? 'orders' : 'bookings';
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/api/$endpoint/$id/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reason': finalReason}),
      );
      
      if (response.statusCode == 200) {
        _fetchAllData();
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dibatalkan"), backgroundColor: Colors.green));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membatalkan"), backgroundColor: Colors.red));
      }
    } catch (e) {
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
              title: const Text("Alasan Pembatalan"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasonList.map((r) => RadioListTile<String>(
                  title: Text(r), value: r, groupValue: tempSelected,
                  activeColor: Colors.pink,
                  onChanged: (val) => setState(() => tempSelected = val!),
                )).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kembali")),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pesanan Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink,
          indicatorColor: Colors.pink,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "Barang"), Tab(text: "Jasa (Booking)")],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.pink)) 
        : TabBarView(
          controller: _tabController,
          children: [
            _buildList(_productOrders, 'order'),
            _buildList(_bookingOrders, 'booking'),
          ],
        ),
    );
  }

  // --- WIDGET BUILDER UNTUK LIST ITEM ---
  Widget _buildList(List<dynamic> data, String type) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text("Belum ada riwayat $type", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: Colors.pink,
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

          // --- LOGIKA JUDUL & SUBTITLE ---
          if (type == 'order') {
            title = "Order #${item['id']}";
            // FIX ERROR LIST VS STRING
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
          
          // --- LOGIKA AMBIL GAMBAR ---
          // Kita coba berbagai kemungkinan nama kolom gambar dari database
          String? imgUrl = type == 'booking' 
              ? item['image_url'] 
              : (item['image'] ?? item['gambar_url'] ?? item['product_image']);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200)
            ),
            child: Column(
              children: [
                // HEADER (TANGGAL & STATUS)
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
                const Divider(height: 1, thickness: 0.5),

                // CONTENT UTAMA
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- KODE GAMBAR BARU (Bisa Baca Aset Lokal & Internet) ---
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[100], 
                          child: Builder(
                            builder: (context) {
                              // 1. Cek jika URL kosong/null
                              if (imgUrl == null || imgUrl.isEmpty) {
                                return const Icon(Icons.pets, color: Colors.pink, size: 40);
                              }
                              
                              // 2. Jika URL dari Internet (http)
                              if (imgUrl.startsWith('http')) {
                                return Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                                );
                              }
                              
                              // 3. Jika URL dari Aset Lokal (Database kamu: assets/images/...)
                              return Image.asset(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) {
                                  // Kalau file gambarnya ternyata gak ada di folder assets, tampilkan icon
                                  return const Icon(Icons.pets, color: Colors.pink, size: 40);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // INFO TEKS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah.format(price),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    color: Colors.red[50],
                    child: Text("Alasan: ${item['cancel_reason']}", style: TextStyle(fontSize: 12, color: Colors.red[800], fontStyle: FontStyle.italic)),
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
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Batalkan"),
                            ),
                          ),
                        if (isUnpaid) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () => _goToPayment(item['id'], type, price, item['bank_name'] ?? 'Bank', item['va_number'] ?? '-'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Bayar Sekarang"),
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

  // --- LOGIKA STATUS BADGE ---
  Widget _statusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'menunggu_pembayaran': color = Colors.orange; text = "BELUM BAYAR"; break;
      case 'menunggu_konfirmasi': color = Colors.blue; text = "DIPROSES"; break;
      case 'diproses': color = Colors.blueAccent; text = "DIPROSES"; break;
      case 'dikirim': color = Colors.purple; text = "DIKIRIM"; break;
      case 'selesai': color = Colors.green; text = "SELESAI"; break;
      case 'batal': color = Colors.red; text = "DIBATALKAN"; break;
      default: color = Colors.grey; text = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}