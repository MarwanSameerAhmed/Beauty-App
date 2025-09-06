import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/view/admin_view/manage_ads_screen.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
import 'package:test_pro/view/profile_Ui/account_settings_page.dart';
import 'package:test_pro/view/profile_Ui/help_and_support_page.dart';
import 'package:test_pro/view/profile_Ui/privacy_policy_page.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/ElegantToast.dart';
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

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,

          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 20),
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
            scale: _pulseAnimation.value.clamp(0.8, 1.2),
            child: GestureDetector(
              onTap: () {
                _scaleController.reset();
                _scaleController.forward();
              },
              child: Transform.rotate(
                angle: _rotationAnimation.value * 0.1, // Subtle rotation
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF52002C),
                        Color(0xFF942A59),
                        Color(0xFFf9d5d3),
                        Colors.white.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF52002C).withOpacity(
                          (0.4 * _pulseAnimation.value).clamp(0.0, 1.0),
                        ),
                        blurRadius: (25 * _pulseAnimation.value).clamp(
                          10.0,
                          35.0,
                        ),
                        offset: const Offset(0, 12),
                        spreadRadius: (3 * _pulseAnimation.value).clamp(
                          1.0,
                          5.0,
                        ),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        blurRadius: 20,
                        offset: const Offset(-8, -8),
                      ),
                      BoxShadow(
                        color: Color(0xFF942A59).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.7),
                          Colors.white.withOpacity(0.4),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
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
          offset: Offset(0, 30 * (1 - _scaleAnimation.value)),
          child: Opacity(
            opacity: (_scaleAnimation.value * 0.9 + 0.1).clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                    Color(0xFFf9d5d3).withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF52002C).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 15,
                    offset: const Offset(-5, -5),
                  ),
                  BoxShadow(
                    color: Color(0xFF942A59).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Column(
                    children: [
                      // TODO: Replace with a proper role-based check from user data
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
                        'الخصوصية والأمان',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
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
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            (color ?? const Color(0xFF52002C)).withOpacity(0.2),
                            (color ?? const Color(0xFF52002C)).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: color ?? const Color(0xFF52002C),
                        size: 22,
                      ),
                    ),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: color ?? const Color(0xFF52002C),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: color ?? const Color(0xFF52002C),
                      ),
                    ),
                    onTap: onTap,
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
