import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:test_pro/controller/ads_section_settings_service.dart';
import 'package:test_pro/model/ads_section_settings.dart';
import 'package:test_pro/view/admin_view/product_section_management_page.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class AdsSectionsManager extends StatefulWidget {
  const AdsSectionsManager({Key? key}) : super(key: key);

  @override
  State<AdsSectionsManager> createState() => _AdsSectionsManagerState();
}

class _AdsSectionsManagerState extends State<AdsSectionsManager>
    with SingleTickerProviderStateMixin {
  final AdsSectionSettingsService _settingsService = AdsSectionSettingsService();
  List<AdsSectionSettings> _sections = [];
  bool _isLoading = true;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _initializeSections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSections() async {
    // إنشاء الأقسام الافتراضية إذا لم تكن موجودة
    await _settingsService.initializeDefaultSections();
    _loadSections();
  }

  void _loadSections() {
    _settingsService.getSectionSettings().listen((sections) {
      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomAdminHeader(
                  title: 'إدارة الأقسام',
                  subtitle: 'تخصيص وترتيب أقسام الإعلانات والمنتجات في التطبيق',
                ),
                
                // التبويبات المحسنة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF52002C),
                              Color(0xFF7A0039),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF52002C).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF52002C),
                        labelStyle: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text('أقسام الإعلانات'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text('أقسام المنتجات'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: Loader())
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // تبويب أقسام الإعلانات
        _buildAdsSectionsTab(),
        // تبويب أقسام المنتجات
        _buildProductsSectionsTab(),
      ],
    );
  }

  Widget _buildAdsSectionsTab() {
    final adsSections = _sections.where((s) => s.isAdsSection).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // بطاقة المعلومات للإعلانات
          _buildAdsInfoCard(adsSections),
          const SizedBox(height: 20),
          
          // قائمة أقسام الإعلانات
          _buildAdsSectionsList(adsSections),
          
          const SizedBox(height: 20),
          
          // أزرار الإجراءات للإعلانات
          _buildAdsActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProductsSectionsTab() {
    final productsSections = _sections.where((s) => s.isProductsSection).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // بطاقة المعلومات للمنتجات
          _buildProductsInfoCard(productsSections),
          const SizedBox(height: 20),
          
          // قائمة أقسام المنتجات
          _buildProductsSectionsList(productsSections),
          
          const SizedBox(height: 20),
          
          // أزرار الإجراءات للمنتجات
          _buildProductsActionButtons(),
        ],
      ),
    );
  }

  // بطاقة معلومات أقسام الإعلانات
  Widget _buildAdsInfoCard(List<AdsSectionSettings> adsSections) {
    final visibleSections = adsSections.where((s) => s.isVisible).length;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF52002C).withOpacity(0.1),
                  const Color(0xFF7A0039).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        color: const Color(0xFF52002C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'أقسام الإعلانات',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52002C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'إجمالي الأقسام',
                        '${adsSections.length}',
                        Icons.folder_outlined,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        'الأقسام المرئية',
                        '$visibleSections',
                        Icons.visibility,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // بطاقة معلومات أقسام المنتجات
  Widget _buildProductsInfoCard(List<AdsSectionSettings> productsSections) {
    final visibleSections = productsSections.where((s) => s.isVisible).length;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.deepOrange.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'أقسام المنتجات',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Flexible(
                      child: _buildStatCard(
                        'إجمالي الأقسام',
                        '${productsSections.length}',
                        Icons.inventory_2_outlined,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _buildStatCard(
                        'الأقسام المرئية',
                        '$visibleSections',
                        Icons.visibility,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // بطاقة الإحصائيات
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
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
          const SizedBox(height: 4),
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

  // حالة فارغة
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // إعادة ترتيب الأقسام
  void _reorderSections(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final section = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, section);
    
    // تحديث الترتيب في قاعدة البيانات
    _settingsService.reorderAllSections(_sections);
  }


  // قائمة أقسام الإعلانات
  Widget _buildAdsSectionsList(List<AdsSectionSettings> adsSections) {
    if (adsSections.isEmpty) {
      return _buildEmptyState(
        'لا توجد أقسام إعلانات',
        'ابدأ بإضافة قسم إعلانات جديد',
        Icons.campaign_outlined,
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: adsSections.length,
      onReorder: _reorderSections,
      itemBuilder: (context, index) {
        final section = adsSections[index];
        return _buildSectionCard(section, index);
      },
    );
  }

  // قائمة أقسام المنتجات
  Widget _buildProductsSectionsList(List<AdsSectionSettings> productsSections) {
    if (productsSections.isEmpty) {
      return _buildEmptyState(
        'لا توجد أقسام منتجات',
        'ابدأ بإضافة قسم منتجات جديد',
        Icons.inventory_2_outlined,
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: productsSections.length,
      onReorder: _reorderSections,
      itemBuilder: (context, index) {
        final section = productsSections[index];
        return _buildSectionCard(section, index);
      },
    );
  }


  Widget _buildSectionCard(AdsSectionSettings section, int index, {Key? key}) {
    return Container(
      key: key ?? ValueKey(section.id),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: section.isProductsSection
                      ? Colors.orange
                      : const Color(0xFF52002C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  section.isProductsSection 
                      ? Icons.inventory_2_outlined
                      : Icons.campaign_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                section.title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'الموضع: ${_getPositionText(section.position)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (section.isProductsSection)
                    Text(
                      'عدد المنتجات: ${section.maxItems}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  if (section.description?.isNotEmpty == true)
                    Text(
                      section.description!,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: section.isVisible,
                    onChanged: (value) => _toggleSectionVisibility(section.id, value),
                    activeColor: section.isProductsSection
                        ? Colors.orange
                        : const Color(0xFF52002C),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(section);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(section);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('تعديل', style: TextStyle(fontFamily: 'Tajawal')),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'حذف',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
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

  void _showDeleteConfirmation(AdsSectionSettings section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'تأكيد الحذف',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Text(
            'هل أنت متأكد من حذف قسم "${section.title}"؟',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _settingsService.deleteSection(section.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف القسم بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في حذف القسم: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'حذف',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(AdsSectionSettings section) {
    final titleController = TextEditingController(text: section.title);
    String selectedPosition = section.position;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تعديل القسم',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'موضع القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'top', child: Text('أعلى الصفحة')),
                      DropdownMenuItem(value: 'middle', child: Text('وسط الصفحة')),
                      DropdownMenuItem(value: 'bottom', child: Text('أسفل الصفحة')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPosition = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final updatedSection = section.copyWith(
                        title: titleController.text.trim(),
                        position: selectedPosition,
                      );
                      await _settingsService.updateSectionSettings(updatedSection);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث القسم بنجاح'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطأ في تحديث القسم: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            );
          },
        );
      },
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
  }

  // أزرار الإجراءات لأقسام الإعلانات
  Widget _buildAdsActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showAddSectionDialog('ads'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'إضافة قسم إعلانات جديد',
              style: TextStyle(
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
    );
  }

  // أزرار الإجراءات لأقسام المنتجات
  Widget _buildProductsActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showAddSectionDialog('products'),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'إضافة قسم منتجات جديد',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_sections.where((s) => s.isProductsSection).isNotEmpty)
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              onPressed: _showProductSectionManagementDialog,
              icon: const Icon(Icons.inventory_2_outlined, color: Colors.orange),
              label: const Text(
                'إدارة أقسام المنتجات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
      ],
    );
  }



  // إضافة قسم جديد
  void _showAddSectionDialog(String type) {
    final titleController = TextEditingController();
    String selectedPosition = 'top';
    int maxItems = type == 'products' ? 6 : 10;
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type == 'products' ? 'إضافة قسم منتجات جديد' : 'إضافة قسم إعلانات جديد',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52002C),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'اسم القسم',
                            labelStyle: TextStyle(fontFamily: 'Tajawal'),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        const SizedBox(height: 15),
                        if (type == 'products') ...[
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'وصف القسم (اختياري)',
                              labelStyle: TextStyle(fontFamily: 'Tajawal'),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontFamily: 'Tajawal'),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              const Text(
                                'عدد المنتجات: ',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                              Expanded(
                                child: Slider(
                                  value: maxItems.toDouble(),
                                  min: 2,
                                  max: 20,
                                  divisions: 18,
                                  label: maxItems.toString(),
                                  onChanged: (value) {
                                    setState(() {
                                      maxItems = value.round();
                                    });
                                  },
                                ),
                              ),
                              Text(
                                maxItems.toString(),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                        DropdownButtonFormField<String>(
                          value: selectedPosition,
                          decoration: const InputDecoration(
                            labelText: 'موضع القسم',
                            labelStyle: TextStyle(fontFamily: 'Tajawal'),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'top', child: Text('أعلى الصفحة')),
                            DropdownMenuItem(value: 'middle', child: Text('وسط الصفحة')),
                            DropdownMenuItem(value: 'bottom', child: Text('أسفل الصفحة')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPosition = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () async {
                                  if (titleController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('يرجى إدخال اسم القسم'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    if (type == 'products') {
                                      await _settingsService.addProductSection(
                                        title: titleController.text.trim(),
                                        position: selectedPosition,
                                        maxItems: maxItems,
                                        description: descriptionController.text.trim().isEmpty
                                            ? null
                                            : descriptionController.text.trim(),
                                      );
                                    } else {
                                      final section = AdsSectionSettings(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        title: titleController.text.trim(),
                                        position: selectedPosition,
                                        order: _sections.length,
                                        isVisible: true,
                                        type: 'ads',
                                        maxItems: 10,
                                      );
                                      await _settingsService.addNewSection(section);
                                    }

                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم إضافة القسم بنجاح'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadSections();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('خطأ في إضافة القسم: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF52002C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'إضافة',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          color: Colors.white,
                                        ),
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
            );
          },
        );
      },
    );
  }

  // إدارة محتوى أقسام المنتجات
  void _showProductSectionManagementDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductSectionManagementPage(),
      ),
    );
  }


  void _resetToDefaults() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'إعادة تعيين للافتراضي',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: const Text(
            'هل أنت متأكد من إعادة تعيين جميع الأقسام للإعدادات الافتراضية؟ سيتم حذف جميع الأقسام المخصصة.',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _settingsService.initializeDefaultSections();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إعادة تعيين الأقسام بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ في إعادة التعيين: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'إعادة تعيين',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleSectionVisibility1(String sectionId, bool isVisible) {
    _settingsService.updateSectionVisibility(sectionId, isVisible);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isVisible ? 'تم إظهار القسم' : 'تم إخفاء القسم'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showEditDialog1(AdsSectionSettings section) {
    final titleController = TextEditingController(text: section.title);
    String selectedPosition = section.position;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تعديل القسم',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'موضع القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'top', child: Text('أعلى الصفحة')),
                      DropdownMenuItem(value: 'middle', child: Text('وسط الصفحة')),
                      DropdownMenuItem(value: 'bottom', child: Text('أسفل الصفحة')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPosition = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateSection(section, titleController.text, selectedPosition);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateSection(AdsSectionSettings section, String newTitle, String newPosition) {
    final updatedSection = section.copyWith(
      title: newTitle,
      position: newPosition,
    );
    
    _settingsService.updateSectionSettings(updatedSection);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديث القسم بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAddSectionDialog1() {
    final titleController = TextEditingController();
    String selectedPosition = 'middle';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'إضافة قسم جديد',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedPosition,
                    decoration: const InputDecoration(
                      labelText: 'موضع القسم',
                      labelStyle: TextStyle(fontFamily: 'Tajawal'),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'top', child: Text('أعلى الصفحة')),
                      DropdownMenuItem(value: 'middle', child: Text('وسط الصفحة')),
                      DropdownMenuItem(value: 'bottom', child: Text('أسفل الصفحة')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPosition = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      _addNewSection(titleController.text, selectedPosition);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text(
                    'إضافة',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addNewSection(String title, String position) {
    final newSection = AdsSectionSettings.createNewSection(
      title: title,
      position: position,
      order: _sections.length,
    );
    
    _settingsService.addNewSection(newSection);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة القسم بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  bool _isDefaultSection(String sectionId) {
    return ['top_section', 'middle_section', 'bottom_section'].contains(sectionId);
  }

  void _showDeleteDialog(AdsSectionSettings section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'حذف القسم',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Text(
            'هل أنت متأكد من حذف قسم "${section.title}"؟\nسيتم نقل جميع الإعلانات في هذا القسم إلى القسم الافتراضي.',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteSection(section);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSection(AdsSectionSettings section) {
    _settingsService.deleteSection(section.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف قسم "${section.title}" بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults1() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'إعادة تعيين للافتراضي',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: const Text(
            'هل أنت متأكد من إعادة تعيين جميع إعدادات الأقسام للقيم الافتراضية؟',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _settingsService.resetToDefaults();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إعادة تعيين الإعدادات بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'إعادة تعيين',
                style: TextStyle(fontFamily: 'Tajawal', color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'top':
        return Colors.green;
      case 'bottom':
        return Colors.blue;
      default:
        return const Color(0xFF52002C);
    }
  }

  IconData _getPositionIcon(String position) {
    switch (position) {
      case 'top':
        return Icons.keyboard_arrow_up;
      case 'bottom':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }

  String _getPositionText2(String position) {
    switch (position) {
      case 'top':
        return 'أعلى الصفحة';
      case 'bottom':
        return 'أسفل الصفحة';
      default:
        return 'وسط الصفحة';
    }
  }
}
