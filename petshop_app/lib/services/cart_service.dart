// File: lib/services/cart_service.dart

import 'package:shared_preferences/shared_preferences.dart'; // Import Library Baru
import 'dart:convert'; // Import untuk ubah List ke Teks JSON

class CartService {
  static List<Map<String, dynamic>> _items = [];

  // --- FUNGSI LOAD (DIPANGGIL SAAT APLIKASI NYALA) ---
  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    // Ambil data teks dari memori HP
    String? cartString = prefs.getString('my_cart');
    
    if (cartString != null) {
      // Ubah Teks JSON kembali menjadi List
      List<dynamic> decodedList = json.decode(cartString);
      _items = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      print('Berhasil memuat ${_items.length} barang dari memori HP.');
    }
  }

  // --- FUNGSI SAVE (DIPANGGIL SETIAP ADA PERUBAHAN) ---
  static Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List menjadi Teks JSON biar bisa disimpan
    String cartString = json.encode(_items);
    await prefs.setString('my_cart', cartString);
    print('Keranjang disimpan ke memori HP.');
  }

  static void addItem(Map<String, dynamic> item) {
    int index = _items.indexWhere((i) => i['id'] == item['id']);
    
    if (index != -1) {
      _items[index]['qty'] = (_items[index]['qty'] ?? 1) + 1;
    } else {
      Map<String, dynamic> newItem = Map.from(item);
      newItem['qty'] = 1;
      _items.add(newItem);
    }
    _saveCart(); // <--- SIMPAN OTOMATIS
  }

  static void removeItem(int id) {
    _items.removeWhere((item) => item['id'] == id);
    _saveCart(); // <--- SIMPAN OTOMATIS
  }

  static void removeSpecificItems(List<int> idsToRemove) {
    _items.removeWhere((item) => idsToRemove.contains(item['id']));
    _saveCart(); // <--- SIMPAN OTOMATIS
  }
  
  static void decreaseQty(int id) {
    int index = _items.indexWhere((i) => i['id'] == id);
    if (index != -1) {
      if (_items[index]['qty'] > 1) {
        _items[index]['qty'] -= 1;
      } else {
        _items.removeAt(index);
      }
      _saveCart(); // <--- SIMPAN OTOMATIS
    }
  }

  static List<Map<String, dynamic>> get items => _items;

  static int get totalPrice {
    int total = 0;
    for (var item in _items) {
      int price = item['harga'] ?? 0;
      int qty = item['qty'] ?? 1;
      total += (price * qty);
    }
    return total;
  }

  static void clear() {
    _items.clear();
    _saveCart(); // <--- SIMPAN OTOMATIS (Jadi kosong juga di memori)
  }
}