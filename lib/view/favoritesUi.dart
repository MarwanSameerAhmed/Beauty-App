import 'package:flutter/material.dart';
import 'package:test_pro/controller/favorites_service.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_Header_user.dart';
import 'package:test_pro/widgets/product_card.dart';
import 'package:test_pro/widgets/productDetails.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ProductService _productService = ProductService();
  final FavoritesService _favoritesService = FavoritesService();

  // Fetches full product details for a list of favorite IDs.
  Future<List<Product>> _getFavoriteProducts(List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final productFutures = ids
        .map((id) => _productService.getProductById(id))
        .toList();
    final products = await Future.wait(productFutures);
    // Filter out null products that may have been deleted.
    return products.where((p) => p != null).cast<Product>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,

          body: Column(
            children: [
              CustomHeaderUser(
                title: 'المفضلة',
                subtitle: 'كل ما أحببتَه سيظهر هنا للوصول السريع',
              ),
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: _favoritesService.favoriteProductIds,
                  builder: (context, favoriteIds, child) {
                    if (favoriteIds.isEmpty) {
                      return _buildEmptyFavorites();
                    }
                    // Once we have the IDs, we fetch the product data.
                    return FutureBuilder<List<Product>>(
                      future: _getFavoriteProducts(favoriteIds),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('حدث خطأ: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyFavorites();
                        }
                        return _buildFavoritesGrid(snapshot.data!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'لا توجد منتجات في المفضلة بعد.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18.0,
        crossAxisSpacing: 18.0,
        childAspectRatio: 0.7,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: product),
              ),
            );
          },
        );
      },
    );
  }
}
