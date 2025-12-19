// File: lib/screens/booking_form_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class BookingFormPage extends StatefulWidget {
  final Map<String, dynamic> serviceData; 
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
  
  final TextEditingController _keluhanController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  List<dynamic> _myPets = []; 
  Map<String, dynamic>? _selectedPet;
  bool _isLoadingPets = true;
  
  String _paymentMethod = 'cod'; 
  String? _selectedBank; 
  
  final List<String> _bankList = ['BCA', 'Mandiri', 'BRI', 'BNI', 'BSI'];

  bool _isSubmitting = false;
  final String _apiUrl = 'http://127.0.0.1:5000'; 

  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); 
  final Color _bgLight = const Color(0xFF203A43); 
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;
  final Color _inputFill = Colors.white.withOpacity(0.05);

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[BookingPage] InitState. User ID: ${widget.userId}, Service: ${widget.serviceData['nama']}");
    _fetchUserPets();
  }

  // --- 1. AMBIL DATA HEWAN ---
  Future<void> _fetchUserPets() async {
    print("[BookingPage] Fetching user pets...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/pets/user/${widget.userId}'));
      print("[BookingPage] API Pets Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _myPets = json.decode(response.body);
            if (_myPets.isNotEmpty) {
              _selectedPet = _myPets[0];
            }
            _isLoadingPets = false;
          });
          print("[BookingPage] Loaded ${_myPets.length} pets.");
        }
      } else {
        print("[BookingPage] Failed to load pets.");
        setState(() => _isLoadingPets = false);
      }
    } catch (e) {
      print("[BookingPage] Error fetching pets: $e");
      setState(() => _isLoadingPets = false);
    }
  }

  // --- 2. KIRIM BOOKING ---
  Future<void> _submitBooking() async {
    print("[BookingPage] Submit button clicked.");

    // Validasi
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) {
      print("[BookingPage] Validation Failed: Date/Time/Form incomplete.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi tanggal dan jam dulu ya.")));
      return;
    }
    
    if (_selectedPet == null) {
       print("[BookingPage] Validation Failed: No pet selected.");
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih hewan peliharaanmu dulu.")));
       return;
    }

    if (_paymentMethod == 'transfer' && _selectedBank == null) {
      print("[BookingPage] Validation Failed: Bank not selected.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan pilih Bank tujuan transfer.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      String timeStr = _selectedTime!.format(context);
      
      String finalPaymentMethod = _paymentMethod == 'cod' 
          ? 'Bayar di Tempat' 
          : 'Transfer Bank - $_selectedBank (VA)';

      final Map<String, dynamic> payload = {
        'user_id': widget.userId,
        'service_name': widget.serviceData['nama'],
        'pet_name': _selectedPet!['nama_hewan'], 
        'pet_type': _selectedPet!['jenis'] ?? 'Unknown', 
        'pet_color': _selectedPet!['warna'] ?? '-',
        'booking_date': dateStr,
        'booking_time': timeStr,
        'keluhan': _keluhanController.text,
        'payment_method': finalPaymentMethod,
        'bank_name': _selectedBank,
        'va_number': _paymentMethod == 'transfer' ? "8800${widget.userId}123" : null,
      };

      print("[BookingPage] Sending Booking Data: $payload");

      final response = await http.post(
        Uri.parse('$_apiUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print("[BookingPage] API Response Status: ${response.statusCode}");

      if (response.statusCode == 201) {
        if (!mounted) return;
        _showSuccessDialog(); 
      } else {
        throw Exception("Gagal booking status: ${response.statusCode}");
      }
    } catch (e) {
      print("[BookingPage] Error submitting: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  
  // POPUP SUKSES (DARK THEME)
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgLight, // Dialog Gelap
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Booking Berhasil!", style: TextStyle(fontFamily: _fontFamily, color: _accentColor, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Jadwalmu sudah tercatat.", style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
            const SizedBox(height: 15),
            if (_paymentMethod == 'transfer') ...[
              Divider(color: Colors.white.withOpacity(0.2)),
              Text("Silakan transfer ke VA $_selectedBank:", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accentColor.withOpacity(0.5))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("8800${widget.userId}123456", style: TextStyle(fontFamily: 'Monospace', fontSize: 16, fontWeight: FontWeight.bold, color: _accentColor)),
                    Icon(Icons.copy, size: 16, color: _textGrey)
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text("Pesanan akan diproses setelah pembayaran dikonfirmasi Admin.", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _textGrey)),
            ] else ...[
              Text("Mohon datang tepat waktu ya! Pembayaran dilakukan di kasir.", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
            ]
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
            child: Text("OK, Mengerti", style: TextStyle(fontFamily: _fontFamily, color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: _bgLight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      print("[BookingPage] Date Picked: $picked");
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentColor,
              onPrimary: Colors.white,
              surface: _bgLight,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      print("[BookingPage] Time Picked: $picked");
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, // Background Gelap
      appBar: AppBar(
        title: Text("Konfirmasi Booking", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD DETAIL LAYANAN (Dark Style)
              Container(
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                child: Column(
                  children: [
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
                            child: Text(widget.serviceData['nama'], style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: _textWhite)),
                          ),
                          Text(formatRupiah.format(widget.serviceData['harga']), style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _accentColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),

              // 2. DROPDOWN PILIH HEWAN
              Text("Mau booking buat siapa?", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 8),
              _isLoadingPets 
                ? Center(child: LinearProgressIndicator(color: _accentColor))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _inputFill,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        dropdownColor: _bgLight,
                        hint: Text("Pilih Hewan Peliharaan...", style: TextStyle(color: _textGrey, fontFamily: _fontFamily)),
                        value: _selectedPet,
                        items: _myPets.map((pet) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: pet,
                            child: Row(
                              children: [
                                Icon(
                                  (pet['jenis'] ?? '').toString().toLowerCase().contains('kucing') ? Icons.pets : Icons.cruelty_free, 
                                  color: _accentColor, size: 20
                                ),
                                const SizedBox(width: 10),
                                Text(pet['nama_hewan'], style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
                                Text(" (${pet['jenis']})", style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)),
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
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Kamu belum mendaftarkan hewan peliharaan.", style: TextStyle(fontFamily: _fontFamily, color: Colors.redAccent, fontSize: 12))),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // 3. INPUT NOTES
              Text("Catatan / Keluhan", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _keluhanController,
                maxLines: 2,
                style: TextStyle(color: _textWhite, fontFamily: _fontFamily),
                decoration: InputDecoration(
                  hintText: "Misal: Kucingnya agak galak, tolong hati-hati.",
                  hintStyle: TextStyle(color: Colors.white30, fontFamily: _fontFamily),
                  filled: true,
                  fillColor: _inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _accentColor)),
                ),
              ),

              const SizedBox(height: 20),

              // 4. PILIH TANGGAL & JAM
              Text("Rencana Jadwal", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today, color: _accentColor),
                      label: Text(
                        _selectedDate == null ? "Pilih Tanggal" : DateFormat('dd MMM yyyy').format(_selectedDate!), 
                        style: TextStyle(fontFamily: _fontFamily, color: _textWhite)
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15), 
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: Icon(Icons.access_time, color: _accentColor),
                      label: Text(
                        _selectedTime == null ? "Pilih Jam" : _selectedTime!.format(context), 
                        style: TextStyle(fontFamily: _fontFamily, color: _textWhite)
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15), 
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 5. METODE PEMBAYARAN
              Text("Metode Pembayaran", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.05))
                ),
                child: Column(
                  children: [
                    // OPSI COD
                    RadioListTile(
                      title: Text("Bayar di Tempat (COD)", style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
                      subtitle: Text("Bayar tunai di kasir Petshop", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                      value: 'cod',
                      groupValue: _paymentMethod,
                      activeColor: _accentColor,
                      onChanged: (val) => setState(() { _paymentMethod = val.toString(); _selectedBank = null; }),
                    ),
                    Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                    
                    // OPSI TRANSFER
                    RadioListTile(
                      title: Text("Transfer Virtual Account", style: TextStyle(fontFamily: _fontFamily, color: _textWhite)),
                      subtitle: Text("Cek otomatis, bayar via M-Banking", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
                      value: 'transfer',
                      groupValue: _paymentMethod,
                      activeColor: _accentColor,
                      onChanged: (val) => setState(() => _paymentMethod = val.toString()),
                    ),

                    // DROPDOWN BANK
                    if (_paymentMethod == 'transfer') 
                      Container(
                        color: Colors.black.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pilih Bank Tujuan:", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _accentColor)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: _inputFill, 
                                borderRadius: BorderRadius.circular(8), 
                                border: Border.all(color: Colors.white.withOpacity(0.2))
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  dropdownColor: _bgLight,
                                  hint: Text("Pilih Bank...", style: TextStyle(color: _textGrey, fontFamily: _fontFamily)),
                                  value: _selectedBank,
                                  items: _bankList.map((bank) => DropdownMenuItem(value: bank, child: Text("Bank $bank", style: TextStyle(color: _textWhite, fontFamily: _fontFamily)))).toList(),
                                  onChanged: (val) => setState(() => _selectedBank = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: _accentColor),
                                const SizedBox(width: 5),
                                Expanded(child: Text("Nomor VA akan muncul setelah konfirmasi.", style: TextStyle(fontFamily: _fontFamily, fontSize: 12, color: _accentColor))),
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
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                    shadowColor: _accentColor.withOpacity(0.4)
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Konfirmasi & Bayar Nanti", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold)),
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