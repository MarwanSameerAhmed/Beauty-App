import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:test_pro/controller/favorites_service.dart';
import 'package:test_pro/model/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final FavoritesService _favoritesService = FavoritesService();
  final double? width;
  final double? height;

  ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
      onTap: onTap,
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
                Expanded(flex: 3, child: _buildImageSection()),
                Expanded(flex: 2, child: _buildTextSection()),
              ],
            ),
          ),
        ),
      ),
    ), // This was missing
    );
  }

  Widget _buildImageSection() {
    return Hero(
      tag: 'product-image-${product.id}',
      child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25.0),
            ),
            child: Image.network(
              product.images.first,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFC15C5C).withOpacity(0.7),
                  ),
                );
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
          top: 12,
          right: 12,
          child: _buildFavoriteButton(),
        ), 
      ],
    ));
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
          final isFavorite = favoriteIds.contains(product.id);
          return IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFF9D5D3) : Colors.white,
              size: 20,
            ),
            onPressed: () => _favoritesService.toggleFavorite(product.id),
            splashRadius: 18,
          );
        },
      ),
    );
  }

  Widget _buildTextSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            product.name,
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
          Text(
            product.description,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: Colors.black.withOpacity(0.6),
              height: 1.3,
            ),
            textAlign: TextAlign.right, // Align text to the right for Arabic
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
