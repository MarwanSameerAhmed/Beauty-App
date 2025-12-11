import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/ad.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';

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
      // جلب الإعلانات الثابتة
      final adsSnapshot = await FirebaseFirestore.instance
          .collection('ads')
          .get();
      
      _ads = adsSnapshot.docs
          .map((doc) => Ad.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      // ترتيب الإعلانات حسب order (الافتراضي 0)
      _ads.sort((a, b) => a.order.compareTo(b.order));
      
      print('🔍 Loaded ${_ads.length} ads');

      // جلب البانر المتحرك
      final carouselSnapshot = await FirebaseFirestore.instance
          .collection('carousel_ads')
          .get();
      
      _carouselAds = carouselSnapshot.docs
          .map((doc) => CarouselAd.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      // ترتيب البانر المتحرك حسب order (الافتراضي 0)
      _carouselAds.sort((a, b) => a.order.compareTo(b.order));
      
      print('🔍 Loaded ${_carouselAds.length} carousel ads');

    } catch (e) {
      print('Error loading ads: $e');
    } finally {
      setState(() => _isLoading = false);
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
                
                // التبويبات
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: const Color(0xFF52002C),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF52002C),
                    labelStyle: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'الإعلانات الثابتة'),
                      Tab(text: 'البانر المتحرك'),
                    ],
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
                    'اسحب الإعلانات لإعادة ترتيبها، واستخدم المفاتيح لإخفائها أو إظهارها',
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

          // قائمة الإعلانات القابلة للسحب
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
                : ReorderableListView.builder(
                    itemCount: _ads.length,
                    onReorder: (oldIndex, newIndex) => _reorderStaticAds(oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final ad = _ads[index];
                      return _buildAdCard(ad, index);
                    },
                  ),
          ),
        ],
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

  Widget _buildAdCard(Ad ad, int index) {
    return Card(
      key: ValueKey(ad.id),
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
              color: ad.isVisible 
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // صورة الإعلان
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(ad.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(width: 15),
                
                // معلومات الإعلان
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.companyName,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'الموضع: ${_getPositionText(ad.position)}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // أدوات التحكم
                Column(
                  children: [
                    // مفتاح الإخفاء/الإظهار
                    Switch(
                      value: ad.isVisible,
                      onChanged: (value) => _toggleAdVisibility(ad.id, value),
                      activeColor: const Color(0xFF52002C),
                    ),
                    
                    // قائمة اختيار الموضع
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.location_on, color: Color(0xFF52002C)),
                      onSelected: (position) => _changeAdPosition(ad.id, position),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'top', child: Text('أعلى')),
                        const PopupMenuItem(value: 'middle', child: Text('وسط')),
                        const PopupMenuItem(value: 'bottom', child: Text('أسفل')),
                      ],
                    ),
                  ],
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

  String _getPositionText(String position) {
    switch (position) {
      case 'top':
        return 'أعلى الصفحة';
      case 'bottom':
        return 'أسفل الصفحة';
      default:
        return 'وسط الصفحة';
    }
  }

  void _reorderStaticAds(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final ad = _ads.removeAt(oldIndex);
      _ads.insert(newIndex, ad);
    });
    _updateAdsOrder();
  }

  void _reorderCarouselAds(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final carouselAd = _carouselAds.removeAt(oldIndex);
      _carouselAds.insert(newIndex, carouselAd);
    });
    _updateCarouselAdsOrder();
  }

  Future<void> _updateAdsOrder() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < _ads.length; i++) {
        final docRef = FirebaseFirestore.instance.collection('ads').doc(_ads[i].id);
        batch.update(docRef, {'order': i});
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث ترتيب الإعلانات بنجاح'),
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

  Future<void> _toggleAdVisibility(String adId, bool isVisible) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'isVisible': isVisible});
      
      setState(() {
        final index = _ads.indexWhere((ad) => ad.id == adId);
        if (index != -1) {
          _ads[index] = Ad(
            id: _ads[index].id,
            imageUrl: _ads[index].imageUrl,
            shapeType: _ads[index].shapeType,
            companyId: _ads[index].companyId,
            companyName: _ads[index].companyName,
            order: _ads[index].order,
            isVisible: isVisible,
            position: _ads[index].position,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVisible ? 'تم إظهار الإعلان' : 'تم إخفاء الإعلان'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الإعلان: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleCarouselAdVisibility(String adId, bool isVisible) async {
    try {
      await FirebaseFirestore.instance
          .collection('carousel_ads')
          .doc(adId)
          .update({'isVisible': isVisible});
      
      setState(() {
        final index = _carouselAds.indexWhere((ad) => ad.id == adId);
        if (index != -1) {
          _carouselAds[index] = CarouselAd(
            id: _carouselAds[index].id,
            imageUrl: _carouselAds[index].imageUrl,
            companyId: _carouselAds[index].companyId,
            companyName: _carouselAds[index].companyName,
            order: _carouselAds[index].order,
            isVisible: isVisible,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVisible ? 'تم إظهار البانر' : 'تم إخفاء البانر'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث البانر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changeAdPosition(String adId, String position) async {
    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(adId)
          .update({'position': position});
      
      setState(() {
        final index = _ads.indexWhere((ad) => ad.id == adId);
        if (index != -1) {
          _ads[index] = Ad(
            id: _ads[index].id,
            imageUrl: _ads[index].imageUrl,
            shapeType: _ads[index].shapeType,
            companyId: _ads[index].companyId,
            companyName: _ads[index].companyName,
            order: _ads[index].order,
            isVisible: _ads[index].isVisible,
            position: position,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تغيير موضع الإعلان إلى ${_getPositionText(position)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الموضع: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
