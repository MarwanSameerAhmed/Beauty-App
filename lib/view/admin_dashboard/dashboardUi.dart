import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/view/admin_view/manage_ads_screen.dart';
import 'package:test_pro/view/admin_view/manage_categories_screen.dart';
import 'package:test_pro/view/admin_view/manage_companies_screen.dart';
import 'package:test_pro/view/admin_view/manage_products_screen.dart';
import 'package:test_pro/view/admin_view/manage_carousel_ads_screen.dart';
import 'package:test_pro/widgets/backgroundUi.dart';

class DashboardUi extends StatelessWidget {
  const DashboardUi({super.key});

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
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.business_outline,
                          title: 'إدارة الشركات',
                          subtitle: 'إضافة، تعديل، وحذف الشركات',
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
                          title: 'إدارة الإعلانات',
                          subtitle: 'إنشاء وتعديل الإعلانات',
                          delay: const Duration(milliseconds: 500),
                          cardType: 'ad',
                        ),
                        const SizedBox(height: 20),
                        _buildModernDashboardCard(
                          context,
                          icon: Ionicons.images_outline,
                          title: 'إدارة إعلانات الكاروسيل',
                          subtitle: 'تغيير صور الكاروسيل في الرئيسية',
                          delay: const Duration(milliseconds: 600),
                          cardType: 'carousel_ad',
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهلاً بعودتك،',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  color: Colors.black54,
                ),
              ),
              Text(
                'لوحة التحكم',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF9D5D3).withOpacity(0.6),
            child: const Icon(
              Ionicons.person_outline,
              size: 30,
              color: Colors.black87,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9D5D3).withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 30, color: Colors.black87),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCardButton(
                  Icons.add_circle_outline,
                  'إدارة',
                  () => _navigateTo(context, cardType),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardButton(IconData icon, String label, VoidCallback onPressed) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Icon(icon, size: 20),
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }
}
