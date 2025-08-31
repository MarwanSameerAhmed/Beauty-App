import 'package:flutter/material.dart';
import 'package:test_pro/controller/carousel_ad_service.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/view/admin_view/add_carousel_ad_form.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';

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
                  subtitle: 'إضافة وحذف وتعديل صور الكاروسيل في الصفحة الرئيسية',
                ),
                Expanded(
                  child: StreamBuilder<List<CarouselAd>>(
                    stream: _carouselAdService.getCarouselAds(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('لا توجد إعلانات حالياً.'));
                      }

                      final ads = snapshot.data!;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: ads.length,
                        itemBuilder: (context, index) {
                          final ad = ads[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Image.network(ad.imageUrl, width: 100, fit: BoxFit.cover),
                              title: Text('إعلان رقم ${index + 1}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text('هل أنت متأكد من رغبتك في حذف هذا الإعلان؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _carouselAdService.deleteCarouselAd(ad.id);
                                  }
                                },
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
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCarouselAdForm()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
