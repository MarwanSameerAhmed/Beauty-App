import 'package:flutter/material.dart';
import 'package:test_pro/controller/carousel_ad_service.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/view/admin_view/add_carousel_ad_form.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';

class ManageCarouselAdsScreen extends StatelessWidget {
  final CarouselAdService _carouselAdService = CarouselAdService();

  ManageCarouselAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              children: [
                const CustomAdminHeader(
                  title: 'إدارة إعلانات الكاروسيل',
                  subtitle:
                      'إضافة وحذف وتعديل صور الكاروسيل في الصفحة الرئيسية',
                ),
                Expanded(
                  child: StreamBuilder<List<CarouselAd>>(
                    stream: _carouselAdService.getCarouselAds(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('حدث خطأ: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('لا توجد إعلانات حالياً.'),
                        );
                      }

                      final ads = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: ads.length,
                        itemBuilder: (context, index) {
                          final ad = ads[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 16.0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF9D5D3).withOpacity(0.7),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // صورة الإعلان
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ad.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.error_outline,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // معلومات الإعلان
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ad.companyName.isNotEmpty
                                              ? ad.companyName
                                              : 'إعلان رقم ${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Tajawal',
                                            color: Color(0xFF52002C),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'إعلان كاروسيل',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Tajawal',
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // أزرار التعديل والحذف
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // زر التعديل
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF52002C,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF52002C,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Color(0xFF52002C),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AddCarouselAdForm(
                                                      carouselAd: ad,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // زر الحذف
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            await showElegantDialog(
                                              context: context,
                                              child: ConfirmActionDialog(
                                                message:
                                                    'هل أنت متأكد من رغبتك في حذف هذا الإعلان؟',
                                                confirmText: 'حذف',
                                                cancelText: 'إلغاء',
                                                onConfirm: () async {
                                                  await _carouselAdService
                                                      .deleteCarouselAd(ad.id);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddCarouselAdForm()),
            );
          },
          backgroundColor: const Color(0xFF942A59),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
