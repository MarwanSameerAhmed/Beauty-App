import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/controller/ads_section_settings_service.dart';
import '../../model/ads_section_settings.dart';
import '../../widgets/backgroundUi.dart';
import '../../widgets/custom_admin_header.dart';
import '../../widgets/loader.dart';
import 'product_selection_page.dart';
import '../../utils/logger.dart';
import 'package:glamify/view/admin_view/section_preview_page.dart';


class ProductSectionManagementPage extends StatefulWidget {
  const ProductSectionManagementPage({Key? key}) : super(key: key);

  @override
  State<ProductSectionManagementPage> createState() => _ProductSectionManagementPageState();
}

class _ProductSectionManagementPageState extends State<ProductSectionManagementPage> {
  final AdsSectionSettingsService _settingsService = AdsSectionSettingsService();
  
  List<AdsSectionSettings> _productSections = [];
  Map<String, int> _sectionProductCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductSections();
  }

  Future<int> _getProductCountForSection(String sectionId) async {
    try {
      AppLogger.debug('محاولة تحميل عدد المنتجات', tag: 'PRODUCT_SECTION', data: {'sectionId': sectionId});
      final snapshot = await FirebaseFirestore.instance
          .collection('product_section_items')
          .where('sectionId', isEqualTo: sectionId)
          .get();
      AppLogger.info('تم تحميل عدد المنتجات', tag: 'PRODUCT_SECTION', data: {'count': snapshot.docs.length, 'sectionId': sectionId});
      return snapshot.docs.length;
    } catch (e) {
      AppLogger.error('خطأ في تحميل عدد المنتجات', tag: 'PRODUCT_SECTION', data: {'sectionId': sectionId}, error: e);
      return 0;
    }
  }

  Future<void> _loadProductSections() async {
    try {
      // تحميل الأقسام من قاعدة البيانات
      final snapshot = await FirebaseFirestore.instance
          .collection('ads_section_settings')
          .where('type', isEqualTo: 'products')
          .get();
      
      final sections = snapshot.docs.map((doc) {
        final data = doc.data();
        return AdsSectionSettings(
          id: doc.id,
          title: data['title'] ?? '',
          position: data['position'] ?? 'middle',
          order: data['order'] ?? 0,
          isVisible: data['isVisible'] ?? true,
          type: data['type'] ?? 'products',
          maxItems: data['maxItems'] ?? 6,
          description: data['description'],
        );
      }).toList();
      
      // ترتيب الأقسام يدوياً بعد جلبها
      sections.sort((a, b) => a.order.compareTo(b.order));
      
      // تحميل عدد المنتجات لكل قسم
      for (var section in sections) {
        final count = await _getProductCountForSection(section.id);
        _sectionProductCounts[section.id] = count;
      }
      
      setState(() {
        _productSections = sections;
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
            child: _isLoading
                ? const Loader()
                : Column(
                    children: [
                      const CustomAdminHeader(
                        title: 'إدارة أقسام المنتجات',
                        subtitle: 'اختر وأضف المنتجات لكل قسم',
                      ),
                      Expanded(
                        child: _productSections.isEmpty
                            ? _buildEmptyState()
                            : _buildSectionsList(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: const Color(0xFFF8BBD9).withOpacity(0.7),
                ),
                const SizedBox(height: 20),
                const Text(
                  'لا توجد أقسام منتجات',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF52002C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'قم بإنشاء أقسام منتجات أولاً من صفحة إدارة الأقسام',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _productSections.length,
      itemBuilder: (context, index) {
        final section = _productSections[index];
        return _buildSectionCard(section);
      },
    );
  }

  Widget _buildSectionCard(AdsSectionSettings section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                          Icons.inventory_2_outlined,
                          color: Color(0xFF52002C),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF52002C),
                              ),
                            ),
                            if (section.description?.isNotEmpty == true)
                              Text(
                                section.description!,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: section.isVisible,
                        onChanged: (value) => _toggleSectionVisibility(section.id, value),
                        activeColor: const Color(0xFFF8BBD9),
                        activeTrackColor: const Color(0xFFF8BBD9).withOpacity(0.3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // إحصائيات القسم
                  Row(
                    children: [
                      Flexible(
                        child: _buildStatCard(
                          'المنتجات المضافة',
                          '${_sectionProductCounts[section.id] ?? 0}',
                          Icons.shopping_bag_outlined,
                          const Color(0xFF52002C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildStatCard(
                          'الحد الأقصى',
                          '${section.maxItems}',
                          Icons.format_list_numbered,
                          const Color(0xFFF8BBD9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildStatCard(
                          'المتاح',
                          '${section.maxItems - (_sectionProductCounts[section.id] ?? 0)}',
                          Icons.add_circle_outline,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  // أزرار الإجراءات
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _manageProducts(section),
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'إدارة المنتجات',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF52002C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _previewSection(section),
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        label: const Text(
                          'معاينة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BBD9),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSectionVisibility(String sectionId, bool isVisible) {
    _settingsService.updateSectionVisibility(sectionId, isVisible);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isVisible ? 'تم إظهار القسم' : 'تم إخفاء القسم'),
        backgroundColor: Colors.green,
      ),
    );
    _loadProductSections();
  }

  void _manageProducts(AdsSectionSettings section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductSelectionPage(section: section),
      ),
    );
  }

  void _previewSection(AdsSectionSettings section) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SectionPreviewPage(section: section),
      ),
    );
  }
}
