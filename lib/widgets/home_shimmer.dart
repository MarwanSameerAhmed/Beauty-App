import 'package:flutter/material.dart';
import 'package:glamify/utils/responsive_helper.dart';

/// ألوان الشيمر - متناسقة مع خلفية التطبيق الوردية
class ShimmerColors {
  static const Color background = Color.fromARGB(255, 249, 237, 237); // خلفية التطبيق
  static const Color base = Color(0xFFF5D5D5); // وردي فاتح
  static const Color highlight = Color(0xFFFFF0F0); // أبيض وردي
  static const Color shimmerGlow = Color(0xFFFFFFFF); // أبيض ناصع
}

/// تأثير الشيمر الأساسي - قابل لإعادة الاستخدام
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                ShimmerColors.base,
                ShimmerColors.highlight,
                ShimmerColors.shimmerGlow,
                ShimmerColors.highlight,
                ShimmerColors.base,
              ],
              stops: [
                0.0,
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

/// شيمر مستطيل بسيط
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ShimmerColors.base,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// شيمر كرت المنتج
class ProductCardShimmer extends StatelessWidget {
  final double? width;
  final double? height;

  const ProductCardShimmer({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final borderRadius = ResponsiveHelper.borderRadius + 10;
    final cardWidth = width ?? ResponsiveHelper.productCardWidth;

    return ShimmerEffect(
      child: Container(
        width: cardWidth,
        height: height,
        decoration: BoxDecoration(
          color: ShimmerColors.base.withOpacity(0.5),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: ShimmerColors.highlight.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: ShimmerColors.base,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                ),
                child: Stack(
                  children: [
                    // أيقونة صورة في المنتصف
                    Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: ShimmerColors.highlight.withOpacity(0.8),
                      ),
                    ),
                    // زر المفضلة الوهمي
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ShimmerColors.base.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // تفاصيل المنتج
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // زر السلة الوهمي
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: ShimmerColors.base,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // النصوص الوهمية
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: ShimmerColors.base,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: 80,
                            decoration: BoxDecoration(
                              color: ShimmerColors.base,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 10,
                            width: 60,
                            decoration: BoxDecoration(
                              color: ShimmerColors.base,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شيمر قسم المنتجات (عنوان + كروت أفقية)
class ProductSectionShimmer extends StatelessWidget {
  const ProductSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // عنوان القسم
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveHelper.horizontalPadding,
            right: ResponsiveHelper.horizontalPadding + 8,
            top: ResponsiveHelper.verticalSpacing,
            bottom: ResponsiveHelper.verticalSpacing,
          ),
          child: ShimmerEffect(
            child: Container(
              height: 22,
              width: 120,
              decoration: BoxDecoration(
                color: ShimmerColors.base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // كروت المنتجات الأفقية
        SizedBox(
          height: ResponsiveHelper.productSectionHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding,
            ),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(
              width: ResponsiveHelper.isMobile ? 12 : 16,
            ),
            itemBuilder: (context, index) {
              return SizedBox(
                width: ResponsiveHelper.productCardWidth,
                child: const ProductCardShimmer(),
              );
            },
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing * 2),
      ],
    );
  }
}

/// شيمر الكاروسيل
class CarouselShimmer extends StatelessWidget {
  const CarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final carouselHeight = ResponsiveHelper.carouselHeight;
    final borderRadius = ResponsiveHelper.borderRadius;

    return Column(
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
            child: ShimmerEffect(
              child: Container(
                height: 22,
                width: 100,
                decoration: BoxDecoration(
                  color: ShimmerColors.base,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // الكاروسيل الوهمي
        ShimmerEffect(
          child: Container(
            height: carouselHeight,
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding + 10,
            ),
            decoration: BoxDecoration(
              color: ShimmerColors.base,
              borderRadius: BorderRadius.circular(borderRadius + 4),
              border: Border.all(
                color: ShimmerColors.highlight.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.view_carousel_outlined,
                    size: 50,
                    color: ShimmerColors.highlight.withOpacity(0.8),
                  ),
                ),
                // شريط اسم الشركة الوهمي
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(borderRadius + 2),
                        bottomRight: Radius.circular(borderRadius + 2),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          ShimmerColors.base.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing + 5),
        // النقاط الوهمية
        ShimmerEffect(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: index == 0 ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == 0
                      ? ShimmerColors.base
                      : ShimmerColors.base.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ],
    );
  }
}

/// شيمر الإعلان المستطيل
class AdRectangleShimmer extends StatelessWidget {
  const AdRectangleShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.verticalSpacing * 0.8,
        horizontal: ResponsiveHelper.horizontalPadding,
      ),
      child: ShimmerEffect(
        child: Container(
          width: double.infinity,
          height: ResponsiveHelper.rectangleAdHeight,
          decoration: BoxDecoration(
            color: ShimmerColors.base,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: ShimmerColors.highlight.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: ShimmerColors.highlight.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}

/// شيمر قسم الإعلانات (عنوان + إعلانات)
class AdSectionShimmer extends StatelessWidget {
  const AdSectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // عنوان القسم
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveHelper.horizontalPadding,
            right: ResponsiveHelper.horizontalPadding + 8,
            top: ResponsiveHelper.verticalSpacing,
            bottom: ResponsiveHelper.verticalSpacing,
          ),
          child: ShimmerEffect(
            child: Container(
              height: 22,
              width: 110,
              decoration: BoxDecoration(
                color: ShimmerColors.base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const AdRectangleShimmer(),
        SizedBox(height: ResponsiveHelper.verticalSpacing),
      ],
    );
  }
}

/// شيمر الهوم بيج كاملة - يظهر عند أول فتح
class HomePageShimmer extends StatelessWidget {
  const HomePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const CarouselShimmer(),
        const AdSectionShimmer(),
        const ProductSectionShimmer(),
      ]),
    );
  }
}
