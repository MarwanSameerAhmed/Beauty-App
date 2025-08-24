import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/view/customer_order_details_page.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_Header_user.dart';
import 'package:test_pro/widgets/loader.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('uid');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              CustomHeaderUser(
                title: 'طلباتي',
                subtitle: 'تتبّع حالة طلباتك السابقة والحالية',
              ),
              Expanded(
                child: _userId == null
                    ? const Center(
                        child: Loader(),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('customer_orders')
                            .where('userId', isEqualTo: _userId)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Loader(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Text(
                                'ليس لديك طلبات حاليًا.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Tajawal',
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }

                          final orders = snapshot.data!.docs;

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              bottom: 80,
                            ), // To avoid overlap with bottom nav bar
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final items = order['items'] as List;
                              final firstItem = items.first;
                              final status = order['status'];
                              final orderDate =
                                  (order['timestamp'] as Timestamp).toDate();
                              final formattedDate =
                                  '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CustomerOrderDetailsPage(
                                            order: order,
                                          ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(25.0),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5.0,
                                      sigmaY: 5.0,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 10,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFF9D5D3,
                                        ).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(
                                          25.0,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15.0,
                                            ),
                                            child: Image.network(
                                              firstItem['imageUrl'],
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'طلب بتاريخ: $formattedDate',
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      status,
                                                    ).withOpacity(0.8),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(status),
                                                    style: const TextStyle(
                                                      fontFamily: 'Tajawal',
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _getStatusText(String status) {
  switch (status) {
    case 'pending_pricing':
      return 'بانتظار التسعير';
    case 'priced':
      return 'بانتظار موافقتك';
    case 'awaiting_customer_approval':
      return 'بانتظار موافقتك';
    case 'awaiting_admin_approval':
      return 'قيد مراجعة المسؤول';
    case 'final_approved':
      return 'تمت الموافقة النهائية';
    case 'completed':
      return 'مكتمل';
    default:
      return 'غير معروف';
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'pending_pricing':
      return Colors.orange.shade700;
    case 'priced':
      return Colors.blue.shade700;
    case 'awaiting_customer_approval':
      return Colors.teal.shade700;
    case 'awaiting_admin_approval':
      return Colors.purple.shade700;
    case 'final_approved':
      return Colors.green.shade700;
    case 'completed':
      return Colors.grey.shade600;
    default:
      return Colors.black;
  }
}
