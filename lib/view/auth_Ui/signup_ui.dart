import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/Auth_Service.dart';
import 'package:glamify/model/userAccount.dart';
import 'package:glamify/view/bottomNavUi.dart';
import 'package:glamify/view/legal/privacy_policy_page.dart';
import 'package:glamify/view/legal/terms_of_service_page.dart';
import 'package:glamify/widgets/FormFields.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/buttonsWidgets.dart';
import 'package:glamify/widgets/ElegantToast.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class SignupUi extends StatefulWidget {
  const SignupUi({super.key});

  @override
  State<SignupUi> createState() => _SignupUiState();
}

class _SignupUiState extends State<SignupUi> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final companyNameController = TextEditingController();
  final taxNumberController = TextEditingController();

  String? _accountType = 'فرد';
  bool _isLoading = false;
  final List<String> accountTypes = ['فرد', 'شركة'];

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40.0,
                    ),
                    child: _buildAnimatedContainer(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'حساب جديد',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              const SizedBox(height: 40),
                              GlassField(
                                controller: nameController,
                                hintText: 'الاسم الكامل',
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'يرجى إدخال الاسم';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              GlassField(
                                controller: emailController,
                                hintText: 'البريد الإلكتروني',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'يرجى إدخال البريد الإلكتروني';
                                  if (!value.contains('@'))
                                    return 'البريد الإلكتروني غير صالح';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              GlassField(
                                controller: passwordController,
                                hintText: 'كلمة المرور',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'يرجى إدخال كلمة المرور';
                                  if (value.length < 6)
                                    return 'كلمة المرور قصيرة جدًا';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              GlassField(
                                controller: confirmPasswordController,
                                hintText: 'تأكيد كلمة المرور',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'يرجى تأكيد كلمة المرور';
                                  if (value != passwordController.text)
                                    return 'كلمة المرور غير متطابقة';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildAccountTypeDropdown(),
                              const SizedBox(height: 20),
                              _buildCompanyFields(),
                              const SizedBox(height: 30),
                              GradientElevatedButton(
                                text: 'إنشاء حساب',
                                isLoading: _isLoading,
                                onPressed: _onRegisterPressed,
                              ),
                              const SizedBox(height: 20),
                              _buildLegalLinks(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer({required Widget child}) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9D5D3).withOpacity(0.6),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildAccountTypeDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          'نوع الحساب',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
            fontFamily: 'Tajawal',
          ),
        ),
        items: accountTypes
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal'),
                ),
              ),
            )
            .toList(),
        value: _accountType,
        onChanged: (value) {
          setState(() {
            _accountType = value;
          });
        },
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color(0xFFF9D5D3),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyFields() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _accountType == 'شركة'
          ? Column(
              key: const ValueKey('company-fields'),
              children: [
                GlassField(
                  controller: companyNameController,
                  hintText: 'اسم الشركة',
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (_accountType == 'شركة' &&
                        (value == null || value.isEmpty)) {
                      return 'يرجى إدخال اسم الشركة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GlassField(
                  controller: taxNumberController,
                  hintText: 'الرقم الضريبي',
                  prefixIcon: Icons.receipt_long,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_accountType == 'شركة' &&
                        (value == null || value.isEmpty)) {
                      return 'يرجى إدخال الرقم الضريبي';
                    }
                    return null;
                  },
                ),
              ],
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildLegalLinks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'بإنشاء حساب، فإنك توافق على:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  );
                },
                child: Text(
                  'سياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF52002C),
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' و ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Tajawal',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage(),
                    ),
                  );
                },
                child: Text(
                  'شروط الخدمة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF52002C),
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onRegisterPressed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newUser = UserAccount(
        uid: '', // Firestore will generate this
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
        accountType: _accountType!,
        companyName: _accountType == 'شركة' ? companyNameController.text : null,
        taxNumber: _accountType == 'شركة' ? taxNumberController.text : null,
      );

      AuthService auth = AuthService();
      String? result = await auth.registerUser(newUser);

      if (mounted) {
        if (result == null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('uid', newUser.uid);
          await prefs.setString('userName', newUser.name);
          await prefs.setString('email', newUser.email);
          await prefs.setBool('isLoggedIn', true);

          showElegantToast(context, 'تم التسجيل بنجاح!', isSuccess: true);

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Run()),
            (route) => false, // Removes all previous routes
          );
        } else {
          showElegantToast(context, 'حدث خطأ: $result', isSuccess: false);
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
