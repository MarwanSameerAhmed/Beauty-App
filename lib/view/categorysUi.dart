import 'package:flutter/material.dart';
import 'package:test_pro/controller/category_service.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/model/categorys.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/CategorySectionUi.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_Header_user.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/widgets/product_card.dart';
import 'package:test_pro/widgets/productDetails.dart';

class Categorys extends StatefulWidget {
  const Categorys({super.key});

  @override
  State<Categorys> createState() => _CategorysState();
}

class _CategorysState extends State<Categorys> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  String? _selectedCategoryId;
  int _selectedIndex = -1; // -1 represents 'All'

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomHeaderUser(
                title: 'الاقسام',
                subtitle: "اختر القسم لتعرض المنتجات المرتبطة به",
              ),
              SizedBox(
                height: 60,
                child: StreamBuilder<List<Category>>(
                  stream: _categoryService.getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Loader());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('لا توجد أقسام حالياً'));
                    }

                    final categories = snapshot.data!;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          categories.length + 1, // +1 for the 'All' button
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // This is the 'All' button
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = -1;
                                _selectedCategoryId = null;
                              });
                            },
                            child: CategoryCard(
                              category: Category(id: 'all', name: 'الكل'),
                              isSelected: _selectedIndex == -1,
                            ),
                          );
                        }

                        // Regular category items
                        final categoryIndex = index - 1;
                        final category = categories[categoryIndex];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = categoryIndex;
                              _selectedCategoryId = category.id;
                            });
                          },
                          child: CategoryCard(
                            category: category,
                            isSelected: _selectedIndex == categoryIndex,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Expanded(child: _buildProductsGrid(_selectedCategoryId)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(String? categoryId) {
    final Stream<List<Product>> productsStream;
    if (categoryId == null) {
      productsStream = _productService.getProducts(); // Get all products
    } else {
      productsStream = _productService.getProductsByCategory(
        categoryId,
      ); // Get products by category
    }

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loader());
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد منتجات في هذا التصنيف حالياً',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
            ),
          );
        }

        final products = snapshot.data!;
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
            return Directionality(
              textDirection: TextDirection.ltr,
              child: ProductCard(
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
              ),
            );
          },
        );
      },
    );
  }
}
