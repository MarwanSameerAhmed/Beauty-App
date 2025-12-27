import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:glamify/controller/favorites_service.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/ElegantToast.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/utils/responsive_helper.dart';

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
    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);
    
    final borderRadius = ResponsiveHelper.borderRadius + 10;
    final titleFontSize = ResponsiveHelper.bodyFontSize;
    final descFontSize = ResponsiveHelper.smallFontSize;
    final buttonSize = ResponsiveHelper.isMobile ? 38.0 : 44.0;
    final favoriteButtonSize = ResponsiveHelper.isMobile ? 36.0 : 42.0;
    
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildImage(borderRadius, favoriteButtonSize)),
                  Expanded(flex: 2, child: _buildProductDetails(titleFontSize, descFontSize, buttonSize)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(double borderRadius, double favoriteButtonSize) {
    return Hero(
      tag: 'product-image-${widget.product.id}',
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
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
          Positioned(
            top: ResponsiveHelper.isMobile ? 12 : 14,
            right: ResponsiveHelper.isMobile ? 12 : 14,
            child: _buildFavoriteButton(favoriteButtonSize),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(double size) {
    return Container(
      width: size,
      height: size,
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
              size: size * 0.55,
            ),
            onPressed: () =>
                _favoritesService.toggleFavorite(widget.product.id),
            splashRadius: size * 0.5,
          );
        },
      ),
    );
  }

  Widget _buildProductDetails(double titleFontSize, double descFontSize, double buttonSize) {
    final padding = ResponsiveHelper.isMobile ? 12.0 : 14.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // زر إضافة للسلة
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF52002C), Color(0xFF942A59)],
                  stops: [0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius * 0.8),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius * 0.8),
                child: InkWell(
                  onTap: _addToCart,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius * 0.8),
                  child: Center(
                    child: _isAddingToCart
                        ? SizedBox(
                            width: buttonSize * 0.52,
                            height: buttonSize * 0.52,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: buttonSize * 0.52,
                          ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: padding),
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.product.name,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    widget.product.description,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: descFontSize,
                      fontWeight: FontWeight.w300,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
