import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/view/admin_dashboard/dashboardUi.dart';
import 'package:test_pro/view/admin_view/customer_orders_page.dart';
import 'package:test_pro/view/profileUi.dart';

class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({Key? key}) : super(key: key);

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav>
    with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;

  @override
  void initState() {
    currentPage = 0;
    tabController = TabController(length: 3, vsync: this);
    tabController.animation!.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        changePage(value);
      }
    });
    super.initState();
  }

  void changePage(int newPage) {
    setState(() {
      currentPage = newPage;
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            TabBarView(
              controller: tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: const [
                DashboardUi(),
                CustomerOrdersPage(),
                ProfileUi(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFF9D5D3).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      tabs: [
                        TabsIcon(
                          icons: currentPage == 0
                              ? Icons.home
                              : Icons.home_outlined,
                          color: currentPage == 0 ? Colors.brown : Colors.grey,
                        ),
                        TabsIcon(
                          icons: currentPage == 1
                              ? Icons.receipt_long
                              : Icons.receipt_long_outlined,
                          color: currentPage == 1 ? Colors.brown : Colors.grey,
                        ),
                        TabsIcon(
                          icons: currentPage == 2
                              ? Icons.person
                              : Icons.person_outline,
                          color: currentPage == 2 ? Colors.brown : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabsIcon extends StatelessWidget {
  final Color color;
  final IconData icons;

  const TabsIcon({Key? key, this.color = Colors.grey, required this.icons})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(icons, color: color);
  }
}
