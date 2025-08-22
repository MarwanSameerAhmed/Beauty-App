import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/controller/ads_service.dart';
import 'package:test_pro/controller/company_service.dart';
import 'package:test_pro/model/ad.dart';
import 'package:test_pro/model/company.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';

class AddAdForm extends StatefulWidget {
  @override
  _AddAdFormState createState() => _AddAdFormState();
}

class _AddAdFormState extends State<AddAdForm> {
  final AdsService _adsService = AdsService();
  final CompanyService _companyService = CompanyService();
  String _selectedShape = 'rectangle';
  List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Company> _companies = [];
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final companies = await _companyService.getCompaniesFuture();
    setState(() {
      _companies = companies;
    });
  }

  Future<void> _pickImage() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCompany == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار شركة')));
      return;
    }
    if (_selectedShape == 'square' && _imageFiles.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار صورتين للإعلان المربع')),
      );
      return;
    }
    if (_selectedShape == 'rectangle' && _imageFiles.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار صورة واحدة للإعلان المستطيل'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (var imageFile in _imageFiles) {
        String imageUrl = await _adsService.uploadImage(imageFile);
        Ad newAd = Ad(
          id: '', // Firestore will generate this
          shapeType: _selectedShape,
          imageUrl: imageUrl,
          companyId: _selectedCompany!.id,
          companyName: _selectedCompany!.name,
        );
        await _adsService.addAd(newAd);
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل رفع الصور: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomAdminHeader(
                  title: 'إضافة إعلان جديد',
                  subtitle: 'إدارة الإعلانات وتحميل صور للإعلانات',
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
                                _buildImagePickerSection(),
                                const SizedBox(height: 32),
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else
                                  _buildAnimatedWidget(
                                    delay: const Duration(milliseconds: 400),
                                    child: GradientElevatedButton(
                                      text: 'إضافة الإعلان',
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
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        child: _imageFiles.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Image.file(_imageFiles[index], fit: BoxFit.cover);
                  },
                ),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.black,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختر صورة أو أكثر',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
                _imageFiles.clear(); // Clear images when shape changes
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
