import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/widgets/product_card.dart';

class SectionPreviewPage extends StatefulWidget {
  final AdsSectionSettings section;
  
  const SectionPreviewPage({Key? key, required this.section}) : super(key: key);

  @override
  State<SectionPreviewPage> createState() => _SectionPreviewPageState();
}

class _SectionPreviewPageState extends State<SectionPreviewPage> {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final productsStream = _productService.getProducts();
      final allProducts = await productsStream.first;
      
      // أخذ عينة من المنتجات للمعاينة
      final sampleProducts = allProducts.take(widget.section.maxItems).toList();
      
      setState(() {
        _products = sampleProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: FlowerBackground(
          child: SafeArea(
            child: Column(
              children: [
                CustomAdminHeader(
                  title: 'معاينة قسم "${widget.section.title}"',
                  subtitle: 'كيف سيظهر القسم في التطبيق',
                ),
              Expanded(
                child: _isLoading
                    ? const Loader()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // معلومات القسم
                            _buildSectionInfo(),
                            const SizedBox(height: 20),
                            
                            // معاينة القسم
                            _buildSectionPreview(),
                            
                            const SizedBox(height: 30),
                            
                            // أزرار الإجراءات
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BBD9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF52002C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'معلومات القسم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52002C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('اسم القسم', widget.section.title),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoItem('الموضع', _getPositionText(widget.section.position)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem('عدد المنتجات', '${_products.length}'),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInfoItem('الحد الأقصى', '${widget.section.maxItems}'),
                  ),
                ],
              ),
              
              if (widget.section.description?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                _buildInfoItem('الوصف', widget.section.description!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: Color(0xFF52002C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8BBD9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Color(0xFF52002C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'معاينة القسم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF52002C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (_products.isEmpty)
                _buildEmptyPreview()
              else
                _buildProductsPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              'لا توجد منتجات في هذا القسم',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم كما سيظهر في التطبيق
        Text(
          widget.section.title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF52002C),
          ),
        ),
        const SizedBox(height: 15),
        
        // المنتجات في عرض أفقي
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = _products[index];
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: product,
                  onTap: () {
                    // معاينة فقط - لا إجراء
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
            onPressed: _refreshPreview,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              'تحديث المعاينة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8BBD9),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getPositionText(String position) {
    switch (position) {
      case 'top':
        return 'أعلى الصفحة';
      case 'middle':
        return 'وسط الصفحة';
      case 'bottom':
        return 'أسفل الصفحة';
      default:
        return position;
    }
  }

  void _refreshPreview() {
    setState(() {
      _isLoading = true;
    });
    _loadProducts();
  }
}
