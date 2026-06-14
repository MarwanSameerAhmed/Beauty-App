import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/cached_image.dart';
import 'package:glamify/controller/favorites_service.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:lottie/lottie.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  static const double _overlap = 30;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  // Use a single instance of FavoritesService.
  final FavoritesService _favoritesService = FavoritesService();
  bool _isAdding = false;
  int _currentPage = 0;
  final PageController _pageController = PageController();

  bool _isPopping = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    // ارتفاع الصورة ديناميكي — 45% من الشاشة
    final imageHeight = screenHeight * 0.45;

    final minChildSize =
        1 - ((imageHeight - ProductDetailsPage._overlap) / screenHeight);
    final initialSize = (0.58 < minChildSize) ? 0.58 : minChildSize;
    // حد أدنى للسحب للرجوع — أقل من minChildSize بشوي
    final dismissSize = (minChildSize - 0.04).clamp(0.1, minChildSize);

    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              // سحب الشيت للأسفل بالكامل = رجوع (مرة واحدة فقط)
              if (!_isPopping && notification.extent <= dismissSize + 0.005) {
                _isPopping = true;
                Navigator.of(context).pop();
                return true;
              }
              return false;
            },
            child: Stack(
              children: [
                _buildImageCarousel(imageHeight),
                _buildGlassBackButton(topPadding, context),
                DraggableScrollableSheet(
                  initialChildSize: initialSize,
                  minChildSize: dismissSize,
                  maxChildSize: 0.95,
                  snap: true,
                  snapSizes: [initialSize, 0.95],
                  builder: (context, controller) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ProductDetailsPage._overlap),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(ProductDetailsPage._overlap),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildDetailsContent(controller),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  10,
                                  24,
                                  30,
                                ),
                                decoration: BoxDecoration(
                                  // تدرج شفاف فوق الزر
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                ),
                                child: _buildAddToCartButton(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(double imageHeight) {
    // Ensure there's at least one image to prevent range errors
    if (widget.product.images.isEmpty) {
      return SizedBox(
        height: imageHeight,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        ),
      );
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (!_isPopping &&
            details.primaryDelta != null &&
            details.primaryDelta! > 20) {
          _isPopping = true;
          Navigator.of(context).pop();
        }
      },
      onVerticalDragEnd: (details) {
        if (!_isPopping &&
            details.primaryVelocity != null &&
            details.primaryVelocity! > 500) {
          _isPopping = true;
          Navigator.of(context).pop();
        }
      },
      child: SizedBox(
        height: imageHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. خلفية مضببة
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: ImageFiltered(
                  key: ValueKey<int>(_currentPage),
                  imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: _buildProductImage(
                    null,
                    widget.product.images[_currentPage],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // تدرج خفيف للتباين
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),

            // 2. الصورة الرئيسية مع خلفية بيضاء نظيفة
            Hero(
              tag: 'product-image-${widget.product.id}',
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPadding + 10,
                  bottom: 55,
                  left: 24,
                  right: 24,
                ),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.product.images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildProductImage(
                            null,
                            widget.product.images[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. مؤشر الصفحات
            if (widget.product.images.length > 1)
              Positioned(
                bottom: ProductDetailsPage._overlap + 28,
                child: _buildPageIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.product.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: _currentPage == index ? 22 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // اسم المنتج + المفضلة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B33),
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
              ),
              // Use ValueListenableBuilder to listen to changes in the favorites list.
              ValueListenableBuilder<List<String>>(
                valueListenable: _favoritesService.favoriteProductIds,
                builder: (context, favoriteIds, child) {
                  final isFavorite = favoriteIds.contains(widget.product.id);
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? const Color(0xFFC15C5C).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          key: ValueKey(isFavorite),
                          color: isFavorite
                              ? const Color(0xFFC15C5C)
                              : Colors.grey.shade500,
                          size: 24,
                        ),
                      ),
                      onPressed: () =>
                          _favoritesService.toggleFavorite(widget.product.id),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // خط فاصل أنيق
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFC15C5C).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // عنوان الوصف
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFC15C5C).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'وصف المنتج',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1B33).withOpacity(0.7),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الوصف
          Text(
            widget.product.description,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              height: 1.7,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFC15C5C).withOpacity(0.9),
                const Color(0xFF942A59).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC15C5C).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(double.infinity, 54),
              alignment: Alignment.center,
            ),
            onPressed: _isAdding
                ? null
                : () {
                    setState(() => _isAdding = true);
                    CartService().addItem(widget.product);
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() => _isAdding = false);
                      }
                    });
                  },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isAdding
                  ? Lottie.asset(
                      'images/Shopping Cart.json',
                      key: const ValueKey('lottie_anim'),
                      height: 50,
                    )
                  : const Row(
                      key: ValueKey('add_to_cart_text'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'أضف إلى السلة',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 15),
                        Padding(
                          padding: EdgeInsets.only(bottom: 10.0),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackButton(double topPadding, BuildContext context) {
    return Positioned(
      top: topPadding + 10,
      left: 15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(
    String? imageBase64,
    String? imageUrl, {
    double? height,
    double? width,
    BoxFit? fit,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return AppCachedImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
      );
    }
    return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
  }
}
