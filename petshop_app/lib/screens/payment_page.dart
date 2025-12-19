// File: lib/screens/payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final int orderId;
  final int totalHarga;
  final String bankName;
  final String vaNumber;
  final String transactionType; 

  const PaymentPage({
    super.key, 
    required this.orderId, 
    required this.totalHarga,
    required this.bankName,
    required this.vaNumber,
    this.transactionType = 'order', 
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = false;

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
    print("[PaymentPage] Init. Type: ${widget.transactionType}, ID: ${widget.orderId}, VA: ${widget.vaNumber}");
  }

  Future<void> _konfirmasiPembayaran() async {
    print("[PaymentPage] Confirm Payment button clicked.");
    setState(() => _isLoading = true);
    
    // Tentukan Endpoint (Booking atau Order)
    String endpoint = widget.transactionType == 'booking' ? 'bookings' : 'orders';
    String url = '$_apiUrl/api/$endpoint/${widget.orderId}/pay';

    print("[PaymentPage] Sending PUT request to: $url");

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );

      print("[PaymentPage] Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog();
      } else {
        print("[PaymentPage] Payment Failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response.body}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("[PaymentPage] Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Pembayaran Berhasil! 🎉', style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
        content: Text('Terima kasih! Status pesanan berubah menjadi menunggu konfirmasi.', style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
        actions: [
          TextButton(
            onPressed: () {
              print("[PaymentPage] Finishing payment flow.");
              Navigator.pop(ctx); // 1. Tutup Dialog
              Navigator.pop(context); // 2. Tutup Halaman Payment
            },
            child: Text('Selesai', style: TextStyle(fontFamily: _fontFamily, color: _textWhite, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _copyToClipboard() {
    print("[PaymentPage] Copied VA: ${widget.vaNumber}");
    Clipboard.setData(ClipboardData(text: widget.vaNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Nomor VA disalin!", style: TextStyle(fontFamily: _fontFamily, color: Colors.white)), 
        backgroundColor: _accentColor, 
        duration: const Duration(seconds: 1)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Pembayaran", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: _bgDark, 
        foregroundColor: Colors.white, 
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.payment, size: 80, color: _accentColor), // Icon Teal
            const SizedBox(height: 20),
            
            Text("Total Pembayaran", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
            Text(
              formatRupiah.format(widget.totalHarga), 
              style: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.bold, color: _textWhite)
            ),
            
            const SizedBox(height: 30),
            
            // KARTU VIRTUAL ACCOUNT (Dark Style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgLight, // Card Gelap
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance, color: _accentColor),
                      const SizedBox(width: 10),
                      Text("Bank ${widget.bankName}", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite)),
                    ],
                  ),
                  Divider(height: 30, color: Colors.white.withOpacity(0.1)),
                  Text("Nomor Virtual Account", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                  const SizedBox(height: 5),
                  
                  // NOMOR VA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.vaNumber,
                        style: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: _accentColor),
                      ),
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy, color: Colors.white54),
                        tooltip: 'Salin',
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3))
                    ),
                    child: Text("Dicek Otomatis • Proses Instan", style: TextStyle(fontFamily: _fontFamily, color: Colors.orangeAccent, fontSize: 12)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor, // Tombol Teal
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                  shadowColor: _accentColor.withOpacity(0.4)
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("SAYA SUDAH TRANSFER", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 15),
            
            TextButton(
              onPressed: () {
                 print("[PaymentPage] Pay Later clicked.");
                 Navigator.pop(context); 
              },
              child: Text("Bayar Nanti", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
            )
          ],
        ),
      ),
    );
  }
}