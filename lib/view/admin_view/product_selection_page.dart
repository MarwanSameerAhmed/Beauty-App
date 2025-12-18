import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/product.dart';
import '../../model/ads_section_settings.dart';
import '../../widgets/backgroundUi.dart';
import '../../controller/product_service.dart';
import '../../utils/logger.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';

class ProductSelectionPage extends StatefulWidget {
  final AdsSectionSettings section;
  
  const ProductSelectionPage({Key? key, required this.section}) : super(key: key);

  @override
  State<ProductSelectionPage> createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  final ProductService _productService = ProductService();
  
  List<Product> _allProducts = [];
  List<Product> _selectedProducts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final productsStream = _productService.getProducts();
      final products = await productsStream.first;
      
      setState(() {
        _allProducts = products;
      });
      
      // تحميل المنتجات المختارة بعد تحميل جميع المنتجات
      await _loadSelectedProducts();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSelectedProducts() async {
    try {
      AppLogger.debug('محاولة تحميل المنتجات المختارة', tag: 'PRODUCT_SELECTION', data: {'sectionId': widget.section.id});
      final snapshot = await FirebaseFirestore.instance
          .collection('product_section_items')
          .where('sectionId', isEqualTo: widget.section.id)
          .orderBy('order')
          .get();
      
      AppLogger.info('تم العثور على عناصر في قاعدة البيانات', tag: 'PRODUCT_SELECTION', data: {'count': snapshot.docs.length});
      
      List<Product> selectedProducts = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final productId = data['productId'];
        AppLogger.debug('البحث عن المنتج', tag: 'PRODUCT_SELECTION', data: {'productId': productId});
        
        // البحث عن المنتج في قائمة جميع المنتجات المحملة مسبقاً
        final productIndex = _allProducts.indexWhere((p) => p.id == productId);
        
        if (productIndex != -1) {
          selectedProducts.add(_allProducts[productIndex]);
          AppLogger.info('تم العثور على المنتج', tag: 'PRODUCT_SELECTION', data: {'productName': _allProducts[productIndex].name});
        } else {
          AppLogger.warning('لم يتم العثور على المنتج', tag: 'PRODUCT_SELECTION', data: {'productId': productId});
        }
      }
      
      AppLogger.info('إجمالي المنتجات المختارة', tag: 'PRODUCT_SELECTION', data: {'totalSelected': selectedProducts.length});
      
      setState(() {
        _selectedProducts = selectedProducts;
      });
    } catch (e) {
      AppLogger.error('خطأ في تحميل المنتجات المختارة', tag: 'PRODUCT_SELECTION', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FlowerBackground(
          child: _isLoading
              ? const Loader()
              : SafeArea(
                  child: Column(
                    children: [
                      CustomAdminHeader(
                        title: 'إدارة منتجات قسم "${widget.section.title}"',
                        subtitle: 'اختر وأضف المنتجات للقسم (الحد الأقصى: ${widget.section.maxItems})',
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // إذا كانت الشاشة صغيرة، استخدم عرض عمودي
                          if (constraints.maxWidth < 800) {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 400,
                                    child: _buildAllProductsList(),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 400,
                                    child: _buildSelectedProductsList(),
                                  ),
                                ],
                              ),
                            );
                          }
                          // للشاشات الكبيرة، استخدم عرض أفقي
                          return Row(
                            children: [
                              Expanded(
                                child: _buildAllProductsList(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSelectedProductsList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _buildActionButtons(),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildAllProductsList() {
    final filteredProducts = _allProducts.where((product) {
      final isNotSelected = !_selectedProducts.any((selected) => selected.id == product.id);
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return isNotSelected && matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52002C).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF52002C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'جميع المنتجات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF52002C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'البحث في المنتجات...',
                          hintStyle: const TextStyle(fontFamily: 'Tajawal'),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                        ),
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? _buildEmptyState('لا توجد منتجات متاحة', Icons.inventory_2_outlined)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product, false);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedProductsList() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8BBD9).withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8BBD9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Color(0xFF52002C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'المنتجات المختارة (${_selectedProducts.length}/${widget.section.maxItems})',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52002C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _selectedProducts.isEmpty
                      ? _buildEmptyState('لم يتم اختيار منتجات بعد', Icons.shopping_cart_outlined)
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _selectedProducts.length,
                          onReorder: _reorderProducts,
                          itemBuilder: (context, index) {
                            final product = _selectedProducts[index];
                            return _buildProductCard(product, true, key: ValueKey(product.id));
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSelected, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
              title: Text(
                product.name,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${product.price} ر.س',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Color(0xFF52002C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.drag_handle, color: Colors.grey),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _removeProduct(product),
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: _selectedProducts.length < widget.section.maxItems
                          ? () => _addProduct(product)
                          : null,
                      icon: Icon(
                        Icons.add_circle,
                        color: _selectedProducts.length < widget.section.maxItems
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFF8BBD9).withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: Color(0xFF52002C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text(
                'رجوع',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52002C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct(Product product) {
    if (_selectedProducts.length >= widget.section.maxItems) return;

    setState(() {
      _selectedProducts.add(product);
    });
  }

  void _removeProduct(Product product) {
    setState(() {
      _selectedProducts.removeWhere((p) => p.id == product.id);
    });
  }

  void _reorderProducts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final product = _selectedProducts.removeAt(oldIndex);
      _selectedProducts.insert(newIndex, product);
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      AppLogger.info('بدء حفظ المنتجات', tag: 'PRODUCT_SELECTION', data: {'count': _selectedProducts.length, 'sectionId': widget.section.id});
      
      // حذف المنتجات الموجودة مسبقاً لهذا القسم
      final existingItems = await FirebaseFirestore.instance
          .collection('product_section_items')
          .where('sectionId', isEqualTo: widget.section.id)
          .get();
      
      for (var doc in existingItems.docs) {
        await doc.reference.delete();
      }
      AppLogger.info('تم حذف عناصر موجودة مسبقاً', tag: 'PRODUCT_SELECTION', data: {'deletedCount': existingItems.docs.length});
      
      // إضافة المنتجات المختارة الجديدة
      for (int i = 0; i < _selectedProducts.length; i++) {
        final product = _selectedProducts[i];
        await FirebaseFirestore.instance
            .collection('product_section_items')
            .add({
          'sectionId': widget.section.id,
          'productId': product.id,
          'order': i,
          'createdAt': FieldValue.serverTimestamp(),
        });
        AppLogger.debug('تم حفظ المنتج', tag: 'PRODUCT_SELECTION', data: {'productName': product.name});
      }
      
      AppLogger.info('تم حفظ جميع المنتجات بنجاح', tag: 'PRODUCT_SELECTION');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ ${_selectedProducts.length} منتج بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      AppLogger.error('خطأ في حفظ المنتجات', tag: 'PRODUCT_SELECTION', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ التغييرات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
}
