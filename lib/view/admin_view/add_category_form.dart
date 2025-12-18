import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/category_service.dart';
import 'package:glamify/model/categorys.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:glamify/widgets/custom_admin_header.dart';

class AddCategoryForm extends StatefulWidget {
  final Category? category;

  const AddCategoryForm({super.key, this.category});

  @override
  State<AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends State<AddCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedParentId;
  List<Category> _parentCategories = [];
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedParentId = widget.category!.parentId;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService().getCategoriesFuture();
      if (mounted) {
        setState(() {
          _parentCategories = categories.where((c) => c.parentId == null).toList();
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في تحميل الأصناف: $e')),
        );
        setState(() {
          _isCategoriesLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final categoryData = Category(
        id: widget.category?.id ?? '',
        name: _nameController.text,
        parentId: _selectedParentId,
      );

      try {
        if (widget.category == null) {
          await CategoryService().addCategory(categoryData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت إضافة الصنف بنجاح')),
            );
          }
        } else {
          await CategoryService().updateCategory(categoryData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تعديل الصنف بنجاح')),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomAdminHeader(
                  title: widget.category == null ? 'إضافة صنف جديد' : 'تعديل الصنف',
                  subtitle: widget.category == null
                      ? 'إدارة الأصناف وإضافة صنف جديد'
                      : 'تعديل بيانات الصنف الحالي',
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: PlayAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10.0,
                              sigmaY: 10.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9D5D3).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GlassField(
                                      controller: _nameController,
                                      hintText: 'اسم الصنف',
                                      prefixIcon: Icons.category_outlined,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال اسم الصنف';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildParentCategoryDropdown(),
                                    const SizedBox(height: 30),
                                    GradientElevatedButton(
                                      text: widget.category == null ? 'حفظ الصنف' : 'تحديث الصنف',
                                      onPressed: _submitForm,
                                      isLoading: _isLoading,
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildParentCategoryDropdown() {
    if (_isCategoriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedParentId,
          isExpanded: true,
          hint: const Text('اختر الصنف الرئيسي (اختياري)', style: TextStyle(color: Colors.white70, fontFamily: 'Tajawal')),
          dropdownColor: const Color(0xFFF9D5D3),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: const TextStyle(color: Colors.black, fontFamily: 'Tajawal', fontSize: 16),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('بدون صنف رئيسي', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ..._parentCategories.map((Category category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name, style: const TextStyle(fontFamily: 'Tajawal')),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedParentId = newValue;
            });
          },
        ),
      ),
    );
  }
}
