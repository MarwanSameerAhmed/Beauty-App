import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/controller/carousel_ad_service.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/widgets/loader.dart';

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

        final ads = snapshot.data!;

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: ads.length,
              itemBuilder: (context, index, realIndex) {
                final ad = ads[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Adjusted for consistency
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      ad.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder:
                          (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) return child;
                            return const Center(child: Loader());
                          },
                      errorBuilder:
                          (
                            BuildContext context,
                            Object exception,
                            StackTrace? stackTrace,
                          ) {
                            return const Icon(Icons.error);
                          },
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 200,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ads.asMap().entries.map((entry) {
                bool isActive = _currentIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isActive ? 14.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? const Color(0xFFf9d5d3)
                        : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
