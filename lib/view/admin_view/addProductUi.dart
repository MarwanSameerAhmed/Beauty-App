import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_pro/controller/company_service.dart';
import 'package:test_pro/controller/category_service.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/controller/image_service.dart';
import 'package:test_pro/model/company.dart';
import 'package:test_pro/model/categorys.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/FormFields.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';
import 'dart:ui';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'dart:typed_data';
import 'package:test_pro/widgets/ElegantToast.dart';

class AddProductUi extends StatefulWidget {
  final Product? product;

  const AddProductUi({super.key, this.product});

  @override
  State<AddProductUi> createState() => _AddProductUiState();
}

class _AddProductUiState extends State<AddProductUi> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  // Editing State
  bool get _isEditing => widget.product != null;

  // State for Stepper
  int _currentStep = 0;

  // State for Images
  File? _mainImageFile;
  List<File> _otherImageFiles = [];
  List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = [];

  // State for Dropdowns
  List<Category> _categories = [];
  List<Company> _companies = [];
  String? _selectedCategoryId;
  String? _selectedCompanyId;

  // Loading States
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();

    if (_isEditing) {
      final product = widget.product!;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _selectedCategoryId = product.categoryId;
      _selectedCompanyId = product.companyId;
      _existingImageUrls = List.from(product.images);
      _uploadedImageUrls = List.from(product.images);
      _currentStep = 1; // Start at details step when editing
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await CategoryService().getCategories().first;
      final companies = await CompanyService().getCompanies().first;
      if (mounted) {
        setState(() {
          _categories = categories;
          _companies = companies;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load data: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _pickMainImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _mainImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickOtherImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _otherImageFiles = pickedFiles.map((file) => File(file.path)).toList();
    });
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == 0) {
      if (_mainImageFile == null && !_isEditing) {
        _showErrorSnackBar('الرجاء اختيار صورة أساسية للمنتج.');
        return;
      }

      setState(() => _isUploading = true);

      try {
        List<File> allImages = [];
        if (_mainImageFile != null) allImages.add(_mainImageFile!);
        allImages.addAll(_otherImageFiles);

        if (allImages.isNotEmpty) {
          List<Uint8List> compressedImages = [];
          for (var imgFile in allImages) {
            final compressed = await ImageService.compressImage(imgFile);
            if (compressed != null) {
              compressedImages.add(compressed);
            }
          }

          if (compressedImages.isEmpty) {
            showElegantToast(
              context,
              'فشل ضغط الصور. يرجى المحاولة مرة أخرى.',
              isSuccess: false,
            );
            return; // Stop execution
          }

          List<String> newUrls = await ProductService().uploadImages(
            compressedImages,
          );
          // In edit mode, combine new URLs with existing ones if needed, or replace.
          // For now, we replace.
          _uploadedImageUrls = newUrls;
        }
        // If no new images are selected in edit mode, _uploadedImageUrls remains unchanged.

        setState(() {
          _currentStep = 1;
        });
      } catch (e) {
        _showErrorSnackBar('فشل رفع الصور: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('الرجاء تعبئة جميع الحقول المطلوبة.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        images: _uploadedImageUrls,
        categoryId: _selectedCategoryId!,
        companyId: _selectedCompanyId!,
      );

      if (_isEditing) {
        await ProductService().updateProduct(product);
      } else {
        await ProductService().addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'تم تحديث المنتج بنجاح!' : 'تمت إضافة المنتج بنجاح!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء حفظ المنتج: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Column(
              children: [
                CustomAdminHeader(
                  title: _isEditing ? 'تعديل منتج' : 'إضافة منتج',
                  subtitle: _isEditing
                      ? 'تعديل تفاصيل المنتج الحالي'
                      : 'اكتب معلومات المنتج بدقة ليتم عرضه بشكل صحيح للعملاء',
                ),
                EasyStepper(
                  activeStep: _currentStep,
                  stepShape: StepShape.rRectangle,
                  stepBorderRadius: 15,
                  borderThickness: 2,
                  padding: const EdgeInsets.all(20),
                  stepRadius: 28,
                  finishedStepTextColor: Colors.black,
                  finishedStepBackgroundColor: const Color(0xFF942A59),
                  activeStepBackgroundColor: const Color(0xFF942A59),
                  unreachedStepBackgroundColor: Colors.white.withOpacity(0.5),
                  unreachedStepBorderColor: const Color(
                    0xFF942A59,
                  ).withOpacity(0.5),
                  activeStepBorderColor: Colors.white,
                  lineStyle: const LineStyle(
                    lineLength: 80,
                    lineSpace: 0,
                    lineType: LineType.normal,
                    defaultLineColor: Color(0xFF942A59),
                    finishedLineColor: Color(0xFF52002C),
                  ),
                  steps: [
                    EasyStep(
                      customStep: const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                      ),
                      title: 'الصور',
                    ),
                    EasyStep(
                      customStep: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                      ),
                      title: 'التفاصيل',
                    ),
                  ],
                  onStepReached: (index) {
                    if (_isEditing) {
                      // In edit mode, allow free navigation
                      setState(() => _currentStep = index);
                      return;
                    }
                    // In add mode, enforce image selection before proceeding
                    if (index > _currentStep && _currentStep == 0) {
                      _handleNextStep();
                    } else {
                      setState(() {
                        _currentStep = index;
                      });
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _currentStep == 0
                      ? _buildImagePickerStep()
                      : _buildDetailsStep(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildControls(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    if (_isUploading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Loader(),
          SizedBox(height: 10),
          Text(
            'جاري رفع الصور...',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (_currentStep == 1)
          Expanded(
            child: GradientElevatedButton(
              onPressed: () => setState(() => _currentStep = 0),
              text: 'السابق',
              isSecondary: true,
            ),
          ),
        if (_currentStep == 1) const SizedBox(width: 20),
        Expanded(
          child: _isSaving
              ? const Loader()
              : GradientElevatedButton(
                  onPressed: _currentStep == 0 ? _handleNextStep : _saveProduct,
                  text: _currentStep == 0
                      ? 'التالي'
                      : (_isEditing ? 'حفظ التعديلات' : 'حفظ المنتج'),
                ),
        ),
      ],
    );
  }

  Widget _buildImagePickerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الصورة الأساسية (إجباري)',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildMainImagePicker(),
        const SizedBox(height: 24),
        const Text(
          'صور إضافية (اختياري)',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildOtherImagesPicker(),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF942A59).withOpacity(0.15),
            borderRadius: BorderRadius.circular(25.0),
            border: Border.all(
              width: 1.5,
              color: const Color(0xFF942A59).withOpacity(0.2),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GlassField(
                  controller: _nameController,
                  hintText: 'اسم المنتج',
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 16),
                GlassField(
                  controller: _descriptionController,
                  hintText: 'الوصف',
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 16),
                GlassField(
                  controller: _priceController,
                  hintText: 'السعر',
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'الحقل مطلوب' : null,
                  textColor: Colors.black,
                ),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildCompanyDropdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainImagePicker() {
    return _buildImagePickerContainer(
      onTap: _pickMainImage,
      child: _mainImageFile == null && _existingImageUrls.isEmpty
          ? _buildPlaceholder('اختر الصورة الأساسية')
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _mainImageFile != null
                  ? Image.file(
                      _mainImageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Image.network(
                      _existingImageUrls.first,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
    );
  }

  Widget _buildOtherImagesPicker() {
    return _buildImagePickerContainer(
      onTap: _pickOtherImages,
      child: _otherImageFiles.isEmpty && (_existingImageUrls.length <= 1)
          ? _buildPlaceholder('اختر صورًا إضافية')
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _otherImageFiles.isNotEmpty
                  ? _otherImageFiles.length
                  : (_existingImageUrls.length > 1
                        ? _existingImageUrls.length - 1
                        : 0),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _otherImageFiles.isNotEmpty
                      ? Image.file(_otherImageFiles[index], fit: BoxFit.contain)
                      : Image.network(
                          _existingImageUrls[index + 1],
                          fit: BoxFit.contain,
                        ),
                );
              },
            ),
    );
  }

  Widget _buildImagePickerContainer({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: child,
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 50, color: Colors.black54),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCompanyId,
      isExpanded: true,
      hint: const Text('اختر الشركة', style: TextStyle(color: Colors.black54)),
      decoration: _glassInputDecoration('الشركة'),
      dropdownColor: Colors.pink[100]?.withOpacity(0.9),
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.bold,
      ),
      items: _companies.map((company) {
        return DropdownMenuItem<String>(
          value: company.id,
          child: Text(company.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCompanyId = value),
      validator: (value) => value == null ? 'الرجاء اختيار شركة' : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      isExpanded: true,
      hint: const Text('اختر الصنف', style: TextStyle(color: Colors.black54)),
      decoration: _glassInputDecoration('الصنف'),
      dropdownColor: Colors.pink[100]?.withOpacity(0.9),
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.bold,
      ),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category.id,
              child: Text(
                category.name,
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
      validator: (value) => value == null ? 'الرجاء اختيار صنف' : null,
    );
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
}
