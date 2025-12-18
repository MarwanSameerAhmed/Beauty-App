import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:test_pro/controller/ads_section_settings_service.dart';
import 'package:test_pro/model/ads_section_settings.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class HomeLayoutManager extends StatefulWidget {
  const HomeLayoutManager({Key? key}) : super(key: key);

  @override
  State<HomeLayoutManager> createState() => _HomeLayoutManagerState();
}

class _HomeLayoutManagerState extends State<HomeLayoutManager> {
  final AdsSectionSettingsService _settingsService = AdsSectionSettingsService();
  List<AdsSectionSettings> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _initializeCarouselSection() async {
    try {
      // التحقق من وجود قسم الكاروسيل
      final carouselExists = _sections.any((s) => s.isCarouselSection);
      
      if (!carouselExists) {
        final carouselSection = AdsSectionSettings.createCarouselSection(
          title: 'جديدنا',
          order: 0,
          description: 'البانر المتحرك في الصفحة الرئيسية',
        );
        
        await _settingsService.addNewSection(carouselSection);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة قسم الكاروسيل بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('قسم الكاروسيل موجود مسبقاً'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة قسم الكاروسيل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                  title: 'إدارة تخطيط الصفحة الرئيسية',
                  subtitle: 'تحكم في ترتيب جميع العناصر (كاروسيل، إعلانات، منتجات)',
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: Loader())
                      : _sections.isEmpty
                          ? _buildEmptyState()
                          : _buildSectionsList(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _initializeCarouselSection,
          backgroundColor: const Color(0xFF52002C),
          icon: const Icon(Icons.view_carousel, color: Colors.white),
          label: const Text(
            'إضافة الكاروسيل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_carousel_outlined,
            size: 100,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد أقسام في الصفحة الرئيسية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ابدأ بإضافة قسم الكاروسيل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sections.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return _buildSectionCard(section, index, key: ValueKey(section.id));
      },
    );
  }

  Widget _buildSectionCard(AdsSectionSettings section, int index, {required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: section.isVisible 
              ? const Color(0xFF52002C).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.drag_handle,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF52002C),
                        const Color(0xFF52002C).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    section.sectionIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ],
            ),
            title: Text(
              section.title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF52002C),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // نوع القسم - أكثر بروزاً
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: section.isCarouselSection 
                              ? [Colors.purple.shade400, Colors.purple.shade600]
                              : section.isAdsSection
                                  ? [Colors.blue.shade400, Colors.blue.shade600]
                                  : [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (section.isCarouselSection 
                                ? Colors.purple 
                                : section.isAdsSection 
                                    ? Colors.blue 
                                    : Colors.orange).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.typeIcon,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            section.isCarouselSection 
                                ? 'كاروسيل'
                                : section.isAdsSection 
                                    ? 'إعلانات'
                                    : 'منتجات',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // حالة الظهور
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: section.isVisible 
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: section.isVisible ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            section.isVisible ? Icons.visibility : Icons.visibility_off,
                            size: 14,
                            color: section.isVisible ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            section.isVisible ? 'ظاهر' : 'مخفي',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: section.isVisible ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // الترتيب
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52002C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF52002C),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.format_list_numbered,
                            size: 14,
                            color: Color(0xFF52002C),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Color(0xFF52002C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                section.isVisible ? Icons.visibility : Icons.visibility_off,
                color: section.isVisible ? Colors.green : Colors.grey,
              ),
              onPressed: () => _toggleVisibility(section),
            ),
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final section = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, section);
      
      // تحديث الترتيب في قاعدة البيانات
      _settingsService.reorderAllSections(_sections);
    });
  }

  Future<void> _toggleVisibility(AdsSectionSettings section) async {
    try {
      await _settingsService.updateSectionVisibility(section.id, !section.isVisible);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              section.isVisible ? 'تم إخفاء القسم' : 'تم إظهار القسم',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الرؤية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
