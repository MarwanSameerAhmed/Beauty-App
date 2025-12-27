import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:glamify/widgets/SearchBar.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/widgets/ad_loading_skeleton.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/corusalWidget.dart';
import 'package:glamify/widgets/infoWidget.dart';
import 'package:glamify/controller/ads_service.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/model/ad.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/productDetails.dart';
import 'package:glamify/widgets/product_card.dart';
import 'package:glamify/view/favoritesUi.dart';
import 'package:glamify/view/company_products_page.dart';
import 'package:glamify/utils/responsive_helper.dart';

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
  Stream<List<Ad>>? _adsStream;
  Stream<QuerySnapshot>? _sectionsStream;
  Stream<List<Product>>? _productsStream;
  
  // Cache للمنتجات والإعلانات لمنع التحديث المستمر
  List<Product>? _cachedProducts;
  List<Ad>? _cachedAds;
  QuerySnapshot? _cachedSections;
  
  // ScrollController لحفظ موضع السكرول
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // تم تعطيل إنشاء الأقسام الافتراضية التلقائي
    // الأقسام تُدار من صفحة إدارة الأقسام فقط

    _loadUserData();
    
    // تهيئة جميع الـ streams مرة واحدة فقط
    _adsStream = _adsService.getAds();
    _productsStream = _productService.getProducts();
    _sectionsStream = FirebaseFirestore.instance
        .collection('ads_section_settings')
        .where('isVisible', isEqualTo: true)
        .snapshots();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
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

                // Dynamic Layout - All Sections (Carousel, Ads, Products)
                _buildDynamicLayout(),

                // Add padding for the translucent bottom navigation bar
                SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
              ],
            ),
          ), // SafeArea
        ),
      ),
    );
  }

  Widget _buildDynamicLayout() {
    return StreamBuilder<QuerySnapshot>(
      stream: _sectionsStream,
      builder: (context, snapshot) {
        // استخدام الـ cache أثناء الانتظار لمنع إعادة البناء
        if (snapshot.connectionState == ConnectionState.waiting && _cachedSections != null) {
          snapshot = AsyncSnapshot.withData(ConnectionState.active, _cachedSections!);
        }

        if (snapshot.hasError) {
          return _buildDefaultLayout();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (_cachedSections != null) {
            snapshot = AsyncSnapshot.withData(ConnectionState.active, _cachedSections!);
          } else {
            return _buildDefaultLayout();
          }
        }
        
        // تحديث الـ cache فقط إذا تغيرت البيانات
        if (_cachedSections == null || 
            _cachedSections!.docs.length != snapshot.data!.docs.length) {
          _cachedSections = snapshot.data;
        }

        final sections = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return AdsSectionSettings(
            id: doc.id,
            title: data['title'] ?? '',
            position: data['position'] ?? 'middle',
            order: data['order'] ?? 0,
            isVisible: data['isVisible'] ?? true,
            type: data['type'] ?? 'ads',
            maxItems: data['maxItems'] ?? 6,
            description: data['description'],
          );
        }).toList();

        sections.sort((a, b) => a.order.compareTo(b.order));

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final section = sections[index];

            // عرض العنصر حسب نوعه
            if (section.isCarouselSection) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: ResponsiveHelper.horizontalPadding,
                      right: ResponsiveHelper.horizontalPadding + 8,
                      top: ResponsiveHelper.verticalSpacing,
                      bottom: ResponsiveHelper.verticalSpacing,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        section.title,
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
                  ),
                  const ProductCarousel(),
                  SizedBox(height: ResponsiveHelper.verticalSpacing),
                ],
              );
            } else if (section.isAdsSection) {
              return _buildAdsSectionWidget(section);
            } else if (section.isProductsSection) {
              return _buildProductSection(section.title, section.maxItems);
            }

            return const SizedBox.shrink();
          }, childCount: sections.length),
        );
      },
    );
  }

  Widget _buildDefaultLayout() {
    // التخطيط الافتراضي في حال عدم وجود أقسام
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveHelper.horizontalPadding,
            right: ResponsiveHelper.horizontalPadding + 8,
            top: ResponsiveHelper.verticalSpacing,
            bottom: ResponsiveHelper.verticalSpacing,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              'جديدنا',
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
        ),
        const ProductCarousel(),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
        _buildAdsSection(),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ]),
    );
  }

  Widget _buildAdsSectionWidget(AdsSectionSettings section) {
    return StreamBuilder<List<Ad>>(
      stream: _adsStream,
      builder: (context, snapshot) {
        // استخدام الـ cache أثناء الانتظار
        List<Ad> ads = [];
        
        if (snapshot.connectionState == ConnectionState.waiting && _cachedAds != null) {
          ads = _cachedAds!;
        } else if (snapshot.hasData) {
          ads = snapshot.data!;
          _cachedAds = ads;
        } else if (_cachedAds != null) {
          ads = _cachedAds!;
        }

        final sectionAds =
            ads
                .where((ad) => ad.sectionId == section.id && ad.isVisible)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));

        // عرض القسم حتى لو كان فارغاً (لأغراض التطوير والاختبار)
        if (sectionAds.isEmpty) {
          return Column(
            key: ValueKey('empty_${section.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: ResponsiveHelper.horizontalPadding,
                  right: ResponsiveHelper.horizontalPadding + 8,
                  top: ResponsiveHelper.verticalSpacing,
                  bottom: ResponsiveHelper.verticalSpacing,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    section.title,
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
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveHelper.horizontalPadding + 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius),
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
            Padding(
              padding: EdgeInsets.only(
                left: ResponsiveHelper.horizontalPadding,
                right: ResponsiveHelper.horizontalPadding + 8,
                top: ResponsiveHelper.verticalSpacing,
                bottom: ResponsiveHelper.verticalSpacing,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  section.title,
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
            ),
            ..._buildAdsSectionWidgets(sectionAds),
            SizedBox(height: ResponsiveHelper.verticalSpacing),
          ],
        );
      },
    );
  }

  Widget _buildAdsSection() {
    // دالة للتوافق مع التخطيط الافتراضي
    return StreamBuilder<List<Ad>>(
      stream: _adsStream ?? const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(8.0), child: Loader()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final ads = snapshot.data!;
        final visibleAds = ads.where((ad) => ad.isVisible).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (visibleAds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildAdsSectionWidgets(visibleAds),
        );
      },
    );
  }

  List<Widget> _buildAdsSectionWidgets(List<Ad> ads) {
    final List<Widget> adWidgets = [];

    // تقسيم الإعلانات حسب النوع
    final rectangleAds = ads
        .where((ad) => ad.shapeType == 'rectangle')
        .toList();
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

  Widget _buildProductSection(String title, int maxItems) {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        // استخدام الـ cache أثناء الانتظار
        if (snapshot.connectionState == ConnectionState.waiting && _cachedProducts != null) {
          // استخدم البيانات المحفوظة
          return _buildProductSectionContent(title, _cachedProducts!.take(maxItems).toList());
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(20.0), child: Loader()),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (_cachedProducts != null) {
            return _buildProductSectionContent(title, _cachedProducts!.take(maxItems).toList());
          }
          return const Center(child: Text('لا توجد منتجات حالياً'));
        }
        
        // تحديث الـ cache
        _cachedProducts = snapshot.data;

        final products = snapshot.data!.take(maxItems).toList();
        return _buildProductSectionContent(title, products);
      },
    );
  }
  
  Widget _buildProductSectionContent(String title, List<Product> products) {
    return Column(
      key: ValueKey('products_$title'),
      children: [
        // عنوان القسم
        Padding(
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
        ),

        // المنتجات في عرض أفقي
        SizedBox(
          height: ResponsiveHelper.productSectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.horizontalPadding),
            itemCount: products.length,
            separatorBuilder: (context, index) => SizedBox(width: ResponsiveHelper.isMobile ? 12 : 16),
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
