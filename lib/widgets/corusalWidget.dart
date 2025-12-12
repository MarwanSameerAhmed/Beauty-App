import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/controller/carousel_ad_service.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/widgets/ad_loading_skeleton.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/view/company_products_page.dart';
import 'dart:ui';

class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key});

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  int _currentIndex = 0;
  final CarouselAdService _carouselAdService = CarouselAdService();
  late Stream<List<CarouselAd>> _carouselAdsStream;

  @override
  void initState() {
    super.initState();
    _carouselAdsStream = _carouselAdService.getCarouselAds();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CarouselAd>>(
      stream: _carouselAdsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 225, // Same height as carousel + indicator
            child: Center(child: Loader()),
          );
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Don't show anything on error
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show if no ads
        }

        // فلترة البانرات الظاهرة فقط وترتيبها
        final visibleCarouselAds = snapshot.data!
            .where((ad) => ad.isVisible)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (visibleCarouselAds.isEmpty) {
          return const SizedBox.shrink();
        }

        final ads = visibleCarouselAds;

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: ads.length,
              itemBuilder: (context, index, realIndex) {
                final ad = ads[index];
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
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              // الصورة الرئيسية مع مؤشر التحميل الأنيق
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: AdImageWithLoading(
                                  imageUrl: ad.imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  isRectangle: true,
                                ),
                              ),

                              // شريط اسم الشركة في الأسفل
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    ad.companyName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 220,

                enlargeCenterPage: true,
                autoPlay: true,
                viewportFraction: 0.94,
                autoPlayCurve: Curves.easeInOut,
                autoPlayInterval: const Duration(seconds: 4),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 15),

            // مؤشرات محسنة مع تصميم زجاجي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  215,
                  211,
                  211,
                ).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: ads.asMap().entries.map((entry) {
                  bool isActive = _currentIndex == entry.key;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    width: isActive ? 24.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFF52002C), Color(0xFF942A59)],
                            )
                          : null,
                      color: isActive ? null : Colors.white.withOpacity(0.4),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF52002C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
