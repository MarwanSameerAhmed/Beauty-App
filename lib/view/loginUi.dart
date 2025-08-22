import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/controller/Auth_Service.dart';
import 'package:test_pro/view/bottomNavUi.dart';
import 'package:test_pro/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:test_pro/view/otpUi.dart';
import 'package:test_pro/widgets/ElegantToast.dart';
import 'package:test_pro/view/signupUi.dart';
import 'package:test_pro/widgets/FormFields.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

class LoginUi extends StatefulWidget {
  const LoginUi({super.key});

  @override
  State<LoginUi> createState() => _LoginUiState();
}

class _LoginUiState extends State<LoginUi> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isPhoneAuth = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: _buildAnimatedContainer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedHeader(),
                    const SizedBox(height: 40.0),
                    _buildAnimatedFormField(
                      delay: const Duration(milliseconds: 400),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            child: child,
                          ),
                        ),
                        child: _isPhoneAuth
                            ? _buildPhoneForm(key: const ValueKey('phone'))
                            : _buildEmailPasswordFields(
                                key: const ValueKey('email'),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    _buildAnimatedSocialLogin(),
                    const SizedBox(height: 20.0),
                    _buildAnimatedSignUp(),
                    const SizedBox(height: 10.0),
                    _buildAnimatedSkipButton(),
                  ],
                ),
              ),
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
    );
  }

  Widget _buildAnimatedHeader() {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: const Text(
        'أهلاً بعودتك',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }

  Widget _buildAnimatedFormField({
    required Duration delay,
    required Widget child,
  }) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      delay: delay,
      duration: const Duration(milliseconds: 500),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildEmailPasswordFields({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildAnimatedEmailPasswordFields(),
        const SizedBox(height: 12.0),
        _buildAnimatedForgotPassword(),
        const SizedBox(height: 20.0),
        _buildAnimatedLoginButton(),
      ],
    );
  }

  Widget _buildAnimatedEmailPasswordFields() {
    return _buildAnimatedFormField(
      delay: Duration.zero,
      child: Form(
        key: _formKey,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              GlassField(
                controller: emailController,
                hintText: 'البريد الإلكتروني',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@gmail')) {
                    return 'البريد الإلكتروني غير صالح';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm({Key? key}) {
    return Column(
      key: key,
      children: [
        GlassField(
          controller: phoneController,
          hintText: 'رقم الهاتف',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 32.0),
        _buildAnimatedLoginButton(),
      ],
    );
  }

  Widget _buildAnimatedForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: const Text(
          'هل نسيت كلمة المرور؟',
          style: TextStyle(color: Colors.black54, fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoginButton() {
    return GradientElevatedButton(
      text: _isPhoneAuth ? 'إرسال الرمز' : 'تسجيل الدخول',
      isLoading: _isLoading,
      onPressed: () async {
        if (_isPhoneAuth) {
          // Phone auth logic remains the same, no loading indicator needed for now
          if (phoneController.text.isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  verificationId: 'test_id',
                  phoneNumber: phoneController.text,
                ),
              ),
            );
          }
        } else {
          // Email auth logic
          if (_formKey.currentState!.validate()) {
            setState(() {
              _isLoading = true;
            });

            final authService = AuthService();
            final result = await authService.login(
              emailController.text.trim(),
              passwordController.text.trim(),
            );

            if (mounted) {
              if (result is UserAccount) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', result.uid);
                await prefs.setString('userName', result.name);
                await prefs.setString('email', result.email);
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('role', result.role); // Save user role

                showElegantToast(
                  context,
                  "تم تسجيل الدخول بنجاح!",
                  isSuccess: true,
                );

                // Redirect based on user role
                if (result.role.toLowerCase() == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminBottomNav(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Run()),
                  );
                }
              } else if (result is String) {
                showElegantToast(context, result, isSuccess: false);
                setState(() {
                  _isLoading = false;
                });
              }
            }
          }
        }
      },
    );
  }

  Widget _buildAnimatedSocialLogin() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _isPhoneAuth = !_isPhoneAuth;
              });
            },
            child: Text(
              _isPhoneAuth ? 'أو سجل بالبريد الإلكتروني' : 'أو سجل برقم الهاتف',
              style: const TextStyle(
                color: Color(0xFFC15C5C),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          if (!_isPhoneAuth)
            const Text(
              'أو سجل الدخول باستخدام',
              style: TextStyle(color: Colors.black54, fontFamily: 'Tajawal'),
            ),
          if (!_isPhoneAuth) const SizedBox(height: 16.0),
          if (!_isPhoneAuth)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(FontAwesome.google, () {}),
                const SizedBox(width: 20),
                _buildSocialButton(FontAwesome.apple, () {}),
                const SizedBox(width: 20),
                _buildSocialButton(FontAwesome.facebook, () {}),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.4),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }

  Widget _buildAnimatedSignUp() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'لا تملك حساب؟',
            style: TextStyle(color: Colors.black54, fontFamily: 'Tajawal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => const SignupUi()));
            },
            child: const Text(
              'إنشاء حساب',
              style: TextStyle(
                color: Color(0xFFC15C5C),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSkipButton() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 900),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Run()),
          );
        },
        child: const Text(
          'الدخول كازائر',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
