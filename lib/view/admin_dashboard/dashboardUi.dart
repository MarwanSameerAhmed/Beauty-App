import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/controller/Auth_Service.dart';
import 'package:test_pro/model/userAccount.dart';
import 'package:test_pro/view/admin_view/create_invoice_page.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
import 'package:test_pro/view/admin_view/manage_ads_screen.dart';
import 'package:test_pro/view/admin_view/manage_categories_screen.dart';
import 'package:test_pro/view/admin_view/manage_companies_screen.dart';
import 'package:test_pro/view/admin_view/manage_products_screen.dart';
import 'package:test_pro/view/admin_view/manage_carousel_ads_screen.dart';
import 'package:test_pro/view/admin_view/company_settings_page.dart';
import 'package:test_pro/view/admin_view/ads_layout_manager.dart';
import 'package:test_pro/view/admin_view/ads_sections_manager.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';

class DashboardUi extends StatefulWidget {
  const DashboardUi({super.key});

  @override
  State<DashboardUi> createState() => _DashboardUiState();
}

class _DashboardUiState extends State<DashboardUi> {
  UserAccount? _adminAccount;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (mounted) {
        setState(() {
          _adminAccount = UserAccount.fromJson(
            adminDoc.data() as Map<String, dynamic>,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.business_outline,
                          title: 'الماركات',
                          subtitle: 'إضافة، تعديل، وحذف الماركات',
                          delay: const Duration(milliseconds: 200),
                          cardType: 'company',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.grid_outline,
                          title: 'إدارة الأصناف',
                          subtitle: 'إضافة، تعديل، وحذف الأصناف',
                          delay: const Duration(milliseconds: 300),
                          cardType: 'category',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.cube_outline,
                          title: 'إدارة المنتجات',
                          subtitle: 'إضافة، تعديل، وحذف المنتجات',
                          delay: const Duration(milliseconds: 400),
                          cardType: 'product',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.megaphone_outline,
                          title: 'البانر المتحرك',
                          subtitle: 'إنشاء وتعديل الإعلانات',
                          delay: const Duration(milliseconds: 500),
                          cardType: 'ad',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.images_outline,
                          title: 'البانر المتحرك',
                          subtitle: 'تغيير صور الكاروسيل في الرئيسية',
                          delay: const Duration(milliseconds: 600),
                          cardType: 'carousel_ad',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.receipt_outline,
                          title: 'إنشاء فاتورة',
                          subtitle: 'اختيار منتجات وتسعيرها وإرسال فاتورة',
                          delay: const Duration(milliseconds: 700),
                          cardType: 'invoice',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.grid_outline,
                          title: 'إدارة مواضع الإعلانات',
                          subtitle: 'تحكم في ترتيب وإخفاء الإعلانات والبانرات',
                          delay: const Duration(milliseconds: 750),
                          cardType: 'ads_layout',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.bookmark_outline,
                          title: 'إدارة أقسام الإعلانات',
                          subtitle: 'تخصيص أسماء الأقسام وترتيبها في الصفحة الرئيسية',
                          delay: const Duration(milliseconds: 775),
                          cardType: 'ads_sections',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.settings_outline,
                          title: 'إعدادات الشركة',
                          subtitle: 'تحديث رقم الهاتف ومعلومات الشركة',
                          delay: const Duration(milliseconds: 800),
                          cardType: 'settings',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بعودتك',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  _adminAccount?.name ?? 'مسؤول',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF9D5D3).withOpacity(0.6),
              child: const Icon(
                Ionicons.log_out_outline,
                size: 30,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String cardType) {
    Widget page;
    switch (cardType) {
      case 'company':
        page = const ManageCompaniesScreen();
        break;
      case 'category':
        page = const ManageCategoriesScreen();
        break;
      case 'product':
        page = const ManageProductsScreen();
        break;
      case 'ad':
        page = ManageAdsScreen();
        break;
      case 'carousel_ad':
        page = ManageCarouselAdsScreen();
        break;
      case 'invoice':
        page = const CreateInvoicePage();
        break;
      case 'ads_layout':
        page = const AdsLayoutManager();
        break;
      case 'ads_sections':
        page = const AdsSectionsManager();
        break;
      case 'settings':
        page = const CompanySettingsPage();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildModernDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Duration delay,
    required String cardType,
  }) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      delay: delay,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D5D3).withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 26, color: Colors.black87),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black54,
          ),
          onTap: () => _navigateTo(context, cardType),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showElegantDialog(
      context: context,
      child: ConfirmActionDialog(
        message: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
        onConfirm: () async {
          await _authService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginUi()),
              (Route<dynamic> route) => false,
            );
          }
        },
      ),
    );
  }
}
