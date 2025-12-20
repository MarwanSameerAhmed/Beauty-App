import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:glamify/view/categorysUi.dart';
import 'package:glamify/view/homeScreenUi.dart';
import 'package:glamify/view/cart_page.dart';
import 'package:glamify/view/my_orders_page.dart';
import 'package:glamify/view/profile_Ui/profileUi.dart';
import 'package:provider/provider.dart';
import 'package:glamify/controller/cart_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/controller/order_status_service.dart';

class Run extends StatefulWidget {
  const Run({Key? key}) : super(key: key);

  @override
  State<Run> createState() => _RunState();
}

class _RunState extends State<Run> with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final OrderStatusService _orderStatusService = OrderStatusService();
  String _userRole = 'user';
  String? _userId;

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(() {
      setState(() {
        currentPage = tabController.index;
      });
    });
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _userId = user.uid;
      FirebaseFirestore.instance.collection('users').doc(_userId).get().then((
        doc,
      ) {
        if (mounted && doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'user';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      Homescreenui(tabController: tabController),
      const Categorys(),
      const CartPage(),
      const MyOrdersPage(),
      const ProfileUi(),
    ];

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            TabBarView(
              controller: tabController,
              dragStartBehavior: DragStartBehavior.down,
              physics: const BouncingScrollPhysics(),
              children: _pages,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D5D3).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    child: Consumer<CartService>(
                      builder: (context, cart, child) {
                        return TabBar(
                          controller: tabController,
                          indicatorColor: Colors.transparent,
                          dividerColor: Colors.transparent,
                          tabs: [
                            TabsIcon(
                              icons: currentPage == 0
                                  ? Icons.home
                                  : Icons.home_outlined,
                              color: currentPage == 0
                                  ? Color(0xFF52002C)
                                  : Colors.grey,
                            ),
                            TabsIcon(
                              icons: currentPage == 1
                                  ? Icons.category
                                  : Icons.category_outlined,
                              color: currentPage == 1
                                  ? Color(0xFF52002C)
                                  : Colors.grey,
                            ),
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                TabsIcon(
                                  icons: currentPage == 2
                                      ? Icons.shopping_cart
                                      : Icons.shopping_cart_outlined,
                                  color: currentPage == 2
                                      ? Color(0xFF52002C)
                                      : Colors.grey,
                                ),
                                if (cart.items.isNotEmpty)
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
                                      '${cart.items.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                            StreamBuilder<int>(
                              stream: _userId == null
                                  ? Stream.value(0)
                                  : _orderStatusService
                                        .getOrderStatusNotificationStream(
                                          userId: _userId!,
                                          userRole: _userRole,
                                        ),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    TabsIcon(
                                      icons: currentPage == 3
                                          ? Icons.receipt_long
                                          : Icons.receipt_long_outlined,
                                      color: currentPage == 3
                                          ? Color(0xFF52002C)
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
                              icons: currentPage == 4
                                  ? Icons.person
                                  : Icons.person_outlined,
                              color: currentPage == 4
                                  ? Color(0xFF52002C)
                                  : Colors.grey,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
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
