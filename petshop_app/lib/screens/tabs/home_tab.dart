// File: lib/screens/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'dart:async';
import 'dart:math'; 
import '../search_result_page.dart';
import '../../services/cart_service.dart'; 
import '../booking_form_page.dart'; 

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeTab({super.key, required this.userData});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final String _apiUrl = 'http://192.168.101.12:5000'; 
  bool _isLoading = true;
  
  List<dynamic> _productRecommendations = [];
  List<dynamic> _serviceRecommendations = [];

  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _sliderTimer;
  
  final List<String> _banners = ['assets/images/banner1.png', 'assets/images/banner2.png', 'assets/images/banner3.png'];
  String _petFact = "Sedang mencari fakta seru...";
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
    _fetchRandomPetFact(); 
    
    _sliderTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      if (_currentBannerIndex < _banners.length - 1) {
        _currentBannerIndex++;
      } else {
        _currentBannerIndex = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentBannerIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      if (response.statusCode == 200) {
        List<dynamic> allData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _productRecommendations = allData.where((item) => item['tipe'] == 'produk').take(5).toList();
            _serviceRecommendations = allData.where((item) => item['tipe'] == 'layanan').take(5).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRandomPetFact() async {
    if(mounted) setState(() { _petFact = "Mengambil fakta..."; });
    try {
      bool isDog = Random().nextBool(); 
      final url = isDog ? 'https://dog-api.kinduff.com/api/facts' : 'https://catfact.ninja/fact';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(mounted) setState(() { _petFact = isDog ? data['facts'][0] : data['fact']; });
      }
    } catch (e) {
      if(mounted) setState(() { _petFact = "Gagal memuat fakta unik."; });
    }
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Selamat Datang,", style: TextStyle(color: Colors.grey)), Text(widget.userData['nama_lengkap'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink[800]))]),
                  IconButton(onPressed: (){}, icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.notifications_none, color: Colors.pink[400])))
                ]),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: TextField(textInputAction: TextInputAction.search, onSubmitted: (value) { if (value.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultPage(keyword: value, userId: widget.userData['id']))); }, decoration: const InputDecoration(border: InputBorder.none, hintText: "Cari kebutuhan anabul...", icon: Icon(Icons.search, color: Colors.grey))))
              ]),
            ),
            const SizedBox(height: 20),
            // BANNER
            SizedBox(height: 220, child: PageView.builder(controller: _pageController, itemCount: _banners.length, onPageChanged: (index) => setState(() => _currentBannerIndex = index), itemBuilder: (context, index) { return Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: AssetImage(_banners[index]), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))])); })),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: _banners.asMap().entries.map((entry) { return Container(width: 8.0, height: 8.0, margin: const EdgeInsets.symmetric(horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: _currentBannerIndex == entry.key ? Colors.pink : Colors.grey.withValues(alpha: 0.3))); }).toList()),
            const SizedBox(height: 25),
            // FAKTA
            Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.orange.shade200, width: 2), boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.lightbulb_rounded, color: Colors.orange[800], size: 28), const SizedBox(width: 8), Text("Tahukah Kamu?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900]))]), InkWell(onTap: _fetchRandomPetFact, child: Icon(Icons.refresh_rounded, color: Colors.orange[800], size: 26))]), const SizedBox(height: 12), Divider(color: Colors.orange.shade200, thickness: 1), const SizedBox(height: 12), Text(_petFact, style: TextStyle(color: Colors.brown[700], fontSize: 15, fontStyle: FontStyle.italic, height: 1.5))])),
            const SizedBox(height: 30),
            // PRODUK
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Rekomendasi Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            SizedBox(height: 240, child: _isLoading ? const Center(child: CircularProgressIndicator()) : _productRecommendations.isEmpty ? const Center(child: Text("Belum ada produk.")) : ListView.builder(padding: const EdgeInsets.only(left: 20), scrollDirection: Axis.horizontal, itemCount: _productRecommendations.length, itemBuilder: (context, index) => _buildItemCard(_productRecommendations[index], isService: false))),
            const SizedBox(height: 20),
            // LAYANAN
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Booking Layanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            SizedBox(height: 240, child: _isLoading ? const Center(child: CircularProgressIndicator()) : _serviceRecommendations.isEmpty ? const Center(child: Text("Belum ada layanan.")) : ListView.builder(padding: const EdgeInsets.only(left: 20), scrollDirection: Axis.horizontal, itemCount: _serviceRecommendations.length, itemBuilder: (context, index) => _buildItemCard(_serviceRecommendations[index], isService: true))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(dynamic item, {required bool isService}) {
    int stok = item['stok'] ?? 0;
    bool isHabis = !isService && stok <= 0;
    
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 15, bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 5))], border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), child: ColorFiltered(colorFilter: isHabis ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply), child: Image(image: _getImage(item['gambar_url']), width: double.infinity, fit: BoxFit.cover))),
                // LABEL HABIS (Tengah Gambar)
                if (isHabis) Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(5)), child: const Text("HABIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: isHabis ? Colors.grey : Colors.black)),
                const SizedBox(height: 5),
                
                // HARGA & STOK
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah.format(item['harga']), style: TextStyle(color: isHabis ? Colors.grey : Colors.pink[600], fontSize: 12, fontWeight: FontWeight.bold)),
                    if (!isService && !isHabis) 
                      Text("Stok: $stok", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      if (isService) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingFormPage(serviceData: item, userId: widget.userData['id'])));
                      } else {
                        int currentQty = 0;
                        try { currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty']; } catch (e) { currentQty = 0; }
                        if (currentQty >= stok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                        } else {
                          CartService.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['nama']} masuk keranjang!'), duration: const Duration(seconds: 1), backgroundColor: Colors.green));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: isHabis ? Colors.grey : (isService ? Colors.blue : Colors.pink), foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(isHabis ? "Sold Out" : (isService ? "Booking" : "Add +"), style: const TextStyle(fontSize: 12)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}