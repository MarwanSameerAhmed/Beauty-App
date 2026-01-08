import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/ad.dart';
import '../../model/carousel_ad.dart';
import '../../model/ads_section_settings.dart';
import '../../widgets/backgroundUi.dart';
import '../../widgets/custom_admin_header.dart';
import '../../utils/logger.dart';

class AdsLayoutManager extends StatefulWidget {
  const AdsLayoutManager({super.key});

  @override
  State<AdsLayoutManager> createState() => _AdsLayoutManagerState();
}

class _AdsLayoutManagerState extends State<AdsLayoutManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Ad> _ads = [];
  List<CarouselAd> _carouselAds = [];
  List<AdsSectionSettings> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    try {
      // جلب الأقسام أولاً
      await _loadSections();
      
      // جلب الإعلانات الثابتة
      final adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .get();
      
      _ads = adsSnapshot.docs
          .map((doc) => Ad.fromMap(doc.data(), doc.id))
          .toList();
      
      // ترتيب الإعلانات حسب القسم ثم حسب order
      _ads.sort((a, b) {
        // أولاً ترتيب حسب القسم
        final sectionA = _sections.firstWhere((s) => s.id == a.sectionId, 
            orElse: () => _sections.first);
        final sectionB = _sections.firstWhere((s) => s.id == b.sectionId, 
            orElse: () => _sections.first);
        
        final sectionComparison = sectionA.order.compareTo(sectionB.order);
        if (sectionComparison != 0) return sectionComparison;
        
        // ثم ترتيب حسب order داخل القسم
        return a.order.compareTo(b.order);
      });
      
      AppLogger.info('Loaded ads', tag: 'ADS_LAYOUT', data: {'count': _ads.length});

      // جلب البانر المتحرك
      final carouselSnapshot = await FirebaseFirestore.instance
          .collection('carousel_ads')
          .get();
      
      _carouselAds = carouselSnapshot.docs
          .map((doc) => CarouselAd.fromMap(doc.data(), doc.id))
          .toList();
      
      // ترتيب البانر المتحرك حسب order (الافتراضي 0)
      _carouselAds.sort((a, b) => a.order.compareTo(b.order));
      
      AppLogger.info('Loaded carousel ads', tag: 'ADS_LAYOUT', data: {'count': _carouselAds.length});

    } catch (e) {
      AppLogger.error('Error loading ads', tag: 'ADS_LAYOUT', error: e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSections() async {
    try {
      final sectionsSnapshot = await FirebaseFirestore.instance
          .collection('ads_section_settings')
          .orderBy('order')
          .get();
      
      // فلترة أقسام الإعلانات فقط محلياً
      _sections = sectionsSnapshot.docs
          .map((doc) => AdsSectionSettings.fromMap({...doc.data(), 'id': doc.id}))
          .where((section) => section.type == 'ads')  // فلترة محلية
          .toList();
      
      // تم تعطيل إنشاء الأقسام الافتراضية التلقائي
      // يمكن للأدمن إضافة الأقسام يدوياً من صفحة إدارة الأقسام
    } catch (e) {
      AppLogger.error('Error loading sections', tag: 'ADS_LAYOUT', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              children: [
                const CustomAdminHeader(
                  title: 'إدارة مواضع الإعلانات',
                  subtitle: 'تحكم في ترتيب وإخفاء الإعلانات والبانرات',
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
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.view_module_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('الإعلانات الثابتة'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.slideshow_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('البانر المتحرك'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // محتوى التبويبات
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF52002C),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStaticAdsTab(),
                            _buildCarouselAdsTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticAdsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // معلومات إرشادية
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'الإعلانات منظمة حسب الأقسام. يمكنك سحب الإعلانات داخل كل قسم أو نقلها بين الأقسام',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // عرض الإعلانات حسب الأقسام
          Expanded(
            child: _ads.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.ad_units_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد إعلانات ثابتة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'أضف إعلانات من قسم "البانر المتحرك"',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildSectionizedAdsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionizedAdsView() {
    return ListView.builder(
      itemCount: _sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = _sections[sectionIndex];
        final sectionAds = _ads.where((ad) => ad.sectionId == section.id).toList();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان القسم
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF52002C).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSectionIcon(section.position),
                      color: const Color(0xFF52002C),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52002C),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52002C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${sectionAds.length}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // إعلانات القسم
              if (sectionAds.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  child: const Center(
                    child: Text(
                      'لا توجد إعلانات في هذا القسم',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sectionAds.length,
                  onReorder: (oldIndex, newIndex) => _reorderAdsInSection(section.id, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final ad = sectionAds[index];
                    return _buildSectionAdCard(ad, section, index);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getSectionIcon(String position) {
    switch (position) {
      case 'top':
        return Icons.keyboard_arrow_up;
      case 'bottom':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.remove;
    }
  }

  void _reorderAdsInSection(String sectionId, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      
      // الحصول على إعلانات القسم
      final sectionAds = _ads.where((ad) => ad.sectionId == sectionId).toList();
      
      if (oldIndex < sectionAds.length && newIndex < sectionAds.length) {
        // إعادة ترتيب الإعلانات داخل القسم
        final movedAd = sectionAds.removeAt(oldIndex);
        sectionAds.insert(newIndex, movedAd);
        
        // تحديث order للإعلانات في القسم
        for (int i = 0; i < sectionAds.length; i++) {
          sectionAds[i] = sectionAds[i].copyWith(order: i);
        }
        
        // تحديث القائمة الرئيسية
        _ads.removeWhere((ad) => ad.sectionId == sectionId);
        _ads.addAll(sectionAds);
        
        // إعادة ترتيب القائمة الرئيسية
        _sortAds();
      }
    });
    
    // حفظ التغييرات في قاعدة البيانات
    _saveAdsOrder();
  }

  Widget _buildSectionAdCard(Ad ad, AdsSectionSettings section, int index) {
    return Card(
      key: ValueKey(ad.id),
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            title: Text(
              ad.companyName,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ad.shapeType == 'rectangle' ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ad.shapeType == 'rectangle' ? 'مستطيل' : 'مربع',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'الترتيب: ${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر إخفاء/إظهار الإعلان
                IconButton(
                  onPressed: () => _toggleAdVisibility(ad),
                  icon: Icon(
                    ad.isVisible ? Icons.visibility : Icons.visibility_off,
                    color: ad.isVisible ? const Color(0xFF52002C) : Colors.grey,
                  ),
                  tooltip: ad.isVisible ? 'إخفاء الإعلان' : 'إظهار الإعلان',
                ),
                // زر نقل إلى قسم آخر
                IconButton(
                  onPressed: () => _showMoveSectionDialog(ad),
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF52002C)),
                  tooltip: 'نقل إلى قسم آخر',
                ),
                // أيقونة السحب
                const Icon(
                  Icons.drag_handle,
                  color: Color(0xFF52002C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoveSectionDialog(Ad ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'نقل الإعلان إلى قسم آخر',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sections.map((section) {
              final isCurrentSection = section.id == ad.sectionId;
              return ListTile(
                leading: Icon(
                  _getSectionIcon(section.position),
                  color: isCurrentSection ? Colors.grey : const Color(0xFF52002C),
                ),
                title: Text(
                  section.title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: isCurrentSection ? Colors.grey : Colors.black,
                  ),
                ),
                subtitle: Text(
                  isCurrentSection ? 'القسم الحالي' : 'انقر للنقل',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                enabled: !isCurrentSection,
                onTap: isCurrentSection ? null : () {
                  _moveAdToSection(ad, section.id);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _moveAdToSection(Ad ad, String newSectionId) {
    setState(() {
      // تحديث sectionId للإعلان
      final updatedAd = ad.copyWith(sectionId: newSectionId);
      
      // استبدال الإعلان في القائمة
      final index = _ads.indexWhere((a) => a.id == ad.id);
      if (index != -1) {
        _ads[index] = updatedAd;
      }
      
      // إعادة ترتيب القائمة
      _sortAds();
    });
    
    // حفظ التغييرات في قاعدة البيانات
    _saveAdSection(ad.id, newSectionId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نقل الإعلان بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sortAds() {
    _ads.sort((a, b) {
      // أولاً ترتيب حسب القسم
      final sectionA = _sections.firstWhere((s) => s.id == a.sectionId, 
          orElse: () => _sections.first);
      final sectionB = _sections.firstWhere((s) => s.id == b.sectionId, 
          orElse: () => _sections.first);
      
      final sectionComparison = sectionA.order.compareTo(sectionB.order);
      if (sectionComparison != 0) return sectionComparison;
      
      // ثم ترتيب حسب order داخل القسم
      return a.order.compareTo(b.order);
    });
  }

  Future<void> _saveAdsOrder() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final ad in _ads) {
        final docRef = FirebaseFirestore.instance.collection('ads').doc(ad.id);
        batch.update(docRef, {'order': ad.order});
      }
      
      await batch.commit();
    } catch (e) {
      AppLogger.error('Error saving ads order', tag: 'ADS_LAYOUT', error: e);
    }
  }

  Future<void> _saveAdSection(String adId, String sectionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'sectionId': sectionId});
    } catch (e) {
      AppLogger.error('Error saving ad section', tag: 'ADS_LAYOUT', error: e);
    }
  }

  void _toggleAdVisibility(Ad ad) {
    final newVisibility = !ad.isVisible;
    
    setState(() {
      final index = _ads.indexWhere((a) => a.id == ad.id);
      if (index != -1) {
        _ads[index] = ad.copyWith(isVisible: newVisibility);
      }
    });
    
    // حفظ التغيير في قاعدة البيانات
    FirebaseFirestore.instance
        .collection('ads')
        .doc(ad.id)
        .update({'isVisible': newVisibility});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newVisibility ? 'تم إظهار الإعلان' : 'تم إخفاء الإعلان'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleCarouselAdVisibility(String carouselAdId, bool isVisible) {
    setState(() {
      final index = _carouselAds.indexWhere((ad) => ad.id == carouselAdId);
      if (index != -1) {
        _carouselAds[index] = _carouselAds[index].copyWith(isVisible: isVisible);
      }
    });
    
    // حفظ التغيير في قاعدة البيانات
    FirebaseFirestore.instance
        .collection('carousel_ads')
        .doc(carouselAdId)
        .update({'isVisible': isVisible});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isVisible ? 'تم إظهار البانر' : 'تم إخفاء البانر'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildCarouselAdsTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // معلومات إرشادية
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.slideshow, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'رتب صور البانر المتحرك حسب الأولوية في العرض',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة البانر المتحرك
          Expanded(
            child: _carouselAds.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.slideshow_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد بانرات متحركة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'أضف بانرات من قسم "البانر المتحرك"',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: _carouselAds.length,
                    onReorder: (oldIndex, newIndex) => _reorderCarouselAds(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final carouselAd = _carouselAds[index];
                      return _buildCarouselAdCard(carouselAd, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildCarouselAdCard(CarouselAd carouselAd, int index) {
    return Card(
      key: ValueKey(carouselAd.id),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: carouselAd.isVisible 
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // صورة البانر
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(carouselAd.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // معلومات البانر
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carouselAd.companyName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ترتيب العرض: ${index + 1}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // مفتاح الإخفاء/الإظهار
                Switch(
                  value: carouselAd.isVisible,
                  onChanged: (value) => _toggleCarouselAdVisibility(carouselAd.id, value),
                  activeColor: const Color(0xFF52002C),
                ),
                
                // أيقونة السحب
                const Icon(
                  Icons.drag_handle,
                  color: Color(0xFF52002C),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 


  void _reorderCarouselAds(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final carouselAd = _carouselAds.removeAt(oldIndex);
      _carouselAds.insert(newIndex, carouselAd);
    });
    _updateCarouselAdsOrder();
  }

 

  Future<void> _updateCarouselAdsOrder() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < _carouselAds.length; i++) {
        final docRef = FirebaseFirestore.instance.collection('carousel_ads').doc(_carouselAds[i].id);
        batch.update(docRef, {'order': i});
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث ترتيب البانر المتحرك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الترتيب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



    }
