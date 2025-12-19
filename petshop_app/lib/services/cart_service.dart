// File: lib/services/cart_service.dart

import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:convert'; 

class CartService {
  static List<Map<String, dynamic>> _items = [];

  // --- FUNGSI LOAD (DIPANGGIL SAAT APLIKASI NYALA) ---
  static Future<void> loadCart() async {
    print("[CartService] Loading cart from local storage...");
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cartString = prefs.getString('my_cart');
      
      if (cartString != null) {
        List<dynamic> decodedList = json.decode(cartString);
        _items = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
        print('[CartService] Success! Loaded ${_items.length} items.');
      } else {
        print('[CartService] No saved cart found (New Session).');
      }
    } catch (e) {
      print('[CartService] Error loading cart: $e');
    }
  }

  // --- FUNGSI SAVE (DIPANGGIL SETIAP ADA PERUBAHAN) ---
  static Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String cartString = json.encode(_items);
      await prefs.setString('my_cart', cartString);
      print('[CartService] Cart saved to local storage. Total items: ${_items.length}');
    } catch (e) {
      print('[CartService] Error saving cart: $e');
    }
  }

  static void addItem(Map<String, dynamic> item) {
    print("[CartService] Adding item: ${item['nama']}");
    int index = _items.indexWhere((i) => i['id'] == item['id']);
    
    if (index != -1) {
      _items[index]['qty'] = (_items[index]['qty'] ?? 1) + 1;
      print("[CartService] Item exists. Quantity increased to ${_items[index]['qty']}");
    } else {
      Map<String, dynamic> newItem = Map.from(item);
      newItem['qty'] = 1;
      _items.add(newItem);
      print("[CartService] New item added.");
    }
    _saveCart(); 
  }

  static void removeItem(int id) {
    print("[CartService] Removing item ID: $id");
    _items.removeWhere((item) => item['id'] == id);
    _saveCart(); 
  }

  static void removeSpecificItems(List<int> idsToRemove) {
    print("[CartService] Removing processed items: $idsToRemove");
    _items.removeWhere((item) => idsToRemove.contains(item['id']));
    _saveCart(); 
  }
  
  static void decreaseQty(int id) {
    int index = _items.indexWhere((i) => i['id'] == id);
    if (index != -1) {
      if (_items[index]['qty'] > 1) {
        _items[index]['qty'] -= 1;
        print("[CartService] Qty decreased for ID $id. New Qty: ${_items[index]['qty']}");
      } else {
        _items.removeAt(index);
        print("[CartService] Item ID $id removed because Qty became 0.");
      }
      _saveCart(); 
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
    print("[CartService] Clearing entire cart...");
    _items.clear();
    _saveCart(); 
  }
}