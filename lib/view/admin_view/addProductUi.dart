import 'package:flutter/material.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/controller/category_service.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/controller/image_service.dart';
import 'package:glamify/controller/universal_image_picker.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/model/categorys.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';
import 'dart:ui';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'dart:typed_data';
import 'package:glamify/widgets/ElegantToast.dart';
import 'package:glamify/utils/responsive_helper.dart';

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
  ImagePickerResult? _mainImage;
  List<ImagePickerResult> _otherImages = [];
  List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = [];

  // State for Dropdowns
  List<Category> _categories = []; // Holds all categories
  List<Category> _mainCategories = [];
  List<Category> _subCategories = [];
  List<Company> _companies = [];
  String? _selectedMainCategoryId;
  String? _selectedSubCategoryId; // This will be the product's categoryId
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
      // Category will be set in _loadInitialData after categories are loaded
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
          _mainCategories = categories.where((c) => c.parentId == null).toList();
          _companies = companies;

          if (_isEditing && widget.product!.categoryId.isNotEmpty) {
            final productCategoryId = widget.product!.categoryId;
            final selectedCategory = _categories.firstWhere((c) => c.id == productCategoryId, orElse: () => categories.firstWhere((c) => c.id == productCategoryId));

            if (selectedCategory.parentId != null) {
              // Product is in a sub-category
              _selectedMainCategoryId = selectedCategory.parentId;
              _subCategories = _categories.where((c) => c.parentId == _selectedMainCategoryId).toList();
              _selectedSubCategoryId = productCategoryId;
            } else {
              // Product is in a main category
              _selectedMainCategoryId = productCategoryId;
              _subCategories = _categories.where((c) => c.parentId == _selectedMainCategoryId).toList();
              _selectedSubCategoryId = null; // No sub-category selected initially
            }
          }
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
    try {
      final result = await UniversalImagePicker.pickSingleImage();
      if (result != null && result.isValid && result.isSupportedFormat) {
        if (!result.isSizeAcceptable) {
          _showErrorSnackBar('حجم الصورة كبير جداً. يجب أن يكون أقل من 5 ميجابايت');
          return;
        }
        setState(() {
          _mainImage = result;
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _pickOtherImages() async {
    try {
      final results = await UniversalImagePicker.pickMultipleImages();
      if (results.isNotEmpty) {
        final validImages = results.where((img) => 
          img.isValid && img.isSupportedFormat && img.isSizeAcceptable
        ).toList();
        
        if (validImages.length != results.length) {
          _showErrorSnackBar('تم تجاهل بعض الصور غير المدعومة أو الكبيرة الحجم');
        }
        
        setState(() {
          _otherImages = validImages;
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصور: $e');
    }
  }

  Future<void> _handleNextStep() async {
    if (_currentStep == 0) {
      if (_mainImage == null && !_isEditing) {
        _showErrorSnackBar('الرجاء اختيار صورة أساسية للمنتج.');
        return;
      }

      setState(() => _isUploading = true);

      try {
        List<ImagePickerResult> allImages = [];
        if (_mainImage != null) allImages.add(_mainImage!);
        allImages.addAll(_otherImages);

        if (allImages.isNotEmpty) {
          List<Uint8List> compressedImages = [];
          for (var imageResult in allImages) {
            final compressed = await ImageService.compressImageBytes(imageResult.bytes);
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
        categoryId: _selectedSubCategoryId ?? _selectedMainCategoryId!,
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
    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);
    
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
        // إرشادات القياسات المثالية
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'القياس المثالي لصور المنتجات: 800×800 بكسل (نسبة 1:1 مربع)',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                _buildCategoryDropdowns(),
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
      child: _mainImage == null && _existingImageUrls.isEmpty
          ? _buildPlaceholder('اختر الصورة الأساسية')
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _mainImage != null
                  ? Image.memory(
                      _mainImage!.bytes,
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
      child: _otherImages.isEmpty && (_existingImageUrls.length <= 1)
          ? _buildPlaceholder('اختر صورًا إضافية')
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _otherImages.isNotEmpty
                  ? _otherImages.length
                  : (_existingImageUrls.length > 1
                        ? _existingImageUrls.length - 1
                        : 0),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _otherImages.isNotEmpty
                      ? Image.memory(_otherImages[index].bytes, fit: BoxFit.contain)
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
    // ارتفاع متجاوب لحقل اختيار الصورة
    final imageHeight = ResponsiveHelper.productCardWidth * 0.9;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: imageHeight,
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

  Widget _buildCategoryDropdowns() {
    return Column(
      children: [
        // Main Category Dropdown
        DropdownButtonFormField<String>(
          value: _selectedMainCategoryId,
          isExpanded: true,
          hint: const Text('اختر الصنف الرئيسي', style: TextStyle(color: Colors.black54)),
          decoration: _glassInputDecoration('الصنف الرئيسي'),
          dropdownColor: Colors.pink[100]?.withOpacity(0.9),
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
          items: _mainCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMainCategoryId = value;
              _selectedSubCategoryId = null; // Reset sub-category
              _subCategories = _categories.where((c) => c.parentId == value).toList();
            });
          },
          validator: (value) => value == null ? 'الرجاء اختيار صنف رئيسي' : null,
        ),

        if (_subCategories.isNotEmpty)
          const SizedBox(height: 16),

        // Sub-Category Dropdown
        if (_subCategories.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedSubCategoryId,
            isExpanded: true,
            hint: const Text('اختر الصنف الفرعي', style: TextStyle(color: Colors.black54)),
            decoration: _glassInputDecoration('الصنف الفرعي (اختياري)'),
            dropdownColor: Colors.pink[100]?.withOpacity(0.9),
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
            items: _subCategories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedSubCategoryId = value),
            // This field is optional if a main category is already selected
            validator: (value) {
              if (_selectedMainCategoryId != null && _subCategories.isNotEmpty && value == null) {
                return 'الرجاء اختيار صنف فرعي';
              }
              return null;
            },
          ),
      ],
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
