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
import '../notification_page.dart'; // Import Halaman Notifikasi

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeTab({super.key, required this.userData});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final String _apiUrl = 'http://127.0.0.1:5000'; 
  bool _isLoading = true;
  
  List<dynamic> _productRecommendations = [];
  List<dynamic> _serviceRecommendations = [];

  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _sliderTimer;
  
  final List<String> _banners = ['assets/images/banner1.png', 'assets/images/banner2.png', 'assets/images/banner3.png'];
  String _petFact = "Sedang mencari fakta seru...";
  final formatRupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Untuk Card/Header
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _glassWhite = Colors.white.withOpacity(0.05); // Efek Kaca Transparan

  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  @override
  void initState() {
    super.initState();
    print("[HomeTab] InitState Called. User: ${widget.userData['nama_lengkap']}");
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
    print("[HomeTab] Fetching items from API...");
    try {
      final response = await http.get(Uri.parse('$_apiUrl/api/items'));
      print("[HomeTab] API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        List<dynamic> allData = json.decode(response.body);
        if (mounted) {
          setState(() {
            _productRecommendations = allData.where((item) => item['tipe'] == 'produk').take(5).toList();
            _serviceRecommendations = allData.where((item) => item['tipe'] == 'layanan').take(5).toList();
            _isLoading = false;
          });
          print("[HomeTab] Loaded ${_productRecommendations.length} products & ${_serviceRecommendations.length} services.");
        }
      }
    } catch (e) {
      print("[HomeTab] Error fetching items: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRandomPetFact() async {
    print("[HomeTab] Fetching new pet fact...");
    if(mounted) setState(() { _petFact = "Mengambil fakta..."; });
    try {
      bool isDog = Random().nextBool(); 
      final url = isDog ? 'https://dog-api.kinduff.com/api/facts' : 'https://catfact.ninja/fact';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(mounted) setState(() { _petFact = isDog ? data['facts'][0] : data['fact']; });
        print("[HomeTab] Fact updated!");
      }
    } catch (e) {
      print("[HomeTab] Error fetching fact: $e");
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
      backgroundColor: _bgDark, // Background Gelap Pekat
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Gradient Background)
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgDark, _bgLight], 
                ),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))
                ]
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Selamat Datang,", style: TextStyle(fontFamily: _fontFamily, color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(widget.userData['nama_lengkap'], style: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1))
                  ]),
                  IconButton(
                    onPressed: (){
                      print("[HomeTab] Notification Icon Clicked"); 
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                    }, 
                    icon: Container(
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(color: _glassWhite, shape: BoxShape.circle), 
                      child: Icon(Icons.notifications_none, color: _accentColor)
                    )
                  )
                ]),
                const SizedBox(height: 20),
                
                // --- SEARCH BAR (Style Solid/Tegas) ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15), 
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50), // Warna Solid Abu-Biru (Bukan Transparan)
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1))
                  ), 
                  child: TextField(
                    textInputAction: TextInputAction.search, 
                    style: TextStyle(fontFamily: _fontFamily, color: Colors.white), // Text Putih
                    onSubmitted: (value) { 
                      print("[HomeTab] Search Submitted: $value"); 
                      if (value.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultPage(keyword: value, userId: widget.userData['id']))); 
                    }, 
                    decoration: InputDecoration(
                      border: InputBorder.none, 
                      hintText: "Cari kebutuhan anabul...", 
                      hintStyle: TextStyle(fontFamily: _fontFamily, color: Colors.white.withOpacity(0.6)), // Hint lebih terang
                      icon: Icon(Icons.search, color: _accentColor)
                    )
                  )
                )
              ]),
            ),
            
            const SizedBox(height: 20),
            
            // BANNER
            SizedBox(height: 180, child: PageView.builder(controller: _pageController, itemCount: _banners.length, onPageChanged: (index) => setState(() => _currentBannerIndex = index), itemBuilder: (context, index) { return Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: DecorationImage(image: AssetImage(_banners[index]), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))])); })),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: _banners.asMap().entries.map((entry) { return Container(width: 8.0, height: 8.0, margin: const EdgeInsets.symmetric(horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: _currentBannerIndex == entry.key ? _accentColor : Colors.white.withOpacity(0.2))); }).toList()),
            
            const SizedBox(height: 25),
            
            // FAKTA (Dark Card dengan Border Cyan)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20), 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), 
              decoration: BoxDecoration(
                color: _bgLight.withOpacity(0.5), 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: _accentColor.withOpacity(0.3), width: 1), 
              ), 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline, color: _accentColor, size: 24), 
                    const SizedBox(width: 10), 
                    Text("Tahukah Kamu?", style: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))
                  ]), 
                  InkWell(
                    onTap: () {
                      print("[HomeTab] Refresh Fact Clicked"); 
                      _fetchRandomPetFact();
                    }, 
                    child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.7), size: 22)
                  )
                ]), 
                const SizedBox(height: 10), 
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1), 
                const SizedBox(height: 10), 
                Text(_petFact, style: TextStyle(fontFamily: _fontFamily, color: Colors.white.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic, height: 1.4))
              ])
            ),
            
            const SizedBox(height: 30),
            
            // LIST PRODUK
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Rekomendasi Produk", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)))),
            const SizedBox(height: 15),
            SizedBox(height: 260, child: _isLoading ? Center(child: CircularProgressIndicator(color: _accentColor)) : _productRecommendations.isEmpty ? Center(child: Text("Belum ada produk.", style: TextStyle(color: Colors.white.withOpacity(0.5)))) : ListView.builder(padding: const EdgeInsets.only(left: 20), scrollDirection: Axis.horizontal, itemCount: _productRecommendations.length, itemBuilder: (context, index) => _buildItemCard(_productRecommendations[index], isService: false))),
            
            const SizedBox(height: 20),
            
            // LIST LAYANAN
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text("Booking Layanan", style: TextStyle(fontFamily: _fontFamily, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)))),
            const SizedBox(height: 15),
            SizedBox(height: 260, child: _isLoading ? Center(child: CircularProgressIndicator(color: _accentColor)) : _serviceRecommendations.isEmpty ? Center(child: Text("Belum ada layanan.", style: TextStyle(color: Colors.white.withOpacity(0.5)))) : ListView.builder(padding: const EdgeInsets.only(left: 20), scrollDirection: Axis.horizontal, itemCount: _serviceRecommendations.length, itemBuilder: (context, index) => _buildItemCard(_serviceRecommendations[index], isService: true))),
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
      width: 160,
      margin: const EdgeInsets.only(right: 15, bottom: 10),
      decoration: BoxDecoration(
        color: _bgLight, // Warna Card Navy agak terang dikit
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))], 
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), 
                  child: ColorFiltered(
                    colorFilter: isHabis ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.multiply), 
                    child: Image(image: _getImage(item['gambar_url']), width: double.infinity, fit: BoxFit.cover)
                  )
                ),
                if (isHabis) Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(5)), child: const Text("HABIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: isHabis ? Colors.grey : Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah.format(item['harga']), style: TextStyle(fontFamily: _fontFamily, color: isHabis ? Colors.grey : _accentColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (!isService && !isHabis) 
                      Text("Stok: $stok", style: TextStyle(fontFamily: _fontFamily, fontSize: 10, color: Colors.white.withOpacity(0.5))),
                  ],
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isHabis ? null : () {
                      print("[HomeTab] Item Button Clicked: ${item['nama']} (Service: $isService)"); 
                      
                      if (isService) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingFormPage(serviceData: item, userId: widget.userData['id'])));
                      } else {
                        int currentQty = 0;
                        try { currentQty = CartService.items.firstWhere((c) => c['id'] == item['id'])['qty']; } catch (e) { currentQty = 0; }
                        
                        if (currentQty >= stok) {
                          print("[HomeTab] Stock insufficient for ${item['nama']}");
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red));
                        } else {
                          print("[HomeTab] Adding ${item['nama']} to Cart");
                          CartService.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['nama']} masuk keranjang!'), duration: const Duration(seconds: 1), backgroundColor: Colors.green));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      // Tombol menggunakan warna Accent (Teal) solid agar kontras
                      backgroundColor: isHabis ? Colors.white.withOpacity(0.1) : _accentColor, 
                      foregroundColor: isHabis ? Colors.white.withOpacity(0.3) : Colors.white, 
                      padding: EdgeInsets.zero, 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)) 
                    ),
                    child: Text(isHabis ? "Sold Out" : (isService ? "Booking" : "Add +"), style: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.bold)),
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