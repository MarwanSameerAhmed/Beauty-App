import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/widgets/SearchBar.dart';
import 'package:test_pro/widgets/SectionTitle.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/widgets/SectionTitleNonSliver.dart';
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
  late Stream<List<Ad>> _adsStream;

  @override
  void initState() {
    super.initState();
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
                        widget.tabController.animateTo(2); // Index 2 is CartPage
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
            SliverToBoxAdapter(child: Searchbar()),

            Sectiontitle(Title: 'جديدنا'),

            // Carousel Section
            SliverToBoxAdapter(child: ProductCarousel()),

            // Ads Section
            SliverToBoxAdapter(child: _buildAdsSection()),

            Sectiontitle(Title: 'الأكثر مبيعاً'),

            // Products Section
            _buildProductsSection(),

            // Add padding for the translucent bottom navigation bar
            const SliverToBoxAdapter(child: SizedBox(height: 85.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsSection() {
    return StreamBuilder<List<Ad>>(
      stream: _adsStream,
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
        final List<Widget> adWidgets = [];

        final rectangleAds = ads
            .where((ad) => ad.shapeType == 'rectangle')
            .toList();
        final squareAds = ads.where((ad) => ad.shapeType == 'square').toList();

        // Build rectangle ads
        for (var ad in rectangleAds) {
          adWidgets.add(
            GestureDetector(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    ad.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),
                ),
              ),
            ),
          );
        }

        // Build square ads in a Wrap
        if (squareAds.isNotEmpty) {
          adWidgets.add(
            Padding(
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
                  return GestureDetector(
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        ad.imageUrl,
                        fit: BoxFit.cover,
                        width: itemWidth,
                        height: itemWidth,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adWidgets.isNotEmpty)
              const SectionTitleNonSliver(title: 'عروض خاصة'),
            ...adWidgets,
          ],
        );
      },
    );
  }

  Widget _buildProductsSection() {
    return StreamBuilder<List<Product>>(
      stream: _productService.getProducts(), // Assuming this gets best sellers
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(padding: EdgeInsets.all(20.0), child: Loader()),
            ),
          );
        }
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('حدث خطأ: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Text('لا توجد منتجات حالياً')),
          );
        }

        final products = snapshot.data!;

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 240.0,
            child: ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  width: 200.0,
                  height: 230.0,
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
                );
              },
            ),
          ),
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
