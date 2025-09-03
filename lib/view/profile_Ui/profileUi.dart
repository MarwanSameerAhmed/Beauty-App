import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/view/admin_view/manage_ads_screen.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
import 'package:test_pro/view/profile_Ui/account_settings_page.dart';
import 'package:test_pro/view/profile_Ui/help_and_support_page.dart';
import 'package:test_pro/view/profile_Ui/privacy_policy_page.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/ElegantToast.dart';

class ProfileUi extends StatefulWidget {
  const ProfileUi({super.key});

  @override
  State<ProfileUi> createState() => _ProfileUiState();
}

class _ProfileUiState extends State<ProfileUi> {
  String _userName = 'زائر';
  String _email = 'guest@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
              const SizedBox(height: 40),
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildProfileMenu(context),
              // Add padding for the translucent bottom navigation bar
              // const SizedBox(height: 90.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              _userName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFF52002C),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 8),
        // Text(
        //   _email,
        //   style: const TextStyle(
        //     fontSize: 16,
        //     color: Colors.black54,
        //     fontFamily: 'Tajawal',
        //   ),
        // ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // TODO: Replace with a proper role-based check from user data
          if (_email.endsWith('@admin.com'))
            Column(
              children: [
                _buildMenuTile(
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
                const Divider(),
              ],
            ),
          _buildMenuTile(
            Icons.settings,
            'إعدادات الحساب',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsPage(),
              ),
            ),
          ),
          _buildMenuTile(
            Icons.notifications,
            'الإشعارات',
            onTap: () => showElegantToast(
              context,
              'هذه الخدمة قيد التطوير حاليًا',
              isSuccess: false,
            ),
          ),
          _buildMenuTile(
            Icons.lock,
            'الخصوصية والأمان',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyPage(),
              ),
            ),
          ),
          _buildMenuTile(
            Icons.help_outline,
            'المساعدة والدعم',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpAndSupportPage(),
              ),
            ),
          ),
          const Divider(),
          _buildMenuTile(
            Icons.logout,
            'تسجيل الخروج',
            onTap: _logout,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF52002C)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
