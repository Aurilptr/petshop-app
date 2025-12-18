// File: lib/screens/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/cart_service.dart';
import 'payment_page.dart'; // Pastikan payment_page.dart juga ada!

class CheckoutPage extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> userData; 
  final List<Map<String, dynamic>> items;

  const CheckoutPage({super.key, required this.userId, required this.items, required this.userData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final String _apiUrl = 'http://127.0.0.1:5000'; // IP KAMU
  bool _isLoading = false;
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  String _selectedBank = 'BCA';
  final List<String> _banks = ['BCA', 'BRI', 'MANDIRI', 'BNI', 'CIMB'];

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
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> orderItems = widget.items.map((item) => {
        "item_id": item['id'],
        "jumlah": item['qty']
      }).toList();

      final response = await http.post(
        Uri.parse('$_apiUrl/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'items_list': orderItems,
          'bank': _selectedBank, 
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Checkout"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_on, color: Colors.pink, size: 20),
                    const SizedBox(width: 8),
                    Text(widget.userData['nama_lengkap'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  Text(widget.userData['alamat'] ?? 'Alamat belum diatur', maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            const Text("Metode Pembayaran (Virtual Account)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  items: _banks.map((String bank) {
                    return DropdownMenuItem<String>(
                      value: bank,
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.pink),
                          const SizedBox(width: 10),
                          Text(bank, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedBank = newValue!; });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Rincian Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...widget.items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Image.network(item['gambar_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                title: Text(item['nama']),
                subtitle: Text("${item['qty']} x ${formatRupiah.format(item['harga'])}"),
                trailing: Text(formatRupiah.format(item['harga'] * item['qty']), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Subtotal"),
                    Text(formatRupiah.format(_totalHarga)),
                  ]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Ongkos Kirim"),
                    const Text("Rp 10.000", style: TextStyle(color: Colors.grey)), 
                  ]),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Total Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(formatRupiah.format(_totalHarga + 10000), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey, width: 0.2))),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processOrder,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("BUAT PESANAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}