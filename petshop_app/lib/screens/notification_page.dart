// File: lib/screens/notification_page.dart

import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // --- PALET WARNA ELEGANT MIDNIGHT ---
  final Color _bgDark = const Color(0xFF0F2027); // Background Utama
  final Color _bgLight = const Color(0xFF203A43); // Warna Card
  final Color _accentColor = const Color(0xFF4CA1AF); // Teal/Cyan Neon
  final Color _textWhite = Colors.white;
  final Color _textGrey = Colors.white70;
  
  // --- FONT CUSTOM ---
  final String _fontFamily = 'Helvetica';

  // Helper untuk menentukan Icon berdasarkan tipe
  IconData _getIconByType(String type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'promo': return Icons.local_offer_outlined;
      case 'info': return Icons.info_outline;
      default: return Icons.notifications_none;
    }
  }

  // Helper untuk menentukan Warna Icon berdasarkan tipe
  Color _getColorByType(String type) {
    switch (type) {
      case 'success': return Colors.greenAccent;
      case 'promo': return Colors.orangeAccent;
      case 'info': return Colors.blueAccent;
      default: return _accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data Dummy
    final List<Map<String, String>> notifications = [
      {
        "title": "Pembayaran Berhasil",
        "body": "Pembayaran untuk layanan Grooming Kucing (Paket Lengkap) telah terverifikasi oleh sistem. Silakan datang sesuai jadwal yang telah ditentukan.",
        "time": "Baru saja",
        "type": "success"
      },
      {
        "title": "Diskon Spesial 50%!",
        "body": "Khusus hari ini! Dapatkan diskon 50% untuk vaksinasi rabies. Gunakan kode promo: PAW50 saat checkout.",
        "time": "1 Jam yang lalu",
        "type": "promo"
      },
      {
        "title": "Jadwal Pengingat",
        "body": "Jangan lupa jadwal kontrol kesehatan anabul besok pagi jam 09:00 WIB di klinik kami.",
        "time": "Kemarin",
        "type": "info"
      },
    ];

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        title: Text("Notifikasi", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite)),
        backgroundColor: _bgDark,
        foregroundColor: _textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: notifications.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 10),
                Text("Belum ada notifikasi", style: TextStyle(fontFamily: _fontFamily, color: _textGrey)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationItem(context, notif, index == 0); // index 0 = terbaru
            },
          ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, String> notif, bool isNew) {
    Color typeColor = _getColorByType(notif['type']!);
    IconData typeIcon = _getIconByType(notif['type']!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(15),
        border: isNew ? Border.all(color: _accentColor.withOpacity(0.3), width: 1) : Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showNotificationDetail(context, notif, typeColor, typeIcon),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Indikator (Lebih Keren)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 15),
                
                // Konten Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title']!, 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: _textWhite, fontSize: 16)
                            ),
                          ),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(left: 5),
                              decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(4)),
                              child: Text("NEW", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _bgDark)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notif['time']!, style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(
                        notif['body']!, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: TextStyle(fontFamily: _fontFamily, color: Colors.white60, fontSize: 13, height: 1.4)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- POPUP DETAIL (BOTTOM SHEET) ---
  void _showNotificationDetail(BuildContext context, Map<String, String> notif, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis handle kecil di atas
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              
              // Icon Besar
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 20),
              
              // Judul & Waktu
              Text(notif['title']!, textAlign: TextAlign.center, style: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: _textWhite)),
              const SizedBox(height: 8),
              Text(notif['time']!, style: TextStyle(fontFamily: _fontFamily, color: _textGrey, fontSize: 12)),
              
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 20),
              
              // Isi Pesan Lengkap
              Text(
                notif['body']!, 
                textAlign: TextAlign.center, 
                style: TextStyle(fontFamily: _fontFamily, color: Colors.white70, fontSize: 14, height: 1.5)
              ),
              
              const SizedBox(height: 30),
              
              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                  child: Text("Tutup", style: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}