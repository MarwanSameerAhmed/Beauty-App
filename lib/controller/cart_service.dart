import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/model/cart_item.dart';
import 'package:test_pro/model/product.dart';

class CartService with ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal() {
    _loadCart();
  }

  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          productId: existingCartItem.productId,
          name: existingCartItem.name,
          description: existingCartItem.description, // Added description
          images: existingCartItem.images,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem.fromProduct(product),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity > 0) {
        _items.update(
          productId,
          (existing) => CartItem(
            productId: existing.productId,
            name: existing.name,
            description: existing.description,
            images: existing.images,
            price: existing.price,
            quantity: quantity,
          ),
        );
      } else {
        _items.remove(productId);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items = {};
    _saveCart();
    notifyListeners();
  }

  // Persistence with SharedPreferences
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(
      {
        'items': _items.map((key, item) => MapEntry(key, item.toJson())),
      },
    );
    await prefs.setString('cartData', cartData);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('cartData')) return;

    final extractedData = json.decode(prefs.getString('cartData')!) as Map<String, dynamic>;
    final Map<String, CartItem> loadedItems = {};
    (extractedData['items'] as Map<String, dynamic>).forEach((productId, itemData) {
      loadedItems[productId] = CartItem.fromJson(itemData);
    });
    _items = loadedItems;
    notifyListeners();
  }
}
