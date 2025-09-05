import 'package:flutter/material.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/widgets/product_card.dart';
import 'package:test_pro/widgets/productDetails.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'dart:ui';

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final String? categoryId;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    this.categoryId,
  });

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _currentQuery = query.trim();
      });
    }
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
              // Custom Header
              CustomAdminHeader(
                title: 'البحث',
                subtitle: 'ابحث عن منتجاتك المفضلة',
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          216,
                          213,
                          213,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Search TextField
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textDirection: TextDirection.rtl,
                              onSubmitted: _performSearch,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'ابحث عن منتج...',
                                hintTextDirection: TextDirection.rtl,
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          // Search Icon Button
                          Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFF52002C), Color(0xFF942A59)],
                                stops: [0.7, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  _performSearch(_searchController.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search results
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: widget.categoryId != null
                      ? _productService.searchProductsWithCategory(
                          _currentQuery,
                          widget.categoryId,
                        )
                      : _productService.searchProducts(_currentQuery),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Loader());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'حدث خطأ أثناء البحث',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لم يتم العثور على منتجات',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جرب البحث بكلمات مختلفة',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final products = snapshot.data!;

                    return Column(
                      children: [
                        // Results count with improved styling
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20.0),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'تم العثور على ${products.length} منتج لـ "$_currentQuery"',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Tajawal',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Products grid with improved styling
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 15,
                                  mainAxisSpacing: 15,
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
                                      builder: (context) =>
                                          ProductDetailsPage(product: product),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
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
}
