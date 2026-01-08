import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/ads_service.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/controller/ads_section_settings_service.dart';
import 'package:glamify/model/ad.dart';
import 'package:glamify/model/ads_section_settings.dart';
import 'package:glamify/controller/image_service.dart';
import 'package:glamify/controller/universal_image_picker.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:glamify/utils/responsive_helper.dart';

class AddAdForm extends StatefulWidget {
  final Ad? ad;

  const AddAdForm({super.key, this.ad});

  @override
  _AddAdFormState createState() => _AddAdFormState();
}

class _AddAdFormState extends State<AddAdForm> {
  final AdsService _adsService = AdsService();
  final CompanyService _companyService = CompanyService();
  final AdsSectionSettingsService _sectionService = AdsSectionSettingsService();
  
  bool get _isEditing => widget.ad != null;

  String _selectedShape = 'rectangle';
  List<ImagePickerResult> _selectedImages = [];
  String? _existingImageUrl;
  bool _isLoading = false;
  List<Company> _companies = [];
  Company? _selectedCompany;
  List<AdsSectionSettings> _sections = [];
  AdsSectionSettings? _selectedSection;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _fetchSections();
    if (_isEditing) {
      final ad = widget.ad!;
      _selectedShape = ad.shapeType;
      _existingImageUrl = ad.imageUrl;
      // البحث عن القسم المحدد للإعلان
      _findSelectedSection(ad.sectionId);
    }
  }

  Future<void> _fetchSections() async {
    _sectionService.getSectionSettings().listen((sections) {
      if (mounted) {
        setState(() {
          // فلترة أقسام الإعلانات فقط
          _sections = sections.where((section) => section.type == 'ads').toList();
          // إذا لم يكن هناك قسم محدد، اختر الأول
          if (_selectedSection == null && _sections.isNotEmpty) {
            _selectedSection = _sections.first;
          }
        });
      }
    });
  }

  void _findSelectedSection(String sectionId) {
    // سيتم تحديد القسم عند جلب الأقسام
    Future.delayed(const Duration(milliseconds: 500), () {
      final section = _sections.firstWhere(
        (s) => s.id == sectionId,
        orElse: () => _sections.isNotEmpty ? _sections.first : AdsSectionSettings.getDefaultSettings().first,
      );
      if (mounted) {
        setState(() {
          _selectedSection = section;
        });
      }
    });
  }

  Future<void> _fetchCompanies() async {
    final companies = await _companyService.getCompaniesFuture();
    if (mounted) {
      setState(() {
        _companies = companies;
        if (_isEditing) {
          _selectedCompany = _companies.firstWhere(
            (c) => c.id == widget.ad!.companyId,
            orElse: () => _companies.first, 
          );
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      if (_isEditing) {
        // في وضع التعديل، اختيار صورة واحدة فقط
        final result = await UniversalImagePicker.pickSingleImage();
        if (result != null && result.isValid && result.isSupportedFormat) {
          if (!result.isSizeAcceptable) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('حجم الصورة كبير جداً. يجب أن يكون أقل من 5 ميجابايت')),
            );
            return;
          }
          setState(() {
            _selectedImages = [result];
          });
        }
      } else {
        // في وضع الإضافة، اختيار صور متعددة
        final results = await UniversalImagePicker.pickMultipleImages();
        if (results.isNotEmpty) {
          // التحقق من صحة جميع الصور
          final validImages = results.where((img) => 
            img.isValid && img.isSupportedFormat && img.isSizeAcceptable
          ).toList();
          
          if (validImages.length != results.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تجاهل بعض الصور غير المدعومة أو الكبيرة الحجم')),
            );
          }
          
          setState(() {
            _selectedImages = validImages;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصور: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار شركة')));
      return;
    }

    if (!_isEditing) {
      // للمستطيل: صورة واحدة فقط
      if (_selectedShape == 'rectangle' && _selectedImages.length != 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار صورة واحدة للإعلان المستطيل')),
        );
        return;
      }
      // للمربع: صورة واحدة أو صورتين (اختياري)
      if (_selectedShape == 'square' && (_selectedImages.isEmpty || _selectedImages.length > 2)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار صورة واحدة أو صورتين للإعلان المربع')),
        );
        return;
      }
    }

    if (_selectedImages.isEmpty && !_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صورة للإعلان')));
        return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        String imageUrl = _existingImageUrl ?? '';
        if (_selectedImages.isNotEmpty) {
          final compressedImage = await ImageService.compressImageBytes(_selectedImages.first.bytes);
          if (compressedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل ضغط الصورة. يرجى المحاولة مرة أخرى.')),
            );
            setState(() { _isLoading = false; });
            return;
          }
          imageUrl = await _adsService.uploadImage(compressedImage);
        }
        // التأكد من وجود sectionId صالح
        String finalSectionId = _selectedSection?.id ?? 
                                widget.ad!.sectionId;
        
        // إذا كان sectionId فارغاً، استخدم القيمة الافتراضية
        if (finalSectionId.isEmpty) {
          finalSectionId = _sections.isNotEmpty 
              ? _sections.first.id 
              : 'middle_section';
        }
        
        final ad = Ad(
          id: widget.ad!.id,
          shapeType: _selectedShape,
          imageUrl: imageUrl,
          companyId: _selectedCompany!.id,
          companyName: _selectedCompany!.name,
          sectionId: finalSectionId,
        );
        await _adsService.updateAd(ad);
      } else {
        for (var selectedImage in _selectedImages) {
          final compressedImage = await ImageService.compressImageBytes(selectedImage.bytes);
          if (compressedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل ضغط الصورة. يرجى المحاولة مرة أخرى.')),
            );
            setState(() {
              _isLoading = false;
            });
            return;
          }
          String imageUrl = await _adsService.uploadImage(compressedImage);
          Ad newAd = Ad(
            id: '', // Firestore will generate this
            shapeType: _selectedShape,
            imageUrl: imageUrl,
            companyId: _selectedCompany!.id,
            companyName: _selectedCompany!.name,
            sectionId: _selectedSection?.id ?? 'middle_section',
          );
          await _adsService.addAd(newAd);
        }
      }
      
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'تم تحديث الإعلان بنجاح' : 'تمت إضافة الإعلان بنجاح')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل حفظ الإعلان: $e')));
      }
    } finally {
      if(mounted){
        setState(() => _isLoading = false);
      }
    }
  }

  Widget buildImageWidget() {
    if (_selectedImages.isNotEmpty) {
      // للمستطيل: صورة واحدة تمتد على كامل المساحة
      if (_selectedShape == 'rectangle') {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14.0),
          child: Image.memory(
            _selectedImages.first.bytes, 
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      } else {
        // للمربع: عرض الصور في grid
        return ClipRRect(
          borderRadius: BorderRadius.circular(14.0),
          child: _selectedImages.length == 1
              ? Image.memory(
                  _selectedImages.first.bytes, 
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Row(
                  children: _selectedImages.map((img) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.memory(img.bytes, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        );
      }
    } else if (_existingImageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14.0),
        child: Image.network(
          _existingImageUrl!, 
          fit: BoxFit.cover, 
          width: double.infinity, 
          height: double.infinity,
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              color: Colors.black,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedShape == 'rectangle' 
                  ? 'اختر صورة واحدة' 
                  : 'اختر صورة أو صورتين',
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAdminHeader(
                  title: _isEditing ? 'تعديل إعلان' : 'إضافة إعلان جديد',
                  subtitle: _isEditing ? 'تعديل بيانات الإعلان الحالي' : 'إدارة الإعلانات وتحميل صور للإعلانات',
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 40.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9D5D3).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(25.0),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildShapeDropdown(),
                                const SizedBox(height: 24),
                                _buildCompanyDropdown(),
                                const SizedBox(height: 24),
                                _buildSectionDropdown(),
                                const SizedBox(height: 24),
                                _buildImagePickerSection(),
                                const SizedBox(height: 32),
                                if (_isLoading)
                                  const Center(
                                    child: Loader(),
                                  )
                                else
                                  _buildAnimatedWidget(
                                    delay: const Duration(milliseconds: 400),
                                    child: GradientElevatedButton(
                                      text: _isEditing ? 'حفظ التعديلات' : 'إضافة الإعلان',
                                      onPressed: _submit,
                                      isLoading: _isLoading,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildAnimatedWidget({
    required Duration delay,
    required Widget child,
  }) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      delay: delay,
      curve: Curves.easeOut,
      builder: (context, value, innerChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: innerChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildImagePickerSection() {
    // حساب الارتفاع بناءً على نوع الإعلان
    final double imageHeight = _selectedShape == 'rectangle'
        ? ResponsiveHelper.rectangleAdHeight
        : ResponsiveHelper.squareAdWidth;
    
    // القياسات المثالية بناءً على النوع
    final String recommendedSize = _selectedShape == 'rectangle'
        ? '1200×500 بكسل (نسبة 2.4:1)'
        : '1080×1080 بكسل (نسبة 1:1)';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: imageHeight,
            width: _selectedShape == 'square' ? imageHeight : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            ),
            child: buildImageWidget(),
          ),
        ),
        const SizedBox(height: 8),
        // إرشادات القياسات المثالية
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'القياس المثالي: $recommendedSize',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedShape == 'rectangle'
                          ? 'إعلان عريض بعرض الشاشة - صورة واحدة'
                          : 'إعلان مربع - صورة واحدة أو صورتين (كل صورة إعلان منفصل)',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShapeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedShape,
          isExpanded: true,
          dropdownColor: const Color(0xFFC15C5C).withOpacity(0.9),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          items: ['rectangle', 'square']
              .map(
                (label) => DropdownMenuItem(
                  value: label,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedShape = value;
                _selectedImages.clear(); // Clear images when shape changes
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AdsSectionSettings>(
          value: _selectedSection,
          isExpanded: true,
          dropdownColor: const Color(0xFFC15C5C).withOpacity(0.9),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          hint: const Text(
            'اختر القسم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black54,
            ),
          ),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          items: _sections
              .map(
                (section) => DropdownMenuItem(
                  value: section,
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.black,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedSection = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Company>(
          value: _selectedCompany,
          isExpanded: true,
          hint: const Text(
            'اختر شركة',
            style: TextStyle(color: Colors.black, fontFamily: 'Tajawal'),
          ),
          dropdownColor: const Color(0xFFC15C5C).withOpacity(0.9),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          items: _companies.map((Company company) {
            return DropdownMenuItem<Company>(
              value: company,
              child: Text(
                company.name,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.black,
                ),
              ),
            );
          }).toList(),
          onChanged: (Company? newValue) {
            setState(() {
              _selectedCompany = newValue;
            });
          },
        ),
      ),
    );
  }
}
