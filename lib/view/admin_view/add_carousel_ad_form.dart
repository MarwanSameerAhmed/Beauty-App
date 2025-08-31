import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_pro/controller/carousel_ad_service.dart';
import 'package:test_pro/controller/image_service.dart';
import 'package:test_pro/model/carousel_ad.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class AddCarouselAdForm extends StatefulWidget {
  const AddCarouselAdForm({super.key});

  @override
  _AddCarouselAdFormState createState() => _AddCarouselAdFormState();
}

class _AddCarouselAdFormState extends State<AddCarouselAdForm> {
  final CarouselAdService _carouselAdService = CarouselAdService();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صورة للإعلان')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final compressedImage = await ImageService.compressImage(_imageFile!);
      if (compressedImage == null) {
        throw Exception('فشل ضغط الصورة');
      }
      
      String imageUrl = await _carouselAdService.uploadImage(compressedImage);
      
      CarouselAd newAd = CarouselAd(id: '', imageUrl: imageUrl);
      
      await _carouselAdService.addCarouselAd(newAd);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الإعلان بنجاح')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حفظ الإعلان: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                  title: 'إضافة إعلان كاروسيل',
                  subtitle: 'اختر صورة لرفعها إلى الكاروسيل',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15.0),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14.0),
                                    child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, size: 50),
                                        SizedBox(height: 8),
                                        Text('اختر صورة'),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const Center(child: Loader())
                        else
                          GradientElevatedButton(
                            text: 'إضافة الإعلان',
                            onPressed: _submit,
                            isLoading: _isLoading,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
