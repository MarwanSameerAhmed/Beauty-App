import 'package:flutter/material.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/model/ad.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/product_card.dart';
import 'package:glamify/widgets/productDetails.dart';
import 'package:glamify/view/company_products_page.dart';
import 'package:glamify/widgets/ad_loading_skeleton.dart';
import 'package:glamify/utils/responsive_helper.dart';
import 'package:glamify/widgets/cached_image.dart';

class PosterPage extends StatefulWidget {
  final AdsSectionSettings poster;
  final List<AdsSectionSettings> allSections;
  final List<Ad> allAds;
  final List<Product> allProducts;

  const PosterPage({
    Key? key,
    required this.poster,
    required this.allSections,
    required this.allAds,
    required this.allProducts,
  }) : super(key: key);

  @override
  State<PosterPage> createState() => _PosterPageState();
}

class _PosterPageState extends State<PosterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // جلب كل الإعلانات المربوطة بالبوستر
  List<Ad> get _allLinkedAds {
    final linkedSectionIds = widget.poster.linkedSectionIds;
    return widget.allAds
        .where((ad) => linkedSectionIds.contains(ad.sectionId) && ad.isVisible)
        .toList();
  }

  // نتائج البحث
  List<Ad> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    return _allLinkedAds
        .where((ad) => ad.companyName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    // جلب الأقسام المربوطة بالبوستر
    final linkedSections = widget.allSections
        .where((s) => widget.poster.linkedSectionIds.contains(s.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header مع صورة البوستر
              _buildSliverHeader(context),

              // شريط البحث
              SliverToBoxAdapter(child: _buildSearchBar()),

              // عدد النتائج عند البحث
              if (_searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.horizontalPadding,
                    ),
                    child: Text(
                      _searchResults.isEmpty
                          ? 'لا توجد نتائج لـ "$_searchQuery"'
                          : '${_searchResults.length} نتيجة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // محتوى الأقسام المربوطة — مع الفلتر
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = linkedSections[index];

                    if (section.isAdsSection) {
                      return _buildAdsSection(context, section);
                    } else if (section.isProductsSection) {
                      if (_searchQuery.isNotEmpty) return const SizedBox.shrink();
                      return _buildProductSection(context, section);
                    }

                    return const SizedBox.shrink();
                  },
                  childCount: linkedSections.length,
                ),
              ),

              // Padding للأسفل
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }

  /// شريط البحث
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalPadding,
        vertical: 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF52002C).withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            color: Color(0xFF3A0020),
          ),
          decoration: InputDecoration(
            hintText: 'ابحث عن ماركة...',
            hintStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: const Color(0xFF52002C).withOpacity(0.5),
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
        ),
      ),
    );
  }


  /// Header عصري وأنيق مع صورة البوستر
  Widget _buildSliverHeader(BuildContext context) {
    final linkedCount = widget.poster.linkedSectionIds.length;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // حساب نسبة الطي
          final maxHeight = 280 + MediaQuery.of(context).padding.top;
          final minHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;
          final collapseRatio = 1.0 - ((currentHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
          final isCollapsed = collapseRatio > 0.7;

          return Stack(
            fit: StackFit.expand,
            children: [
              // المحتوى الموسع (الصورة)
              FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // صورة البوستر
            if (widget.poster.posterImageUrl != null && widget.poster.posterImageUrl!.isNotEmpty)
              AppCachedImage(
                imageUrl: widget.poster.posterImageUrl!,
                fit: BoxFit.cover,
                errorWidget: _buildGradientBackground(),
              )
            else
              _buildGradientBackground(),

            // طبقة Gradient متعددة للعمق
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.75, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),

            // دائرة ديكورية ضبابية
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // المحتوى — عنوان + وصف + عدد الأقسام
            Positioned(
              bottom: 24,
              right: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بادج عدد الأقسام
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$linkedCount أقسام',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.grid_view_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // العنوان
                  Text(
                    widget.poster.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 15,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),

                  // الوصف
                  if (widget.poster.description != null && widget.poster.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.poster.description!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
                  ],
                ),
                ),
              ),

              // زر الرجوع (يظهر دائماً فوق الصورة)
              if (!isCollapsed)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                ),

              // الهيدر المطوي — يظهر فقط عند السحب للأعلى
              if (isCollapsed)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: minHeight,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: collapseRatio > 0.8 ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF52002C).withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF52002C).withOpacity(0.08),
                          ),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        right: 16,
                        left: 16,
                      ),
                      child: Row(
                        children: [
                          // العنوان من اليمين
                          Text(
                            widget.poster.title,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: Color(0xFF3A0020),
                            ),
                          ),
                          const Spacer(),
                          // زر الرجوع من اليسار
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF52002C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF52002C),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF52002C), Color(0xFF7A0039), Color(0xFFB5004F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveHelper.horizontalPadding,
        right: ResponsiveHelper.horizontalPadding + 8,
        top: ResponsiveHelper.verticalSpacing * 1.5,
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

  /// قسم الإعلانات
  Widget _buildAdsSection(BuildContext context, AdsSectionSettings section) {
    var sectionAds = widget.allAds
        .where((ad) => ad.sectionId == section.id && ad.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // فلترة بالبحث
    if (_searchQuery.isNotEmpty) {
      sectionAds = sectionAds
          .where((ad) => ad.companyName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (sectionAds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionTitle(section.title),
        ..._buildAdWidgets(context, sectionAds),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ],
    );
  }

  List<Widget> _buildAdWidgets(BuildContext context, List<Ad> ads) {
    final List<Widget> widgets = [];

    final rectangleAds = ads.where((ad) => ad.shapeType == 'rectangle').toList();
    final squareAds = ads.where((ad) => ad.shapeType == 'square').toList();

    for (var ad in rectangleAds) {
      widgets.add(
        Padding(
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
                  builder: (_) => CompanyProductsPage(
                    companyId: ad.companyId,
                    companyName: ad.companyName,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (squareAds.isNotEmpty) {
      final itemWidth = ResponsiveHelper.squareAdWidth;
      final spacing = ResponsiveHelper.isMobile ? 10.0 : 12.0;

      widgets.add(
        Padding(
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
                      builder: (_) => CompanyProductsPage(
                        companyId: ad.companyId,
                        companyName: ad.companyName,
                      ),
                    ),
                  );
                },
              );
            }).toList().cast<Widget>(),
          ),
        ),
      );
    }

    return widgets;
  }

  /// قسم المنتجات
  Widget _buildProductSection(BuildContext context, AdsSectionSettings section) {
    final products = widget.allProducts.take(section.maxItems).toList();
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionTitle(section.title),
        SizedBox(
          height: ResponsiveHelper.productSectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding,
            ),
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
                        builder: (_) => ProductDetailsPage(product: product),
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
