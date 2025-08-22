import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/view/categorysUi.dart';
import 'package:test_pro/view/homeScreenUi.dart';
import 'package:test_pro/view/cart_page.dart';
import 'package:test_pro/view/my_orders_page.dart';
import 'package:test_pro/view/profileUi.dart'; 

class Run extends StatefulWidget {
  const Run({Key? key}) : super(key: key);

  @override
  State<Run> createState() => _RunState();
}

class _RunState extends State<Run> with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;

  @override
  void initState() {
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
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
    final List<Widget> _pages = [
      const Homescreenui(),
      const Categorys(),
      const CartPage(),
      const MyOrdersPage(),
      const ProfileUi(),
    ];

    return SafeArea(
      child: Scaffold(
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
                      color: Color(0xFFF9D5D3).withOpacity(0.3),

                      borderRadius: BorderRadius.circular(30.0),
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
                              ? Icons.category
                              : Icons.category_outlined,
                          color: currentPage == 1 ? Colors.brown : Colors.grey,
                        ),
                        TabsIcon(
                          icons: currentPage == 2
                              ? Icons.shopping_cart
                              : Icons.shopping_cart_outlined,
                          color: currentPage == 2 ? Colors.brown : Colors.grey,
                        ),
                        TabsIcon(
                          icons: currentPage == 3
                              ? Icons.receipt_long
                              : Icons.receipt_long_outlined,
                          color: currentPage == 3 ? Colors.brown : Colors.grey,
                        ),
                        TabsIcon(
                          icons: currentPage == 4
                              ? Icons.person
                              : Icons.person_outlined,
                          color: currentPage == 4 ? Colors.brown : Colors.grey,
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
