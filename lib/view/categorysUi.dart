import 'package:flutter/material.dart';
import 'package:glamify/controller/category_service.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/model/categorys.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/CategorySectionUi.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_Header_user.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/widgets/product_card.dart';
import 'package:glamify/widgets/productDetails.dart';

class Categorys extends StatefulWidget {
  const Categorys({super.key});

  @override
  State<Categorys> createState() => _CategorysState();
}

class _CategorysState extends State<Categorys> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();
  final ScrollController _mainCategoryScrollController = ScrollController();
  
  // البيانات المحمّلة
  List<Category> _allCategories = [];
  List<Product> _products = [];
  
  // حالة التحميل
  bool _isCategoriesLoading = true;
  bool _isProductsLoading = true;
  
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId;
  int _selectedMainIndex = -1; // -1 for 'All'
  int _selectedSubIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }
  
  @override
  void dispose() {
    _mainCategoryScrollController.dispose();
    super.dispose();
  }

  /// جلب الأقسام مرة واحدة (Future بدل Stream)
  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategoriesFuture();
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    }
  }

  /// جلب المنتجات مرة واحدة بناءً على القسم المحدد
  Future<void> _loadProducts() async {
    setState(() => _isProductsLoading = true);

    try {
      List<Product> products;

      if (_selectedSubCategoryId != null) {
        products = await _productService.getProductsByCategoryOnce(
          _selectedSubCategoryId!,
        );
      } else if (_selectedMainCategoryId != null) {
        final categoryIds = [_selectedMainCategoryId!];
        final subCategoryIds = _allCategories
            .where((c) => c.parentId == _selectedMainCategoryId)
            .map((c) => c.id)
            .toList();
        categoryIds.addAll(subCategoryIds);
        products = await _productService.getProductsByCategoriesOnce(categoryIds);
      } else {
        products = await _productService.getProductsOnce();
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isProductsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProductsLoading = false);
      }
    }
  }

  /// تحديث كل البيانات (Pull-to-Refresh)
  Future<void> _onRefresh() async {
    await Future.wait([
      _loadCategories(),
      _loadProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF52002C),
            backgroundColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomHeaderUser(
                  title: 'الاقسام',
                  subtitle: "اختر القسم لتعرض المنتجات المرتبطة به",
                ),
                SizedBox(
                  height: 60,
                  child: _isCategoriesLoading
                      ? const Center(child: Loader())
                      : _buildMainCategoryList(
                          _allCategories.where((c) => c.parentId == null).toList(),
                        ),
                ),
                _buildSubCategoryList(),
                Expanded(child: _buildProductsGrid()),
                const SizedBox(height: 65.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategoryList(List<Category> mainCategories) {
    return ListView.builder(
      controller: _mainCategoryScrollController,
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
              _mainCategoryScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _loadProducts();
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
              _selectedSubCategoryId = null;
              _selectedSubIndex = -1;
            });
            final itemWidth = 100.0;
            final scrollPosition = index * itemWidth;
            _mainCategoryScrollController.animateTo(
              scrollPosition.clamp(0, _mainCategoryScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            _loadProducts();
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
        : _allCategories
              .where((c) => c.parentId == _selectedMainCategoryId)
              .toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
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
                              _loadProducts();
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
                            _loadProducts();
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
    if (_isProductsLoading) {
      return const Center(child: Loader());
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد منتجات في هذا التصنيف حالياً',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 9.0,
        crossAxisSpacing: 9.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
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
  }
}
