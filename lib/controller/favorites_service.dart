import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  static const _favoritesKey = 'favoriteProducts';

  final ValueNotifier<List<String>> favoriteProductIds = ValueNotifier([]);

  FavoritesService._internal() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteProductIds.value = prefs.getStringList(_favoritesKey) ?? [];
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteProductIds.value);
  }

  Future<void> addFavorite(String productId) async {
    if (!favoriteProductIds.value.contains(productId)) {
      final updatedFavorites = List<String>.from(favoriteProductIds.value)
        ..add(productId);
      favoriteProductIds.value = updatedFavorites;
      await _saveFavorites();
    }
  }

  Future<void> removeFavorite(String productId) async {
    if (favoriteProductIds.value.contains(productId)) {
      final updatedFavorites = List<String>.from(favoriteProductIds.value)
        ..remove(productId);
      favoriteProductIds.value = updatedFavorites;
      await _saveFavorites();
    }
  }

  Future<void> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      await removeFavorite(productId);
    } else {
      await addFavorite(productId);
    }
  }

  bool isFavorite(String productId) {
    return favoriteProductIds.value.contains(productId);
  }
}
