import 'package:flutter/material.dart';
import 'package:test_pro/controller/Auth_Service.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final AuthService _authService = AuthService();
  late Future<UserAccount?> _userAccountFuture;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _isGuest = currentUser?.isAnonymous ?? true;
    if (!_isGuest) {
      _userAccountFuture = _authService.getCurrentUserAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const CustomAdminHeader(
                title: 'إعدادات الحساب',
                subtitle: 'عرض معلومات حسابك الشخصي.',
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9D5D3).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.2,
                          ),
                        ),
                        child: _isGuest
                            ? _buildGuestView()
                            : FutureBuilder<UserAccount?>(
                                future: _userAccountFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(child: Loader());
                                  }
                                  if (snapshot.hasError ||
                                      !snapshot.hasData ||
                                      snapshot.data == null) {
                                    return const Center(
                                      child: Text('حدث خطأ في تحميل البيانات.'),
                                    );
                                  }

                                  final user = snapshot.data!;

                                  return ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(16.0),
                                    children: [
                                      _buildInfoTile(
                                        Icons.person,
                                        'الاسم',
                                        user.name,
                                      ),
                                      _buildInfoTile(
                                        Icons.email,
                                        'البريد الإلكتروني',
                                        user.email,
                                      ),
                                      _buildInfoTile(
                                        Icons.account_box,
                                        'نوع الحساب',
                                        user.accountType,
                                      ),
                                      if (user.accountType == 'company') ...[
                                        _buildInfoTile(
                                          Icons.business,
                                          'اسم الشركة',
                                          user.companyName ?? 'غير متوفر',
                                        ),
                                        _buildInfoTile(
                                          Icons.confirmation_number,
                                          'الرقم الضريبي',
                                          user.taxNumber ?? 'غير متوفر',
                                        ),
                                      ],
                                    ],
                                  );
                                },
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
    );
  }

  Widget _buildGuestView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.black54),
          const SizedBox(height: 20),
          const Text(
            'ميزة حصرية للمستخدمين المسجلين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'يرجى تسجيل الدخول أو إنشاء حساب جديد للوصول إلى إعدادات حسابك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 30),
          GradientElevatedButton(
            text: 'الانتقال لتسجيل الدخول',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginUi()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: ListTile(
              leading: Icon(icon, color: const Color(0xFF52002C)),
              title: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
