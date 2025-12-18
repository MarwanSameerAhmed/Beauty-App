import 'package:flutter/material.dart';
import 'package:glamify/controller/carousel_ad_service.dart';
import 'package:glamify/controller/image_service.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/controller/universal_image_picker.dart';
import 'package:glamify/model/carousel_ad.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';

class AddCarouselAdForm extends StatefulWidget {
  final CarouselAd? carouselAd; // للتعديل
  
  const AddCarouselAdForm({super.key, this.carouselAd});

  @override
  _AddCarouselAdFormState createState() => _AddCarouselAdFormState();
}

class _AddCarouselAdFormState extends State<AddCarouselAdForm> {
  final CarouselAdService _carouselAdService = CarouselAdService();
  final CompanyService _companyService = CompanyService();
  ImagePickerResult? _selectedImage;
  bool _isLoading = false;
  List<Company> _companies = [];
  Company? _selectedCompany;
  String? _existingImageUrl;

  // للتحقق من وضع التعديل
  bool get _isEditing => widget.carouselAd != null;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    
    // إذا كان في وضع التعديل، املأ البيانات
    if (_isEditing) {
      _existingImageUrl = widget.carouselAd!.imageUrl;
      // سيتم تعيين الشركة المحددة بعد تحميل قائمة الشركات
    }
  }

  Future<void> _fetchCompanies() async {
    final companies = await _companyService.getCompaniesFuture();
    if (mounted) {
      setState(() {
        _companies = companies;
        
        // إذا كان في وضع التعديل، اختر الشركة المحددة
        if (_isEditing) {
          _selectedCompany = _companies.firstWhere(
            (company) => company.id == widget.carouselAd!.companyId,
            orElse: () => _companies.first,
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await UniversalImagePicker.pickSingleImage();
      if (result != null && result.isValid && result.isSupportedFormat) {
        if (!result.isSizeAcceptable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حجم الصورة كبير جداً. يجب أن يكون أقل من 5 ميجابايت')),
          );
          return;
        }
        setState(() {
          _selectedImage = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  InputDecoration _glassInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontFamily: 'Tajawal',
        color: Colors.black.withOpacity(0.7),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.4),
          width: 1.2,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // في وضع التعديل، لا نحتاج صورة جديدة إذا لم يتم اختيارها
    if (_selectedImage == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صورة للإعلان')));
      return;
    }

    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار الشركة')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _existingImageUrl ?? '';
      
      // رفع صورة جديدة فقط إذا تم اختيارها
      if (_selectedImage != null) {
        final compressedImage = await ImageService.compressImageBytes(_selectedImage!.bytes);
        if (compressedImage == null) {
          throw Exception('فشل ضغط الصورة');
        }
        imageUrl = await _carouselAdService.uploadImage(compressedImage);
      }
      
      CarouselAd ad = CarouselAd(
        id: _isEditing ? widget.carouselAd!.id : '', 
        imageUrl: imageUrl,
        companyId: _selectedCompany!.id,
        companyName: _selectedCompany!.name,
      );
      
      if (_isEditing) {
        await _carouselAdService.updateCarouselAd(ad);
      } else {
        await _carouselAdService.addCarouselAd(ad);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'تم تحديث الإعلان بنجاح' : 'تمت إضافة الإعلان بنجاح')),
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
                CustomAdminHeader(
                  title: _isEditing ? 'تعديل إعلان كاروسيل' : 'إضافة إعلان كاروسيل',
                  subtitle: _isEditing ? 'تعديل بيانات الإعلان الحالي' : 'اختر صورة لرفعها إلى الكاروسيل',
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
                            child: _selectedImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14.0),
                                    child: Image.memory(_selectedImage!.bytes, fit: BoxFit.cover, width: double.infinity),
                                  )
                                : _isEditing && _existingImageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14.0),
                                        child: Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity),
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
                        const SizedBox(height: 24),
                        
                        // Company Selection Dropdown
                        DropdownButtonFormField<Company>(
                          value: _selectedCompany,
                          isExpanded: true,
                          hint: const Text('اختر الشركة', style: TextStyle(color: Colors.black54)),
                          decoration: _glassInputDecoration('الشركة'),
                          dropdownColor: Colors.pink[100]?.withOpacity(0.9),
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                          items: _companies.map((Company company) {
                            return DropdownMenuItem<Company>(
                              value: company,
                              child: Text(company.name),
                            );
                          }).toList(),
                          onChanged: (Company? newValue) {
                            setState(() {
                              _selectedCompany = newValue;
                            });
                          },
                          validator: (value) => value == null ? 'الرجاء اختيار شركة' : null,
                        ),
                        
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const Center(child: Loader())
                        else
                          GradientElevatedButton(
                            text: _isEditing ? 'حفظ التعديلات' : 'إضافة الإعلان',
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
