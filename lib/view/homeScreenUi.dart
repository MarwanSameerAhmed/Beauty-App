import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/widgets/SearchBar.dart';
import 'package:test_pro/widgets/SectionTitle.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/widgets/sectionTitleNonSliver.dart';
import 'package:test_pro/widgets/ad_loading_skeleton.dart';
import 'package:test_pro/controller/ads_section_settings_service.dart';
import 'package:test_pro/model/ads_section_settings.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/corusalWidget.dart';
import 'package:test_pro/widgets/infoWidget.dart';
import 'package:test_pro/controller/ads_service.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/model/ad.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/productDetails.dart';
import 'package:test_pro/widgets/product_card.dart';
import 'package:test_pro/view/favoritesUi.dart';
import 'package:test_pro/view/company_products_page.dart';

class Homescreenui extends StatefulWidget {
  final TabController tabController;
  const Homescreenui({super.key, required this.tabController});

  @override
  _HomescreenuiState createState() => _HomescreenuiState();
}

class _HomescreenuiState extends State<Homescreenui> {
  String _userName = "Guest";
  String _email = "No Email";
  String _imagePath = "images/0c7640ce594d7f983547e32f01ede503.jpg";
  final ProductService _productService = ProductService();
  final AdsService _adsService = AdsService();
  Stream<List<Ad>>? _adsStream;
  final AdsSectionSettingsService _sectionSettingsService = AdsSectionSettingsService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // إنشاء الأقسام الافتراضية إذا لم تكن موجودة
    await _sectionSettingsService.initializeDefaultSections();
    
