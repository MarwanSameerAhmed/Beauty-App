import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/company_service.dart';
import 'package:glamify/model/company.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:glamify/widgets/custom_admin_header.dart';

class AddCompanyForm extends StatefulWidget {
  final Company? company;

  const AddCompanyForm({super.key, this.company});

  @override
  State<AddCompanyForm> createState() => _AddCompanyFormState();
}

class _AddCompanyFormState extends State<AddCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _logoUrlController;
  bool _isLoading = false;
  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _logoUrlController = TextEditingController(text: widget.company?.logoUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final companyData = Company(
        id: widget.company?.id ?? '',
        name: _nameController.text,
        logoUrl: _logoUrlController.text.isNotEmpty ? _logoUrlController.text : null,
      );

      try {
        if (_isEditing) {
          await CompanyService().updateCompany(companyData);
        } else {
          await CompanyService().addCompany(companyData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'تم تحديث الشركة بنجاح' : 'تمت إضافة الشركة بنجاح')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
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
                  title: _isEditing ? 'تعديل شركة' : 'إضافة شركة جديدة',
                  subtitle: _isEditing
                      ? 'تعديل بيانات الشركة الحالية'
                      : 'إدخال بيانات الشركة مثل الاسم والشعار',
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
                                      hintText: 'اسم الشركة',
                                      prefixIcon: Icons.business,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'الرجاء إدخال اسم الشركة';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    GlassField(
                                      controller: _logoUrlController,
                                      hintText: 'رابط شعار الشركة (اختياري)',
                                      prefixIcon: Icons.link,
                                    ),
                                    const SizedBox(height: 30),
                                    GradientElevatedButton(
                                      text: _isEditing ? 'حفظ التعديلات' : 'حفظ الشركة',
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
}
