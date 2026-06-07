import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glamify/widgets/home_shimmer.dart';

/// ويدجت موحّد للصور مع كاش تلقائي
/// يستبدل Image.network في كل مكان
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) {
          return placeholder ??
              ShimmerEffect(
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: ShimmerColors.base,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: ShimmerColors.highlight.withOpacity(0.8),
                    ),
                  ),
                ),
              );
        },
        errorWidget: (context, url, error) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: ShimmerColors.base.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 30,
                    color: ShimmerColors.base,
                  ),
                ),
              );
        },
      ),
    );
  }
}
