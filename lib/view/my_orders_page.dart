import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
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

    @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: FlowerBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                const CustomHeaderUser(
                  title: 'طلباتي',
                  subtitle: 'يجب عليك تسجيل الدخول لعرض طلباتك',
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'يرجى تسجيل الدخول لعرض هذه الصفحة.',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Tajawal',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginUi()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF52002C),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          ),
                          child: const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const CustomHeaderUser(
                title: 'طلباتي',
                subtitle: 'تتبّع حالة طلباتك السابقة والحالية',
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('customer_orders')
                            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Loader(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
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

                          if (orders.isEmpty) {
                            return const Center(
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

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              bottom: 80,
                            ), // To avoid overlap with bottom nav bar
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final orderData = order.data() as Map<String, dynamic>;
                              final status = orderData['status'];
                              final orderDate = (orderData['timestamp'] as Timestamp).toDate();
                              final bool isCancelled = status == 'cancelled';
                              final items = orderData['items'] as List? ?? [];

                              final String titleText = isCancelled ? 'طلب ملغي' : items.isNotEmpty ? items[0]['name'] : 'طلب فارغ';
                              final String? imageUrl = isCancelled || items.isEmpty ? null : items[0]['imageUrl'];

                              final formattedDate =
                                  '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';

                              return GestureDetector(
                                onTap: () {
                                  if (isCancelled) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('هذا الطلب ملغي ولا يمكن عرض تفاصيله.', style: TextStyle(fontFamily: 'Tajawal')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CustomerOrderDetailsPage(
                                              order: order,
                                            ),
                                      ),
                                    );
                                  }
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
                                            borderRadius: BorderRadius.circular(15.0),
                                            child: imageUrl != null
                                                ? Image.network(
                                                    imageUrl,
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 90,
                                                    height: 90,
                                                    color: Colors.grey.shade300,
                                                    child: Icon(
                                                      Icons.cancel_outlined,
                                                      color: Colors.red.shade400,
                                                      size: 40,
                                                    ),
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
                                                  titleText,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Tajawal',
                                                    color: isCancelled ? Colors.red.shade400 : Colors.black,
                                                    decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'تاريخ الطلب: $formattedDate',
                                                  style: const TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
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
                                          if (!isCancelled)
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
    case 'cancelled':
      return 'ملغي';
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
    case 'cancelled':
      return Colors.red.shade400;
    default:
      return Colors.black;
  }
}
