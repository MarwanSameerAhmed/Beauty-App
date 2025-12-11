import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/services/pdf_invoice_service.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class CreateInvoicePage extends StatefulWidget {
  const CreateInvoicePage({super.key});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final ProductService _productService = ProductService();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerEmailController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  final List<InvoiceItem> _selectedItems = [];
  bool _isLoading = false;
  bool _isCreatingInvoice = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
      });
    } catch (e) {
      _showErrorSnackBar('خطأ في تحميل المنتجات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.description.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _addProductToInvoice(Product product) {
    final existingIndex = _selectedItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      setState(() {
        _selectedItems[existingIndex].quantity++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم زيادة كمية ${product.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      _showPriceDialog(product);
    }
  }

  void _showPriceDialog(Product product) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52002C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.price_change_rounded,
                    color: Color(0xFF52002C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تحديد السعر',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'السعر المخصص',
                  hintText: 'سعر الوحدة: ${product.price.toStringAsFixed(2)} ريال',
                  labelStyle: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey.shade600,
                  ),
                  hintStyle: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.orange.shade600,
                    fontSize: 14,
                  ),
                  suffixText: 'ريال',
                  suffixStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF52002C),
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF52002C),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextButton(
                  onPressed: () {
                    final price = double.tryParse(priceController.text);
                    if (price != null && price > 0) {
                      setState(() {
                        _selectedItems.add(
                          InvoiceItem(
                            productId: product.id,
                            productName: product.name,
                            originalPrice: product.price,
                            customPrice: price,
                            quantity: 1,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم إضافة ${product.name} بسعر ${price.toStringAsFixed(2)} ريال',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى إدخال سعر صحيح'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'إضافة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeItemFromInvoice(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _removeItemFromInvoice(index);
    } else {
      setState(() {
        _selectedItems[index].quantity = quantity;
      });
    }
  }

  void _updateItemPrice(int index, double price) {
    setState(() {
      _selectedItems[index].customPrice = price;
    });
  }

  double get _totalAmount {
    return _selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.customPrice * item.quantity),
    );
  }

  Future<void> _createInvoice() async {
    if (_selectedItems.isEmpty) {
      _showErrorSnackBar('يرجى اختيار منتجات للفاتورة');
      return;
    }

    if (_customerNameController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم العميل');
      return;
    }

    if (_customerEmailController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال بريد العميل الإلكتروني');
      return;
    }

    setState(() => _isCreatingInvoice = true);

    try {
      // تحويل العناصر إلى التنسيق المطلوب
      final items = _selectedItems
          .map(
            (item) => {
              'name': item.productName,
              'quantity': item.quantity,
              'price': item.customPrice,
              'originalPrice': item.originalPrice, // إضافة السعر الأصلي
              'total': item.customPrice * item.quantity,
            },
          )
          .toList();

      final pdfFile = await PdfInvoiceService.generateInvoice(
        customerName: _customerNameController.text.isEmpty
            ? 'عميل'
            : _customerNameController.text,
        customerEmail: _customerEmailController.text,
        items: items,
        totalPrice: _totalAmount,
        orderNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (pdfFile != null) {
          // مشاركة الفاتورة
          if (pdfFile is File) {
            await Share.shareXFiles(
              [XFile(pdfFile.path)],
              text:
                  'فاتورة ${_customerNameController.text.isEmpty ? "عميل" : _customerNameController.text}',
            );
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء ومشاركة الفاتورة بنجاح!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _resetForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إنشاء الفاتورة'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في إنشاء الفاتورة: $e');
    } finally {
      setState(() => _isCreatingInvoice = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedItems.clear();
      _customerNameController.clear();
      _customerEmailController.clear();
      _searchController.clear();
      _filteredProducts = _allProducts;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              children: [
                const CustomAdminHeader(
                  title: 'إنشاء فاتورة',
                  subtitle: 'اختر المنتجات وقم بتسعيرها',
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: Loader())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 900) {
                              return _buildDesktopLayout();
                            } else {
                              return _buildMobileLayout();
                            }
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

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildProductsSection()),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: _buildInvoiceSection()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF9D5D3).withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: TabBar(
              padding: const EdgeInsets.all(6),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFFF9D5D3).withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Tajawal',
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('المنتجات'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('الفاتورة'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductsSection(), 
                _buildMobileInvoiceSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInvoiceSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInvoiceHeader(),
          _buildCustomerInfo(),
          Expanded(
            child: _buildInvoiceItems(),
          ),
          _buildInvoiceTotal(),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _buildModernProductCard(_filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF9D5D3).withOpacity(0.4),
            const Color(0xFFFFE4E1).withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterProducts,
        decoration: InputDecoration(
          hintText: 'ابحث عن منتج...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontFamily: 'Tajawal',
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterProducts('');
                  },
                  icon: Icon(Icons.clear, color: Colors.grey.shade500),
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: const Color(0xFFFF69B4).withOpacity(0.8),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: -3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.inventory, color: Colors.grey.shade400),
                      ),
                    )
                  : Icon(Icons.inventory, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D5D3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _addProductToInvoice(product),
                    icon: const Icon(
                      Icons.add_shopping_cart,
                      color: Colors.black87,
                    ),
                    tooltip: 'إضافة للفاتورة',
                  ),
                ),
                if (_selectedItems.any((item) => item.productId == product.id))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${_selectedItems.firstWhere((item) => item.productId == product.id).quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب البحث بكلمات أخرى',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildInvoiceHeader(),
                    _buildCustomerInfo(),
                    Expanded(
                      child: _buildInvoiceItems(),
                    ),
                    _buildInvoiceTotal(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF9D5D3).withOpacity(0.8),
            const Color(0xFFFFE4E1).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'الفاتورة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Tajawal',
            ),
          ),
          const Spacer(),
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9D5D3).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF9D5D3).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_selectedItems.length} منتج',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.7),
            Colors.white.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات العميل',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildCustomerField(
                  controller: _customerNameController,
                  label: 'اسم العميل',
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCustomerField(
                  controller: _customerEmailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF9D5D3).withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 13,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontFamily: 'Tajawal',
            fontSize: 11,
          ),
          prefixIcon: Icon(icon, color: Colors.black87, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildInvoiceItems() {
    if (_selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد منتجات في الفاتورة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _selectedItems.length,
      itemBuilder: (context, index) {
        return _buildModernInvoiceItem(index);
      },
    );
  }

  Widget _buildModernInvoiceItem(int index) {
    final item = _selectedItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            const Color(0xFFF9D5D3).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D5D3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Tajawal',
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: IconButton(
                    onPressed: () => _removeItemFromInvoice(index),
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    tooltip: 'حذف',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300) {
                  // للشاشات الصغيرة جداً - عمود واحد
                  return Column(
                    children: [
                      _buildQuantityControls(index),
                      const SizedBox(height: 4),
                      _buildPriceField(index),
                    ],
                  );
                } else {
                  // للشاشات العادية - صف واحد
                  return Row(
                    children: [
                      Expanded(child: _buildQuantityControls(index)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildPriceField(index)),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF9D5D3).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF9D5D3).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                'المجموع: ${(item.customPrice * item.quantity).toStringAsFixed(2)} ريال',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF1493),
                  fontSize: 8,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(int index) {
    final item = _selectedItems[index];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            const Color(0xFFF9D5D3).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF9D5D3).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9D5D3).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9D5D3).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF9D5D3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _updateItemQuantity(index, item.quantity - 1),
              icon: const Icon(
                Icons.remove_rounded,
                size: 12,
                color: Colors.black87,
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9D5D3).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF9D5D3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _updateItemQuantity(index, item.quantity + 1),
              icon: const Icon(
                Icons.add_rounded,
                size: 12,
                color: Colors.black87,
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(int index) {
    final item = _selectedItems[index];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            const Color(0xFFF9D5D3).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFF9D5D3).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9D5D3).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: item.customPrice.toString(),
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF1493),
          fontSize: 12,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: InputBorder.none,
          suffix: Text(
            'ريال',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Tajawal',
              color: Color(0xFFF9D5D3),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onChanged: (value) {
          final price = double.tryParse(value) ?? item.originalPrice;
          _updateItemPrice(index, price);
        },
      ),
    );
  }

  Widget _buildInvoiceTotal() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF9D5D3).withOpacity(0.7),
            const Color(0xFFFFE4E1).withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontFamily: 'Tajawal',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.8),
                      const Color(0xFF81C784).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${_totalAmount.toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D5D3).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _resetForm,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'إعادة تعيين',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF52002C),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF52002C).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingInvoice ? null : _createInvoice,
                    icon: _isCreatingInvoice
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                    label: Text(
                      _isCreatingInvoice ? 'جاري الإنشاء...' : 'إنشاء فاتورة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// فئة لتمثيل عنصر في الفاتورة
class InvoiceItem {
  final String productId;
  final String productName;
  final double originalPrice;
  double customPrice;
  int quantity;

  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.originalPrice,
    required this.customPrice,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': productName,
      'originalPrice': originalPrice,
      'price': customPrice,
      'quantity': quantity,
    };
  }
}
