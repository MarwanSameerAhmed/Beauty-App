import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/controller/Auth_Service.dart';
import 'package:test_pro/view/bottomNavUi.dart';
import 'package:test_pro/view/admin_dashboard/admin_bottom_nav_ui.dart';
import 'package:test_pro/widgets/ElegantToast.dart';
import 'package:test_pro/view/auth_Ui/signupUi.dart';
import 'package:test_pro/widgets/FormFields.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/view/auth_Ui/complete_profile_ui.dart';

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
  bool _isGuestLoading = false;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                final horizontalPadding = isSmallScreen ? 24.0 : 60.0;
                final verticalPadding = isSmallScreen ? 40.0 : 60.0;
                final containerMaxWidth = isSmallScreen
                    ? double.infinity
                    : 500.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: containerMaxWidth),
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
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(
                                        sizeFactor: animation,
                                        child: child,
                                      ),
                                    ),
                                child: _isPhoneAuth
                                    ? _buildPhoneForm(
                                        key: const ValueKey('phone'),
                                      )
                                    : _buildEmailPasswordFields(
                                        key: const ValueKey('email'),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            _buildAnimatedLoginButton(),
                            const SizedBox(height: 20.0),
                            _buildAnimatedSocialLogin(),
                            const SizedBox(height: 10.0),
                            _buildAnimatedSkipButton(),
                            const SizedBox(height: 10.0),
                            _buildAnimatedPhoneToggle(),
                            _buildAnimatedSignUp(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    return Column(key: key, children: [_buildAnimatedEmailPasswordFields()]);
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
              const SizedBox(height: 13),
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
      ],
    );
  }

  Widget _buildAnimatedLoginButton() {
    return GradientElevatedButton(
      text: _isPhoneAuth ? 'إرسال الرمز' : 'تسجيل الدخول',
      isLoading: _isLoading,
      onPressed: () async {
        if (_isPhoneAuth) {
          // Show a toast indicating the service is unavailable
          showElegantToast(
            context,
            "هذه الخدمة غير متوفرة حالياً",
            isSuccess: false,
          );
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
      delay: const Duration(milliseconds: 800),
      child: Column(
        children: [
          if (!_isPhoneAuth)
            Column(
              children: [
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'أو',
                        style: TextStyle(
                          color: Colors.black54,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20.0),
                _buildGoogleSignInButton(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return InkWell(
      onTap: _signInWithGoogle,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesome.google, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'سجل الدخول باستخدام ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSignUp() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.only(left: 13.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'لا تملك حساب؟',
              style: TextStyle(color: Colors.black54, fontFamily: 'Tajawal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SignupUi()),
                );
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
      ),
    );
  }

  Widget _buildAnimatedSkipButton() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 900),
      child: InkWell(
        onTap: _isGuestLoading
            ? null
            : () async {
                setState(() {
                  _isGuestLoading = true;
                });
                try {
                  final authService = AuthService();
                  final user = await authService.signInAnonymously();
                  if (mounted) {
                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Run()),
                      );
                    } else {
                      showElegantToast(
                        context,
                        'فشل الدخول كزائر',
                        isSuccess: false,
                      );
                    }
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isGuestLoading = false;
                    });
                  }
                }
              },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: _isGuestLoading
              ? const SizedBox(height: 24, width: 24, child: Loader())
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, color: Colors.black87, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'الدخول كزائر',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPhoneToggle() {
    return _buildAnimatedFormField(
      delay: const Duration(milliseconds: 1000),
      child: TextButton(
        onPressed: () {
          setState(() {
            _isPhoneAuth = !_isPhoneAuth;
          });
        },
        child: Text(
          _isPhoneAuth
              ? 'تسجيل الدخول بالبريد الإلكتروني'
              : 'تسجيل الدخول برقم الهاتف',
          style: const TextStyle(
            color: Color(0xFFC15C5C),
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final result = await authService.signInWithGoogle();

    if (!mounted) return;

    if (result is UserAccount) {
      // Existing user logic
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', result.uid);
      await prefs.setString('userName', result.name);
      await prefs.setString('email', result.email);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', result.role);

      showElegantToast(context, "تم تسجيل الدخول بنجاح!", isSuccess: true);

      if (result.role.toLowerCase() == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminBottomNav()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Run()),
        );
      }
    } else if (result is NewGoogleUser) {
      // New Google user, navigate to complete profile screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompleteProfileUi(user: result.user),
        ),
      );
    } else if (result is String) {
      showElegantToast(context, result, isSuccess: false);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
