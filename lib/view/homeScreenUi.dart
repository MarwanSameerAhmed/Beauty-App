import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:glamify/widgets/SearchBar.dart';
import 'package:glamify/widgets/home_shimmer.dart';
import 'package:glamify/widgets/ad_loading_skeleton.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/corusalWidget.dart';
import 'package:glamify/widgets/infoWidget.dart';
import 'package:glamify/controller/ads_service.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/controller/carousel_ad_service.dart';
import 'package:glamify/controller/home_cache_service.dart';
import 'package:glamify/model/ad.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/model/carousel_ad.dart';
import 'package:glamify/widgets/productDetails.dart';
import 'package:glamify/widgets/product_card.dart';
import 'package:glamify/view/favoritesUi.dart';
import 'package:glamify/view/company_products_page.dart';
import 'package:glamify/utils/responsive_helper.dart';
import 'package:glamify/utils/logger.dart';
import 'package:glamify/view/poster_page.dart';
import 'package:glamify/widgets/cached_image.dart';

class Homescreenui extends StatefulWidget {
  final TabController tabController;
  const Homescreenui({super.key, required this.tabController});

  @override
  _HomescreenuiState createState() => _HomescreenuiState();
}

class _HomescreenuiState extends State<Homescreenui>
    with AutomaticKeepAliveClientMixin {
  String _userName = "Guest";
  String _email = "No Email";
  String _imagePath = "images/0c7640ce594d7f983547e32f01ede503.jpg";

  final ProductService _productService = ProductService();
  final AdsService _adsService = AdsService();
  final CarouselAdService _carouselAdService = CarouselAdService();

  // البيانات المحمّلة
  List<Product>? _products;
  List<Ad>? _ads;
  List<CarouselAd>? _carouselAds;
  List<AdsSectionSettings>? _sections;

  // حالة التحميل
  bool _isFirstLoad = true;
  bool _isRefreshing = false;

  // ScrollController لحفظ موضع السكرول
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// تحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString("userName") ?? "Guest";
        _email = prefs.getString("email") ?? "No Email";
        _imagePath = prefs.getString("imagePath") ??
            "images/0c7640ce594d7f983547e32f01ede503.jpg";
      });
    }
  }

  /// تهيئة البيانات: كاش أولاً → ثم سيرفر بالخلفية
  Future<void> _initializeData() async {
    // 1. جلب البيانات من الكاش فوراً
    await _loadFromCache();

    // 2. جلب البيانات الجديدة من السيرفر بالخلفية
    _fetchFromServer();
  }

  /// جلب البيانات من الكاش المحلي (فوري)
  Future<void> _loadFromCache() async {
    try {
      final results = await Future.wait([
        HomeCacheService.getCachedProducts(),
        HomeCacheService.getCachedAds(),
        HomeCacheService.getCachedCarouselAds(),
        HomeCacheService.getCachedSections(),
      ]);

      final cachedProducts = results[0] as List<Product>;
      final cachedAds = results[1] as List<Ad>;
      final cachedCarousel = results[2] as List<CarouselAd>;
      final cachedSections = results[3] as List<AdsSectionSettings>;

      if (mounted && cachedProducts.isNotEmpty) {
        setState(() {
          _products = cachedProducts;
          _ads = cachedAds;
          _carouselAds = cachedCarousel;
          _sections = cachedSections.isNotEmpty ? cachedSections : null;
          _isFirstLoad = false;
        });
        AppLogger.info('Loaded data from cache', tag: 'HOME');
      }
    } catch (e) {
      AppLogger.error('Failed to load from cache', tag: 'HOME', error: e);
    }
  }

  /// جلب البيانات من السيرفر
  Future<void> _fetchFromServer() async {
    try {
      // جلب كل البيانات بالتوازي
      final results = await Future.wait([
        _productService.getProductsOnce(limit: 50),
        _adsService.getAdsOnce(),
        _carouselAdService.getCarouselAdsOnce(),
        _fetchSections(),
      ]);

      final products = results[0] as List<Product>;
      final ads = results[1] as List<Ad>;
      final carousel = results[2] as List<CarouselAd>;
      final sections = results[3] as List<AdsSectionSettings>;

      if (mounted) {
        setState(() {
          _products = products;
          _ads = ads;
          _carouselAds = carousel;
          _sections = sections;
          _isFirstLoad = false;
        });
      }

      // حفظ في الكاش
      await HomeCacheService.cacheAll(
        products: products,
        ads: ads,
        carouselAds: carousel,
        sections: sections,
      );

      AppLogger.info('Data fetched from server & cached', tag: 'HOME');
    } catch (e) {
      AppLogger.error('Failed to fetch from server', tag: 'HOME', error: e);
      if (mounted && _isFirstLoad) {
        setState(() {
          _isFirstLoad = false;
        });
      }
    }
  }

  /// جلب الأقسام من Firestore
  Future<List<AdsSectionSettings>> _fetchSections() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ads_section_settings')
          .where('isVisible', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        return AdsSectionSettings.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Pull-to-Refresh
  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _fetchFromServer();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);
    final headerHeight = ResponsiveHelper.headerHeight;
    final bottomPadding = ResponsiveHelper.isMobile ? 85.0 : 100.0;

    return FlowerBackground(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            bottom: false, // السماح بامتداد المحتوى للأسفل
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF52002C),
              backgroundColor: Colors.white,
              displacement: 60,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      minHeight: headerHeight,
                      maxHeight: headerHeight,
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

                  // Dynamic Layout - All Sections
                  _buildContent(),

                  // Add padding for the translucent bottom navigation bar
                  SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
                ],
              ),
            ),
          ), // SafeArea
        ),
      ),
    );
  }

  /// بناء المحتوى الرئيسي
  Widget _buildContent() {
    // أول فتح بدون كاش → عرض شيمر
    if (_isFirstLoad) {
      return const HomePageShimmer();
    }

    // فيه أقسام مخصصة
    if (_sections != null && _sections!.isNotEmpty) {
      return _buildDynamicLayout();
    }

    // التخطيط الافتراضي
    return _buildDefaultLayout();
  }

  /// بناء التخطيط الديناميكي من الأقسام
  Widget _buildDynamicLayout() {
    final allSections = List<AdsSectionSettings>.from(_sections!)
      ..sort((a, b) => a.order.compareTo(b.order));

    // جمع IDs الأقسام المربوطة بالبوسترات — هذه تختفي من الهوم
    final Set<String> linkedIds = {};
    for (final s in allSections.where((s) => s.isPosterSection)) {
      linkedIds.addAll(s.linkedSectionIds);
    }

    // فلترة: عرض البوسترات + الأقسام الغير مربوطة فقط
    final sections = allSections.where((s) => !linkedIds.contains(s.id)).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = sections[index];

        if (section.isCarouselSection) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(section.title),
              ProductCarousel(carouselAds: _carouselAds),
              SizedBox(height: ResponsiveHelper.verticalSpacing),
            ],
          );
        } else if (section.isPosterSection) {
          return _buildPosterBanner(section);
        } else if (section.isAdsSection) {
          return _buildAdsSectionWidget(section);
        } else if (section.isProductsSection) {
          return _buildProductSection(section.title, section.maxItems);
        }

        return const SizedBox.shrink();
      }, childCount: sections.length),
    );
  }

  /// بناء بانر البوستر
  Widget _buildPosterBanner(AdsSectionSettings poster) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalPadding,
        vertical: ResponsiveHelper.verticalSpacing,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PosterPage(
                poster: poster,
                allSections: _sections ?? [],
                allAds: _ads ?? [],
                allProducts: _products ?? [],
              ),
            ),
          );
        },
        child: Container(
          height: ResponsiveHelper.rectangleAdHeight + 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF52002C).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // صورة البوستر
                if (poster.posterImageUrl != null && poster.posterImageUrl!.isNotEmpty)
                  AppCachedImage(
                    imageUrl: poster.posterImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF52002C), Color(0xFF7A0039), Color(0xFFB5004F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF52002C), Color(0xFF7A0039), Color(0xFFB5004F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                // Gradient overlay — من اليمين للعربي
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                // النص والمحتوى — من اليمين وفي الأسفل
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        poster.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      if (poster.description != null && poster.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            poster.description!,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'اكتشف الآن',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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


  /// التخطيط الافتراضي
  Widget _buildDefaultLayout() {
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildSectionTitle('جديدنا'),
        ProductCarousel(carouselAds: _carouselAds),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
        _buildAdsSection(),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ]),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveHelper.horizontalPadding,
        right: ResponsiveHelper.horizontalPadding + 8,
        top: ResponsiveHelper.verticalSpacing,
        bottom: ResponsiveHelper.verticalSpacing,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: "Tajawal",
            fontSize: ResponsiveHelper.titleFontSize,
            color: Colors.black,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// قسم الإعلانات مع بياناته
  Widget _buildAdsSectionWidget(AdsSectionSettings section) {
    if (_ads == null) {
      return const AdSectionShimmer();
    }

    final sectionAds = _ads!
        .where((ad) => ad.sectionId == section.id && ad.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (sectionAds.isEmpty) {
      return Column(
        key: ValueKey('empty_${section.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(section.title),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveHelper.horizontalPadding + 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(ResponsiveHelper.borderRadius),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'لا توجد إعلانات في هذا القسم بعد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: ResponsiveHelper.bodyFontSize,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing * 2),
        ],
      );
    }

    return Column(
      key: ValueKey('section_${section.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(section.title),
        ..._buildAdsSectionWidgets(sectionAds),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ],
    );
  }

  /// قسم الإعلانات الافتراضي
  Widget _buildAdsSection() {
    if (_ads == null || _ads!.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleAds = _ads!.where((ad) => ad.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (visibleAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildAdsSectionWidgets(visibleAds),
    );
  }

  List<Widget> _buildAdsSectionWidgets(List<Ad> ads) {
    final List<Widget> adWidgets = [];

    final rectangleAds =
        ads.where((ad) => ad.shapeType == 'rectangle').toList();
    final squareAds = ads.where((ad) => ad.shapeType == 'square').toList();

    for (var ad in rectangleAds) {
      adWidgets.add(_buildRectangleAd(ad));
    }

    if (squareAds.isNotEmpty) {
      adWidgets.add(_buildSquareAdsGrid(squareAds));
    }

    return adWidgets;
  }

  Widget _buildRectangleAd(Ad ad) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.verticalSpacing * 0.8,
        horizontal: ResponsiveHelper.horizontalPadding,
      ),
      child: AdImageWithLoading(
        imageUrl: ad.imageUrl,
        width: double.infinity,
        height: ResponsiveHelper.rectangleAdHeight,
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
    final itemWidth = ResponsiveHelper.squareAdWidth;
    final spacing = ResponsiveHelper.isMobile ? 10.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalPadding,
        vertical: ResponsiveHelper.verticalSpacing * 0.8,
      ),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: squareAds.map((ad) {
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

  /// قسم المنتجات
  Widget _buildProductSection(String title, int maxItems) {
    // لسا ما تحمّلت → شيمر
    if (_products == null) {
      return const ProductSectionShimmer();
    }

    final products = _products!.take(maxItems).toList();
    if (products.isEmpty) {
      return const Center(child: Text('لا توجد منتجات حالياً'));
    }

    return _buildProductSectionContent(title, products);
  }

  Widget _buildProductSectionContent(String title, List<Product> products) {
    return Column(
      key: ValueKey('products_$title'),
      children: [
        _buildSectionTitle(title),
        SizedBox(
          height: ResponsiveHelper.productSectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.horizontalPadding),
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                SizedBox(width: ResponsiveHelper.isMobile ? 12 : 16),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: ResponsiveHelper.productCardWidth,
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
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing * 2),
      ],
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