    _loadUserData();
    _adsStream = _adsService.getAds();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString("userName") ?? "Guest";
      _email = prefs.getString("email") ?? "No Email";
      _imagePath =
          prefs.getString("imagePath") ??
          "images/0c7640ce594d7f983547e32f01ede503.jpg";
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 110.0,
                  maxHeight: 110.0,
                  child: Consumer<CartService>(
                    builder: (context, cart, child) {
                      return ProfileHeaderWidget(
                        imagePath: _imagePath,
                        userName: _userName,
                        email: _email,
                        cartItemCount: cart.itemCount,
                        onCartPressed: () {
                          widget.tabController.animateTo(
                            2,
                          ); // Index 2 is CartPage
                        },
                        onFavoritePressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Search Bar and Search Icon
              const SliverToBoxAdapter(child: Searchbar()),

              const Sectiontitle(Title: 'جديدنا'),

              // Carousel Section
              const SliverToBoxAdapter(child: ProductCarousel()),

              // Ads Section
              SliverToBoxAdapter(child: _buildAdsSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // Product Sections
              _buildProductSections(),

              // Add padding for the translucent bottom navigation bar
              const SliverToBoxAdapter(child: SizedBox(height: 85.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsSection() {
    return StreamBuilder<List<Ad>>(
      stream: _adsStream ?? const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(8.0), child: Loader()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final ads = snapshot.data!;
        
        // فلترة الإعلانات الظاهرة فقط وترتيبها
        final visibleAds = ads
            .where((ad) => ad.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (visibleAds.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildAdsWithPositions(visibleAds);
      },
    );
  }

  Widget _buildAdsWithPositions(List<Ad> visibleAds) {
    return StreamBuilder<List<AdsSectionSettings>>(
      stream: AdsSectionSettingsService().getSectionSettings(),
      builder: (context, settingsSnapshot) {
        if (settingsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!settingsSnapshot.hasData || settingsSnapshot.data!.isEmpty) {
          return _buildDefaultAdsLayout(visibleAds);
        }

        final sectionSettings = settingsSnapshot.data!
            .where((section) => section.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        final List<Widget> allAdWidgets = [];

        for (var section in sectionSettings) {
          final sectionAds = visibleAds
              .where((ad) => ad.sectionId == section.id)
              .toList();

          if (sectionAds.isNotEmpty) {
            allAdWidgets.add(
              SectionTitleNonSliver(title: section.title),
            );
            allAdWidgets.addAll(_buildAdsSectionWidgets(sectionAds));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: allAdWidgets,
        );
      },
    );
  }

  Widget _buildDefaultAdsLayout(List<Ad> visibleAds) {
    // تقسيم الإعلانات حسب المواضع (النظام الافتراضي)
    final topAds = visibleAds.where((ad) => ad.position == 'top').toList();
    final middleAds = visibleAds.where((ad) => ad.position == 'middle').toList();
    final bottomAds = visibleAds.where((ad) => ad.position == 'bottom').toList();

    final List<Widget> allAdWidgets = [];

    // إعلانات الأعلى
    if (topAds.isNotEmpty) {
      allAdWidgets.add(
        const SectionTitleNonSliver(title: 'عروض مميزة'),
      );
      allAdWidgets.addAll(_buildAdsSectionWidgets(topAds));
    }

    // إعلانات الوسط
    if (middleAds.isNotEmpty) {
      allAdWidgets.add(
        const SectionTitleNonSliver(title: 'عروض خاصة'),
      );
      allAdWidgets.addAll(_buildAdsSectionWidgets(middleAds));
    }

    // إعلانات الأسفل
    if (bottomAds.isNotEmpty) {
      allAdWidgets.add(
        const SectionTitleNonSliver(title: 'عروض إضافية'),
      );
      allAdWidgets.addAll(_buildAdsSectionWidgets(bottomAds));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allAdWidgets,
    );
  }

  List<Widget> _buildAdsSectionWidgets(List<Ad> ads) {
    final List<Widget> adWidgets = [];
    
    // تقسيم الإعلانات حسب النوع
    final rectangleAds = ads.where((ad) => ad.shapeType == 'rectangle').toList();
    final squareAds = ads.where((ad) => ad.shapeType == 'square').toList();

    // بناء الإعلانات المستطيلة
    for (var ad in rectangleAds) {
      adWidgets.add(_buildRectangleAd(ad));
    }

    // بناء الإعلانات المربعة (في مجموعات من اثنين)
    if (squareAds.isNotEmpty) {
      adWidgets.add(_buildSquareAdsGrid(squareAds));
    }

    return adWidgets;
  }

  Widget _buildRectangleAd(Ad ad) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      child: AdImageWithLoading(
        imageUrl: ad.imageUrl,
        width: double.infinity,
        height: 180,
        isRectangle: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyProductsPage(
                companyId: ad.companyId,
                companyName: ad.companyName,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSquareAdsGrid(List<Ad> squareAds) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: squareAds.map((ad) {
          final screenWidth = MediaQuery.of(context).size.width;
          final itemWidth = (screenWidth - 16 * 2 - 10) / 2;
          return AdImageWithLoading(
            imageUrl: ad.imageUrl,
            width: itemWidth,
            height: itemWidth,
            isRectangle: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompanyProductsPage(
                    companyId: ad.companyId,
                    companyName: ad.companyName,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductSections() {
    return FutureBuilder<List<AdsSectionSettings>>(
      future: FirebaseFirestore.instance
          .collection('ads_section_settings')
          .where('type', isEqualTo: 'products')
          .where('isVisible', isEqualTo: true)
          .get()
          .then((snapshot) {
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
            sections.sort((a, b) => a.order.compareTo(b.order));
            return sections;
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(child: Loader()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          );
        }

        final productSections = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = productSections[index];
              return _buildProductSection(section.title, section.maxItems);
            },
            childCount: productSections.length,
          ),
        );
      },
    );
  }

  Widget _buildProductSection(String title, int maxItems) {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(20.0), child: Loader()),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد منتجات حالياً'));
        }

        final products = snapshot.data!.take(maxItems).toList();

        return Column(
          children: [
            // عنوان القسم
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 24, top: 10, bottom: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: "Tajawal",
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 30,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // المنتجات في عرض أفقي
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 180,
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(product: product),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }


}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
