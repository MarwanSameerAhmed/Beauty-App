import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/view/admin_view/order_details_page.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_Header_user.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:intl/intl.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({Key? key}) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const CustomHeaderUser(
                title: 'طلبات العملاء',
                subtitle: 'عرض وإدارة طلبات العملاء',
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.pink.shade800,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.pink.shade800,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'الكل'),
                  Tab(text: 'تحتاج مراجعة'),
                  Tab(text: 'المؤكدة'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList([
                      // Active orders
                      'pending_pricing', // <-- أضفت هذه الحالة
                      'pending',
                      'priced',
                      'awaiting_customer_approval',
                      'awaiting_admin_approval',
                      'cancelled',
                    ]),
                    _buildOrdersList([
                      'awaiting_admin_approval',
                    ]), // Needs review
                    _buildOrdersList([
                      'final_approved',
                      'completed',
                    ]), // Confirmed
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<String>? statuses) {
    Query query = FirebaseFirestore.instance
        .collection('customer_orders')
        .orderBy('timestamp', descending: true);

    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loader());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات في هذا القسم.',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Tajawal',
                color: Colors.black,
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات في هذا القسم.',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Tajawal',
                color: Colors.black,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderData = order.data() as Map<String, dynamic>;
            final status = orderData['status'];
            final isCancelled = status == 'cancelled';
            final items = orderData['items'] as List? ?? [];
            final String? imageUrl = isCancelled || items.isEmpty ? null : items[0]['imageUrl'];

            final orderTimestamp = order['timestamp'] as Timestamp;
            final formattedDateTime = DateFormat(
              'h:mm a - yyyy/MM/dd',
              'ar',
            ).format(orderTimestamp.toDate());

            return GestureDetector(
              onTap: () {
                if (isCancelled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('هذا الطلب ملغي.', style: TextStyle(fontFamily: 'Tajawal')),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsPage(order: order),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D5D3).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(25.0),
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
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 85,
                                  height: 85,
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<Map<String, String>>(
                                future: _getUserData(order['userId']),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text(
                                      'جاري تحميل بيانات العميل...',
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  final userName =
                                      userSnapshot.data?['name'] ?? 'غير معروف';
                                  final userRole =
                                      userSnapshot.data?['role'] ?? 'غير محدد';
                                  final arabicRole = _getArabicRole(userRole);

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCancelled ? 'طلب ملغي' : 'طلب من: $userName',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isCancelled ? Colors.red.shade400 : Colors.black,
                                          decoration: isCancelled ? TextDecoration.lineThrough : TextDecoration.none,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'نوع العميل: $arabicRole',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'وقت الطلب: $formattedDateTime',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
    );
  }

  Future<Map<String, String>> _getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return {
          'name': userDoc.data()?['name'] ?? 'غير معروف',
          'role': userDoc.data()?['role'] ?? 'غير محدد',
        };
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return {'name': 'غير معروف', 'role': 'غير محدد'};
  }

  String _getArabicRole(String role) {
    switch (role) {
      case 'user':
        return 'فرد';
      case 'company':
        return 'شركة';
      default:
        return 'غير محدد';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_pricing':
        return Colors.red.shade700;
      case 'pending':
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
        return Colors.grey.shade800;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending_pricing':
        return 'بانتظار التسعير';
      case 'pending':
        return 'بانتظار التسعير';
      case 'priced':
        return 'تم التسعير';
      case 'awaiting_customer_approval':
        return 'بانتظار موافقة العميل';
      case 'awaiting_admin_approval':
        return 'يحتاج مراجعة';
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
}
