import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  // Singleton pattern setup
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  static const _favoritesKey = 'favoriteProducts';

  // A ValueNotifier that holds the list of favorite product IDs.
  // Widgets can listen to this notifier to rebuild when the list of favorites changes.
  final ValueNotifier<List<String>> favoriteProductIds = ValueNotifier([]);

  FavoritesService._internal() {
    // Load the initial list of favorites when the service is instantiated.
    _loadFavorites();
  }

  // Loads the list of favorite IDs from SharedPreferences and updates the notifier.
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteProductIds.value = prefs.getStringList(_favoritesKey) ?? [];
  }

  // Saves the current list of favorite IDs to SharedPreferences.
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteProductIds.value);
  }

  // Adds a product to favorites and notifies listeners.
  Future<void> addFavorite(String productId) async {
    if (!favoriteProductIds.value.contains(productId)) {
      // Create a new list and add the new id, then assign it to the notifier.
      final updatedFavorites = List<String>.from(favoriteProductIds.value)
        ..add(productId);
      favoriteProductIds.value = updatedFavorites;
      await _saveFavorites();
    }
  }

  // Removes a product from favorites and notifies listeners.
  Future<void> removeFavorite(String productId) async {
    if (favoriteProductIds.value.contains(productId)) {
      // Create a new list without the id, then assign it to the notifier.
      final updatedFavorites = List<String>.from(favoriteProductIds.value)
        ..remove(productId);
      favoriteProductIds.value = updatedFavorites;
      await _saveFavorites();
    }
  }

  // Toggles a product's favorite status.
  Future<void> toggleFavorite(String productId) async {
    if (isFavorite(productId)) {
      await removeFavorite(productId);
    } else {
      await addFavorite(productId);
    }
  }

  // Checks if a product is in the favorites list.
  bool isFavorite(String productId) {
    return favoriteProductIds.value.contains(productId);
  }
}
