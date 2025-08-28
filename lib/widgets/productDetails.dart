import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/controller/favorites_service.dart';
import 'package:test_pro/controller/cart_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  static const double _imageHeight = 400;
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    final minChildSize =
        1 -
        ((ProductDetailsPage._imageHeight - ProductDetailsPage._overlap) /
            screenHeight);
    final initialSize = (0.6 < minChildSize) ? 0.6 : minChildSize;

    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              _buildImageCarousel(),
              _buildGlassBackButton(topPadding, context),
              DraggableScrollableSheet(
                initialChildSize: initialSize,
                minChildSize: minChildSize,
                maxChildSize: 0.95,
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
                                color: Colors.white.withOpacity(0.0),
                                backgroundBlendMode: BlendMode.srcOver,
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
    );
  }

  Widget _buildImageCarousel() {
    // Ensure there's at least one image to prevent range errors
    if (widget.product.images.isEmpty) {
      return SizedBox(
        height: ProductDetailsPage._imageHeight,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        ),
      );
    }

    return SizedBox(
      height: ProductDetailsPage._imageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Blurred Background Image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: ImageFiltered(
                key: ValueKey<int>(_currentPage),
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: _buildProductImage(
                  null,
                  widget.product.images[_currentPage],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Gradient overlay for better contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
            ),
          ),

          // 2. Centered Image Card with Hero Animation
          Hero(
            tag: 'product-image-${widget.product.id}',
            child: Padding(
              padding: const EdgeInsets.only(
                top: 15,
                bottom: 60,
                left: 0,
                right: 0,
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
                    margin: const EdgeInsets.symmetric(horizontal: 25.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildProductImage(
                        null,
                        widget.product.images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Page Indicator
          if (widget.product.images.length > 1)
            Positioned(
              bottom: ProductDetailsPage._overlap + 35,
              child: _buildPageIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.product.images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Use ValueListenableBuilder to listen to changes in the favorites list.
              ValueListenableBuilder<List<String>>(
                valueListenable: _favoritesService.favoriteProductIds,
                builder: (context, favoriteIds, child) {
                  final isFavorite = favoriteIds.contains(widget.product.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? const Color(0xFFC15C5C)
                          : Colors.grey.shade400,
                      size: 30,
                    ),
                    // Toggle the favorite status when pressed.
                    onPressed: () =>
                        _favoritesService.toggleFavorite(widget.product.id),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Text(
          //   '${widget.product.price.toStringAsFixed(2)} ر.س',
          //   style: TextStyle(
          //     fontFamily: 'Tajawal',
          //     fontSize: 22,
          //     color: const Color(0xFFC15C5C).withOpacity(0.9),
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          Text(
            widget.product.description,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              height: 1.6,
              color: Colors.black.withOpacity(0.7),
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
        child: ElevatedButton.icon(
          icon: _isAdding
              ? const SizedBox.shrink()
              : const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          label: Text(
            _isAdding ? 'جاري الإضافة...' : 'أضف إلى العربة',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            backgroundColor: const Color(0xFFC15C5C).withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.3),
          ),
          onPressed: _isAdding
              ? null
              : () {
                  setState(() => _isAdding = true);

                  // Add item to cart
                  CartService().addItem(widget.product);

                  // Show a confirmation message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة المنتج إلى السلة بنجاح!'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Reset the button state after a delay
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() => _isAdding = false);
                    }
                  });
                },
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
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
      return Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }
    return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
  }
}
