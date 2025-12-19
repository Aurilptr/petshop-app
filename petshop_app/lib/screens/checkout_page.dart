// File: lib/screens/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cart_service.dart';
import 'payment_page.dart'; 

class CheckoutPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> userData; 
  final List<Map<String, dynamic>> items;

  const CheckoutPage({super.key, required this.userId, required this.items, required this.userData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = false;
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  String _selectedBank = 'BCA';
  final List<String> _banks = ['BCA', 'BRI', 'MANDIRI', 'BNI', 'CIMB'];

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  int get _totalHarga {
    int total = 0;
    for (var item in widget.items) {
      int price = item['harga'] ?? 0;
      int qty = item['qty'] ?? 1;
      total += (price * qty);
    }
    return total;
  }

  Future<void> _processOrder() async {
    print("[CheckoutPage] Processing Order...");
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> orderItems = widget.items.map((item) => {
        "item_id": item['id'],
        "jumlah": item['qty']
      }).toList();

      final bodyData = {
        'user_id': widget.userId,
        'items_list': orderItems,
        'bank': _selectedBank, 
      };

      print("[CheckoutPage] Sending Data: $bodyData");

      final response = await http.post(
        Uri.parse('$_apiUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyData),
      );

      print("[CheckoutPage] API Status: ${response.statusCode}");
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        print("[CheckoutPage] Order Success! Order ID: ${responseData['order_id']}");
        
        // Hapus item yang sudah dibeli dari keranjang lokal
        List<int> idsToRemove = widget.items.map((e) => e['id'] as int).toList();
        CartService.removeSpecificItems(idsToRemove);

        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPage(
              orderId: responseData['order_id'], 
              totalHarga: _totalHarga,
              bankName: _selectedBank,
              vaNumber: responseData['va_number'],
            ),
          ),
        );
      } else {
        throw Exception(responseData['message']);
      }
    } catch (e) {
      print("[CheckoutPage] Order Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Checkout", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)), 
        backgroundColor: _bgDark, 
        foregroundColor: Colors.white, 
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alamat Pengiriman", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)), // Card Gelap
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.location_on, color: _accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.userData['nama_lengkap'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
                  ]),
                  const SizedBox(height: 8),
                  Text(widget.userData['alamat'] ?? 'Alamat belum diatur', style: TextStyle(fontFamily: _fontFamily, color: _textGrey), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            Text("Metode Pembayaran (Virtual Account)", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  dropdownColor: _bgLight, // Dropdown Gelap
                  icon: Icon(Icons.arrow_drop_down, color: _accentColor),
                  items: _banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: _accentColor),
                          const SizedBox(width: 10),
                          Text(bank, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    print("[CheckoutPage] Bank selected: $newValue");
                    setState(() { _selectedBank = newValue!; });
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            Text("Rincian Pesanan", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
            const SizedBox(height: 10),
            ...widget.items.map((item) => Card(
              color: _bgLight,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(item['gambar_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, color: Colors.grey)),
                ),
                title: Text(item['nama'], style: TextStyle(fontFamily: _fontFamily, color: _textWhite, fontWeight: FontWeight.bold)),
                subtitle: Text("${item['qty']} x ${formatRupiah.format(item['harga'])}", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                trailing: Text(formatRupiah.format(item['harga'] * item['qty']), style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _accentColor)),
              ),
            )),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: _bgLight, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Subtotal", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                    Text(formatRupiah.format(_totalHarga), style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Ongkos Kirim", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                    Text("Rp 10.000", style: TextStyle(fontFamily: _fontFamily, color: _textWhite)), 
                  ]),
                  Divider(height: 20, color: Colors.white.withOpacity(0.1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("Total Bayar", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: _textWhite)),
                    Text(formatRupiah.format(_totalHarga + 10000), style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, fontSize: 18, color: _accentColor)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgLight, 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : Text("BUAT PESANAN", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}