import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glamify/controller/company_settings_service.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/ElegantToast.dart';

class CompanySettingsPage extends StatefulWidget {
  const CompanySettingsPage({super.key});

  @override
  State<CompanySettingsPage> createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  final CompanySettingsService _settingsService = CompanySettingsService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for all fields
  final _companyNameController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _supportEmailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _commercialRegisterController.dispose();
    _taxNumberController.dispose();
    _companyPhoneController.dispose();
    _whatsappController.dispose();
    _supportPhoneController.dispose();
    _supportEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await _settingsService.getCompanySettings();
      if (settings != null && mounted) {
        setState(() {
          _companyNameController.text = settings['companyName'] ?? '';
          _commercialRegisterController.text = settings['commercialRegister'] ?? '';
          _taxNumberController.text = settings['taxNumber'] ?? '';
          _companyPhoneController.text = settings['companyPhone'] ?? '';
          _whatsappController.text = settings['whatsappNumber'] ?? '';
          _supportPhoneController.text = settings['supportPhone'] ?? '';
          _supportEmailController.text = settings['supportEmail'] ?? '';
        });
      }
    } catch (e) {
      // Error loading settings
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _settingsService.updateCompanySettings(
        companyName: _companyNameController.text.trim(),
        commercialRegister: _commercialRegisterController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        phoneNumber: _companyPhoneController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
        supportEmail: _supportEmailController.text.trim(),
      );
      if (mounted) {
        showElegantToast(context, 'تم حفظ الإعدادات بنجاح!', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        showElegantToast(context, 'خطأ في حفظ الإعدادات', isSuccess: false);
      }
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: SafeArea(
            child: Column(
              children: [
                const CustomAdminHeader(
                  title: 'إعدادات الشركة',
                  subtitle: 'تعديل بيانات الفاتورة ومعلومات التواصل',
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF52002C)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // معلومات الشركة
                                _buildSectionCard(
                                  title: 'معلومات الشركة',
                                  icon: Icons.business,
                                  iconColor: const Color(0xFF52002C),
                                  children: [
                                    _buildTextField(
                                      controller: _companyNameController,
                                      label: 'اسم الشركة',
                                      hint: 'مثال: مؤسسة علي للتجارة',
                                      icon: Icons.store,
                                    ),
                                    _buildTextField(
                                      controller: _commercialRegisterController,
                                      label: 'السجل التجاري',
                                      hint: 'مثال: 4030649655',
                                      icon: Icons.description,
                                      keyboardType: TextInputType.number,
                                    ),
                                    _buildTextField(
                                      controller: _taxNumberController,
                                      label: 'الرقم الضريبي',
                                      hint: 'مثال: 310824900003',
                                      icon: Icons.receipt_long,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // أرقام التواصل
                                _buildSectionCard(
                                  title: 'أرقام التواصل',
                                  icon: Icons.phone,
                                  iconColor: const Color(0xFF52002C),
                                  children: [
                                    _buildTextField(
                                      controller: _companyPhoneController,
                                      label: 'رقم الجوال الرئيسي',
                                      hint: 'مثال: 0554055582',
                                      icon: Icons.phone_android,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    _buildTextField(
                                      controller: _whatsappController,
                                      label: 'رقم الواتس',
                                      hint: 'مثال: 966554055582',
                                      icon: Icons.chat,
                                      iconColor: const Color(0xFF25D366),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // معلومات الدعم
                                _buildSectionCard(
                                  title: 'معلومات الدعم والاستفسارات',
                                  icon: Icons.support_agent,
                                  iconColor: const Color(0xFF52002C),
                                  children: [
                                    _buildTextField(
                                      controller: _supportPhoneController,
                                      label: 'رقم الاستفسارات',
                                      hint: 'مثال: 0554055582',
                                      icon: Icons.headset_mic,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    _buildTextField(
                                      controller: _supportEmailController,
                                      label: 'البريد الإلكتروني للدعم',
                                      hint: 'مثال: support@company.com',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 30),
                                
                                // زر الحفظ
                                _buildSaveButton(),
                                
                                const SizedBox(height: 20),
                              ],
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9D5D3).withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Color iconColor = const Color(0xFF52002C),
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: keyboardType == TextInputType.phone || 
                       keyboardType == TextInputType.number ||
                       keyboardType == TextInputType.emailAddress
            ? TextDirection.ltr
            : TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF52002C), width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.black54),
          hintStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF52002C), Color(0xFF942A59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF52002C).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving ? null : _saveSettings,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'حفظ التغييرات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
