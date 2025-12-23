import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glamify/view/admin_view/manage_ads_screen.dart';
import 'package:glamify/view/auth_Ui/login_ui.dart';
import 'package:glamify/view/profile_Ui/account_settings_page.dart';
import 'package:glamify/view/profile_Ui/help_and_support_page.dart';
import 'package:glamify/view/legal/privacy_policy_page.dart' as LegalPrivacy;
import 'package:glamify/view/legal/terms_of_service_page.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/ElegantToast.dart';
import 'package:glamify/controller/Auth_Service.dart';
import 'package:glamify/widgets/loader.dart';
import 'dart:ui';

class ProfileUi extends StatefulWidget {
  const ProfileUi({super.key});

  @override
  State<ProfileUi> createState() => _ProfileUiState();
}

class _ProfileUiState extends State<ProfileUi> with TickerProviderStateMixin {
  String _userName = 'زائر';
  String _email = 'guest@example.com';

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for subtle spinning
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Scale animation for entrance effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'زائر';
      _email = prefs.getString('email') ?? 'guest@example.com';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userName');
    await prefs.remove('email');
    await prefs.remove('role');
    await prefs.remove('uid');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginUi()),
        (route) => false,
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.white.withOpacity(0.95),
                          const Color(0xFFF9D5D3).withOpacity(0.9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Warning Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade50,
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red.shade600,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'حذف الحساب نهائياً',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52002C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Warning message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade100,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '⚠️ تحذير هام',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سيتم حذف حسابك وجميع بياناتك بشكل نهائي ولا يمكن استعادتها. هذا يشمل:',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• معلومات حسابك\n• سجل طلباتك\n• السلة المحفوظة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  color: Colors.red.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFF52002C)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Color(0xFF52002C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteAccount();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'حذف الحساب',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Loader(),
    );

    try {
      final authService = AuthService();
      final result = await authService.deleteAccount();

      // Hide loading
      if (mounted) Navigator.of(context).pop();

      if (result == null) {
        // Success - clear local data and navigate to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          showElegantToast(
            context,
            'تم حذف حسابك بنجاح',
            isSuccess: true,
          );
          
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginUi()),
            (route) => false,
          );
        }
      } else {
        // Error
        if (mounted) {
          showElegantToast(
            context,
            result,
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      // Hide loading
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        showElegantToast(
          context,
          'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 60),
              _buildProfileHeader(),
              const SizedBox(height: 10),
              _buildProfileMenu(context),
              // Add padding for the translucent bottom navigation bar
              // const SizedBox(height: 90.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFancyCircleAvatar() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _rotationController,
        _scaleController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _pulseAnimation.value.clamp(0.95, 1.05),
            child: GestureDetector(
              onTap: () {
                _scaleController.reset();
                _scaleController.forward();
              },
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.05, // Subtle rotation
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFf9d5d3).withOpacity(0.9),
                        Color(0xFF942A59).withOpacity(0.5),
                        Color(0xFF52002C).withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF52002C).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 15,
                        offset: const Offset(-4, -4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.85),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.1),
                                Color(0xFFf9d5d3).withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'ز',
                                style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF52002C),
                                  fontFamily: 'Tajawal',
                                  shadows: [
                                    Shadow(
                                      color: Colors.white,
                                      blurRadius: 15,
                                      offset: Offset(0, 3),
                                    ),
                                    Shadow(
                                      color: Color(0xFF942A59).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(2, 2),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Column(
          children: [
            _buildFancyCircleAvatar(),
            const SizedBox(height: 20),

            // Animated Name Container
            Transform.translate(
              offset: Offset(0, 20 * (1 - _scaleAnimation.value)),
              child: Opacity(
                opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.1),
                        Color(0xFFf9d5d3).withOpacity(0.3),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF52002C).withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(-3, -3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF52002C),
                          fontFamily: 'Tajawal',
                          shadows: [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: Color(0xFF942A59),
                              blurRadius: 12,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _scaleAnimation.value)),
          child: Opacity(
            opacity: (_scaleAnimation.value * 0.95 + 0.05).clamp(0.0, 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.5),
                        Color(0xFFf9d5d3).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF52002C).withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Admin role check based on email domain
                      if (_email.endsWith('@admin.com'))
                        Column(
                          children: [
                            _buildAnimatedMenuTile(
                              Icons.dashboard_customize,
                              'إدارة الإعلانات',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ManageAdsScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildAnimatedDivider(),
                          ],
                        ),
                      _buildAnimatedMenuTile(
                        Icons.settings,
                        'إعدادات الحساب',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsPage(),
                          ),
                        ),
                      ),
                      _buildAnimatedMenuTile(
                        Icons.notifications,
                        'الإشعارات',
                        onTap: () => showElegantToast(
                          context,
                          'هذه الخدمة قيد التطوير حاليًا',
                          isSuccess: false,
                        ),
                      ),
                      _buildAnimatedMenuTile(
                        Icons.lock,
                        'سياسة الخصوصية',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LegalPrivacy.PrivacyPolicyPage(),
                          ),
                        ),
                      ),
                      _buildAnimatedMenuTile(
                        Icons.description,
                        'شروط الخدمة',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServicePage(),
                          ),
                        ),
                      ),
                      _buildAnimatedMenuTile(
                        Icons.help_outline,
                        'المساعدة والدعم',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpAndSupportPage(),
                          ),
                        ),
                      ),
                      _buildAnimatedDivider(),
                      _buildAnimatedMenuTile(
                        Icons.logout,
                        'تسجيل الخروج',
                        onTap: _logout,
                        color: Colors.orange,
                      ),
                      _buildAnimatedMenuTile(
                        Icons.delete_forever,
                        'حذف الحساب',
                        onTap: _showDeleteAccountDialog,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMenuTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 0.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Color(0xFF52002C).withOpacity(0.1),
                  highlightColor: Color(0xFFf9d5d3).withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                (color ?? const Color(0xFF52002C)).withOpacity(
                                  0.15,
                                ),
                                (color ?? const Color(0xFFf9d5d3)).withOpacity(
                                  0.2,
                                ),
                              ],
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: color ?? const Color(0xFF52002C),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: color ?? const Color(0xFF52002C),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: (color ?? const Color(0xFF52002C)).withOpacity(
                            0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedDivider() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Opacity(
            opacity: value,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF52002C).withOpacity(0.3 * value),
                    Color(0xFF942A59).withOpacity(0.2 * value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
