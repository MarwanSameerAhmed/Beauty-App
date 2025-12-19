import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glamify/view/admin_dashboard/dashboardUi.dart';
import 'package:glamify/view/admin_view/customer_orders_page.dart';
import 'package:glamify/view/profile_Ui/profileUi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glamify/controller/order_status_service.dart';

class AdminBottomNav extends StatefulWidget {
  const AdminBottomNav({Key? key}) : super(key: key);

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav>
    with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final OrderStatusService _orderStatusService = OrderStatusService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 3, vsync: this);
    tabController.animation!.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        changePage(value);
      }
    });
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
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
      bottom: false, // السماح بامتداد الباك قراوند للأسفل
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
                        StreamBuilder<int>(
                          stream: _userId == null
                              ? Stream.value(0)
                              : _orderStatusService
                                    .getOrderStatusNotificationStream(
                                      userId: _userId!,
                                      userRole: 'admin',
                                    ),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                TabsIcon(
                                  icons: currentPage == 1
                                      ? Icons.receipt_long
                                      : Icons.receipt_long_outlined,
                                  color: currentPage == 1
                                      ? Colors.brown
                                      : Colors.grey,
                                ),
                                if (count > 0)
                                  Container(
                                    padding: const EdgeInsets.all(0),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            );
                          },
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
