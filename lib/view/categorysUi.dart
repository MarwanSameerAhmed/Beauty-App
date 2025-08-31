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
  List<Category> _allCategories = [];
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  int _selectedMainIndex = -1; // -1 for 'All'
  int _selectedSubIndex = -1;

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

                    _allCategories = snapshot.data!;
                    final mainCategories = _allCategories.where((c) => c.parentId == null).toList();

                    return _buildMainCategoryList(mainCategories);
                  },
                ),
              ),
              _buildSubCategoryList(),
              Expanded(child: _buildProductsGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategoryList(List<Category> mainCategories) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: mainCategories.length + 1, // +1 for 'All'
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMainIndex = -1;
                _selectedMainCategoryId = null;
                _selectedSubCategoryId = null;
              });
            },
            child: CategoryCard(
              category: Category(id: 'all', name: 'الكل'),
              isSelected: _selectedMainIndex == -1,
            ),
          );
        }

        final categoryIndex = index - 1;
        final category = mainCategories[categoryIndex];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMainIndex = categoryIndex;
              _selectedMainCategoryId = category.id;
              _selectedSubCategoryId = null; // Reset sub-category selection
              _selectedSubIndex = -1;
            });
          },
          child: CategoryCard(
            category: category,
            isSelected: _selectedMainIndex == categoryIndex,
          ),
        );
      },
    );
  }

  Widget _buildSubCategoryList() {
    final subCategories = _selectedMainCategoryId == null
        ? <Category>[]
        : _allCategories.where((c) => c.parentId == _selectedMainCategoryId).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: subCategories.isEmpty
            ? const SizedBox.shrink()
            : Column(
                key: ValueKey(_selectedMainCategoryId),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'الأصناف الفرعية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: subCategories.length + 1,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSubIndex = -1;
                                _selectedSubCategoryId = null;
                              });
                            },
                            child: CategoryCard(
                              category: Category(id: 'all_sub', name: 'الكل'),
                              isSelected: _selectedSubIndex == -1,
                              isSubcategory: true,
                            ),
                          );
                        }

                        final subCategoryIndex = index - 1;
                        final subCategory = subCategories[subCategoryIndex];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedSubIndex = subCategoryIndex;
                              _selectedSubCategoryId = subCategory.id;
                            });
                          },
                          child: CategoryCard(
                            category: subCategory,
                            isSelected: _selectedSubIndex == subCategoryIndex,
                            isSubcategory: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final Stream<List<Product>> productsStream;

    if (_selectedSubCategoryId != null) {
      // A sub-category is selected
      productsStream = _productService.getProductsByCategory(_selectedSubCategoryId!);
    } else if (_selectedMainCategoryId != null) {
      // A main category is selected, get products from it and all its sub-categories
      final categoryIds = [_selectedMainCategoryId!];
      final subCategoryIds = _allCategories
          .where((c) => c.parentId == _selectedMainCategoryId)
          .map((c) => c.id)
          .toList();
      categoryIds.addAll(subCategoryIds);
      productsStream = _productService.getProductsByCategories(categoryIds);
    } else {
      // 'All' is selected
      productsStream = _productService.getProducts();
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
