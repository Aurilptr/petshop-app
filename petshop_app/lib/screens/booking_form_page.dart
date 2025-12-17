import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BookingFormPage extends StatefulWidget {
  final Map<String, dynamic> serviceData; // Data layanan (termasuk gambar_url)
  final int userId;

  const BookingFormPage({
    super.key, 
    required this.serviceData, 
    required this.userId
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller Notes
  final TextEditingController _keluhanController = TextEditingController();

  // Variable Tanggal & Jam
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  // Variable Data Hewan
  List<dynamic> _myPets = []; 
  Map<String, dynamic>? _selectedPet;
  bool _isLoadingPets = true;
  
  // Variable Pembayaran
  String _paymentMethod = 'cod'; // 'cod' atau 'transfer'
  String? _selectedBank; // Bank yang dipilih jika method == transfer
  
  // Daftar Bank Tersedia (Simulasi VA)
  final List<String> _bankList = ['BCA', 'Mandiri', 'BRI', 'BNI', 'BSI'];

  bool _isSubmitting = false;
  final String _apiUrl = 'http://192.168.101.12:5000'; // IP KAMU

  // Format Rupiah
  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchUserPets();
  }

  // --- 1. AMBIL DATA HEWAN REAL DARI DATABASE ---
  Future<void> _fetchUserPets() async {
    try {
      // [PERBAIKAN 1] URL diganti jadi /api/pets/user/ID
      final response = await http.get(Uri.parse('$_apiUrl/api/pets/user/${widget.userId}'));
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _myPets = json.decode(response.body);
            // Kalau user punya hewan, otomatis pilih yang pertama biar praktis
            if (_myPets.isNotEmpty) {
              _selectedPet = _myPets[0];
            }
            _isLoadingPets = false;
          });
        }
      } else {
        print("Gagal ambil hewan: ${response.statusCode}");
        setState(() => _isLoadingPets = false);
      }
    } catch (e) {
      print("Error fetch pets: $e");
      setState(() => _isLoadingPets = false);
    }
  }

  // --- 2. KIRIM BOOKING ---
  Future<void> _submitBooking() async {
    // Validasi dasar
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi tanggal dan jam dulu ya.")));
      return;
    }
    
    // Validasi Hewan
    if (_selectedPet == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih hewan peliharaanmu dulu.")));
       return;
    }

    // Validasi Bank (Kalau pilih transfer tapi belum pilih bank)
    if (_paymentMethod == 'transfer' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan pilih Bank tujuan transfer.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      String timeStr = _selectedTime!.format(context);
      
      // Susun string metode bayar
      String finalPaymentMethod = _paymentMethod == 'cod' 
          ? 'Bayar di Tempat' 
          : 'Transfer Bank - $_selectedBank (VA)';

      final response = await http.post(
        Uri.parse('$_apiUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'service_name': widget.serviceData['nama'],
          
          // [PERBAIKAN 2] Ambil 'nama_hewan' (bukan 'nama') sesuai database
          'pet_name': _selectedPet!['nama_hewan'], 
          'pet_type': _selectedPet!['jenis'] ?? 'Unknown', 
          'pet_color': _selectedPet!['warna'] ?? '-',
          
          'booking_date': dateStr,
          'booking_time': timeStr,
          'keluhan': _keluhanController.text,
          
          // Kirim Metode Bayar
          'payment_method': finalPaymentMethod,
          'bank_name': _selectedBank, // Kirim nama bank terpisah (opsional, buat database)
          'va_number': _paymentMethod == 'transfer' ? "8800${widget.userId}123" : null,
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        _showSuccessDialog(); // Tampilkan popup sukses
      } else {
        throw Exception("Gagal booking status: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  
  // POPUP SUKSES & INSTRUKSI BAYAR
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Booking Berhasil!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Jadwalmu sudah tercatat."),
            const SizedBox(height: 10),
            if (_paymentMethod == 'transfer') ...[
              const Divider(),
              Text("Silakan transfer ke VA $_selectedBank:", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nomor VA Dummy
                    Text("8800${widget.userId}123456", style: const TextStyle(fontFamily: 'Monospace', fontSize: 16, fontWeight: FontWeight.bold)),
                    const Icon(Icons.copy, size: 16, color: Colors.grey)
                  ],
                ),
              ),
              const SizedBox(height: 5),
              const Text("Pesanan akan diproses setelah pembayaran dikonfirmasi Admin.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ] else ...[
              const Text("Mohon datang tepat waktu ya! Pembayaran dilakukan di kasir."),
            ]
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              Navigator.pop(context); // Kembali ke menu utama
            },
            child: const Text("OK, Mengerti"),
          )
        ],
      ),
    );
  }

  // --- FUNGSI HELPER UI ---
  ImageProvider _getImage(String? url) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }
    return const AssetImage('assets/images/pet_avatar.png'); // Gambar default
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Konfirmasi Booking"), backgroundColor: Colors.pink, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD DETAIL LAYANAN (GAMBAR + HARGA)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: Column(
                  children: [
                    // Gambar Full Width dengan Clip
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _getImage(widget.serviceData['gambar_url']),
                            fit: BoxFit.cover
                          )
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(widget.serviceData['nama'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          Text(formatRupiah.format(widget.serviceData['harga']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),

              // 2. DROPDOWN PILIH HEWAN
              const Text("Mau booking buat siapa?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _isLoadingPets 
                ? const Center(child: LinearProgressIndicator(color: Colors.pink))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        hint: const Text("Pilih Hewan Peliharaan..."),
                        value: _selectedPet,
                        items: _myPets.map((pet) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: pet,
                            child: Row(
                              children: [
                                Icon(
                                  // Pastikan null safety buat jenis
                                  (pet['jenis'] ?? '').toString().toLowerCase().contains('kucing') ? Icons.pets : Icons.cruelty_free, 
                                  color: Colors.brown, size: 20
                                ),
                                const SizedBox(width: 10),
                                // [PERBAIKAN 3] Tampilkan 'nama_hewan'
                                Text(pet['nama_hewan'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(" (${pet['jenis']})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedPet = val),
                      ),
                    ),
                  ),
              
              if (!_isLoadingPets && _myPets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text("Kamu belum mendaftarkan hewan peliharaan. Silakan tambah di menu Profil.", style: TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // 3. INPUT NOTES
              const Text("Catatan / Keluhan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _keluhanController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Misal: Kucingnya agak galak, tolong hati-hati.",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 20),

              // 4. PILIH TANGGAL
              const Text("Rencana Jadwal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, color: Colors.pink),
                      label: Text(_selectedDate == null ? "Pilih Tanggal" : DateFormat('dd MMM yyyy').format(_selectedDate!), style: const TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, color: Colors.pink),
                      label: Text(_selectedTime == null ? "Pilih Jam" : _selectedTime!.format(context), style: const TextStyle(color: Colors.black87)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 5. METODE PEMBAYARAN
              const Text("Metode Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    // OPSI COD
                    RadioListTile(
                      title: const Text("Bayar di Tempat (COD)"),
                      subtitle: const Text("Bayar tunai di kasir Petshop"),
                      value: 'cod',
                      groupValue: _paymentMethod,
                      activeColor: Colors.pink,
                      onChanged: (val) => setState(() { _paymentMethod = val.toString(); _selectedBank = null; }),
                    ),
                    const Divider(height: 1),
                    
                    // OPSI TRANSFER
                    RadioListTile(
                      title: const Text("Transfer Virtual Account"),
                      subtitle: const Text("Cek otomatis, bayar via M-Banking"),
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      activeColor: Colors.pink,
                      onChanged: (val) => setState(() => _paymentMethod = val.toString()),
                    ),

                    // --- MUNCULKAN DROPDOWN BANK JIKA PILIH TRANSFER ---
                    if (_paymentMethod == 'transfer') 
                      Container(
                        color: Colors.blue[50],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pilih Bank Tujuan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text("Pilih Bank..."),
                                  value: _selectedBank,
                                  items: _bankList.map((bank) => DropdownMenuItem(value: bank, child: Text("Bank $bank"))).toList(),
                                  onChanged: (val) => setState(() => _selectedBank = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.blue),
                                SizedBox(width: 5),
                                Expanded(child: Text("Nomor VA akan muncul setelah konfirmasi.", style: TextStyle(fontSize: 12, color: Colors.blue))),
                              ],
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // TOMBOL SUBMIT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Konfirmasi & Bayar Nanti", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}