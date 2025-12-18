// File: lib/screens/payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final int totalHarga;
  final String bankName;
  final String vaNumber;
  final String transactionType; // 1. TAMBAHKAN INI

  const PaymentPage({
    super.key, 
    required this.orderId, 
    required this.totalHarga,
    required this.bankName,
    required this.vaNumber,
    this.transactionType = 'order', // 2. TAMBAHKAN INI (Default 'order')
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; // IP KAMU
  bool _isLoading = false;

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  Future<void> _konfirmasiPembayaran() async {
    setState(() => _isLoading = true);
    
    // 3. LOGIKA BARU: Tentukan Endpoint (Booking atau Order)
    String endpoint = widget.transactionType == 'booking' ? 'bookings' : 'orders';
    // Gunakan endpoint /pay yang sudah kita buat di backend revisi
    String url = '$_apiUrl/api/$endpoint/${widget.orderId}/pay';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Pembayaran Berhasil! 🎉'),
            content: const Text('Terima kasih! Status pesanan berubah menjadi menunggu konfirmasi.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // 1. Tutup Dialog
                  Navigator.pop(context); // 2. Tutup Halaman Payment
                },
                child: const Text('Selesai'),
              )
            ],
          ),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.vaNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nomor VA disalin!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.payment, size: 80, color: Colors.pink),
            const SizedBox(height: 20),
            
            Text("Total Pembayaran", style: TextStyle(color: Colors.grey[600])),
            Text(
              formatRupiah.format(widget.totalHarga), // Revisi: Harga pas, tidak perlu +10000 kalau tidak ada admin fee
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink)
            ),
            
            const SizedBox(height: 30),
            
            // KARTU VIRTUAL ACCOUNT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text("Bank ${widget.bankName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  const Text("Nomor Virtual Account", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 5),
                  
                  // NOMOR VA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.vaNumber,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy, color: Colors.pink),
                        tooltip: 'Salin',
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                    child: const Text("Dicek Otomatis • Proses Instan", style: TextStyle(color: Colors.orange, fontSize: 12)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _konfirmasiPembayaran,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAYA SUDAH TRANSFER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            
            TextButton(
              onPressed: () {
                 Navigator.pop(context); 
              },
              child: const Text("Bayar Nanti", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}