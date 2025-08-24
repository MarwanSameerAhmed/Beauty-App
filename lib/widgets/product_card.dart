import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/controller/favorites_service.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/ElegantToast.dart';
import 'package:test_pro/widgets/loader.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isAddingToCart = false;

  void _addToCart() {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      cartService.addItem(widget.product);

      showElegantToast(
        context,
        'تمت إضافة المنتج إلى السلة بنجاح!',
        isSuccess: true,
      );
    } catch (e) {
      showElegantToast(context, 'حدث خطأ أثناء إضافة المنتج', isSuccess: false);
    } finally {
      // A small delay to show the loading indicator
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isAddingToCart = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildImage()),
                  Expanded(flex: 2, child: _buildProductDetails()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Hero(
      tag: 'product-image-${widget.product.id}',
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25.0),
              ),
              child: Image.network(
                widget.product.images.first,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: Loader(width: 70, height: 70));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  );
                },
              ),
            ),
          ),
          Positioned(top: 12, right: 12, child: _buildFavoriteButton()),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _favoritesService.favoriteProductIds,
        builder: (context, favoriteIds, child) {
          final isFavorite = favoriteIds.contains(widget.product.id);
          return IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? const Color(0xFFF9D5D3) : Colors.white,
              size: 20,
            ),
            onPressed: () =>
                _favoritesService.toggleFavorite(widget.product.id),
            splashRadius: 18,
          );
        },
      ),
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to the bottom
        children: [
          // Add to cart button on the left
          SizedBox(
            width: 38,
            height: 38,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF52002C), Color(0xFF942A59)],
                  stops: [0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _addToCart,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: _isAddingToCart
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align text to the bottom
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.product.description,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2, // Limit to 2 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis on overflow
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
