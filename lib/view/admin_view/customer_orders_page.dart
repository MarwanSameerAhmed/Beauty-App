import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glamify/view/admin_view/order_details_page.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_Header_user.dart';
import 'package:glamify/widgets/loader.dart';
import 'package:intl/intl.dart';
import '../../utils/logger.dart';
import 'package:glamify/view/update_dialog.dart';
import 'package:glamify/controller/update_service.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({Key? key}) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSelectionMode = false;
  final Set<String> _selectedOrderIds = {};

  /// كاش بيانات المستخدمين — static عشان يبقى محفوظ حتى لو طلع ورجع للصفحة
  static final Map<String, Map<String, String>> _userDataCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedOrderIds.clear();
      }
    });
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  Future<void> _deleteSelectedOrders() async {
    if (_selectedOrderIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلبات',
            style: TextStyle(
                fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من حذف ${_selectedOrderIds.length} طلب؟\nلا يمكن التراجع عن هذا الإجراء.',
            style: const TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف',
                style:
                    TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // جلب الطلبات لمعرفة حالتها قبل الحذف لتحديث العداد
      int pendingOrdersToDelete = 0;
      
      final selectedList = _selectedOrderIds.toList();

      // تقسيم الطلبات لمجموعات من 10 لتجاوز حد whereIn
      for (var i = 0; i < selectedList.length; i += 10) {
        final end = (i + 10 < selectedList.length) ? i + 10 : selectedList.length;
        final chunk = selectedList.sublist(i, end);
        
        final snapshot = await FirebaseFirestore.instance
            .collection('customer_orders')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
            
        for (var doc in snapshot.docs) {
          if (doc.data()['status'] == 'pending_pricing') {
            pendingOrdersToDelete++;
          }
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final orderId in _selectedOrderIds) {
        final docRef = FirebaseFirestore.instance
            .collection('customer_orders')
            .doc(orderId);
        batch.delete(docRef);
      }
      await batch.commit();

      // تحديث العداد إذا تم حذف طلبات قيد الانتظار
      if (pendingOrdersToDelete > 0) {
        await FirebaseFirestore.instance.collection('metadata').doc('orders_status').set({
          'pending_orders_count': FieldValue.increment(-pendingOrdersToDelete)
        }, SetOptions(merge: true));
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف الطلبات بنجاح',
                  style: TextStyle(fontFamily: 'Tajawal'))),
        );
        setState(() {
          _isSelectionMode = false;
          _selectedOrderIds.clear();
        });
      }
    } catch (e) {
      AppLogger.error('Error deleting orders',
          tag: 'CUSTOMER_ORDERS', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('حدث خطأ أثناء الحذف',
                  style: TextStyle(fontFamily: 'Tajawal')),
              backgroundColor: Colors.red),
        );
      }
    }
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
              Stack(
                children: [
                  const CustomHeaderUser(
                    title: 'طلبات العملاء',
                    subtitle: 'عرض وإدارة طلبات العملاء',
                  ),

                  if (_isSelectionMode)
                    Positioned(
                      left: 20,
                      top: MediaQuery.of(context).padding.top + 10,
                      child: Row(
                        children: [
                          Text(
                            '${_selectedOrderIds.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent, size: 28),
                            onPressed: _deleteSelectedOrders,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                            onPressed: _toggleSelectionMode,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(128), // 0.5 opacity
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: const Color(0xFF942A59),
                    borderRadius: BorderRadius.circular(25.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF942A59).withAlpha(100),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  labelStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('تحتاج تسعير'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('تم التسعير'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('تحتاج مراجعة'),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('المؤكدة'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList([
                      'pending_pricing',
                      'pending',
                    ]), // تحتاج تسعير
                    _buildOrdersList([
                      'priced',
                      'awaiting_customer_approval',
                    ]), // تم التسعير - بانتظار رد العميل
                    _buildOrdersList([
                      'awaiting_admin_approval',
                    ]), // تحتاج مراجعة الإدارة
                    _buildOrdersList([
                      'final_approved',
                      'completed',
                    ]), // المؤكدة
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

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {}); // Rebuild to fetch futures again
      },
      child: FutureBuilder<QuerySnapshot>(
        future: query.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loader());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: Text(
                    'لا توجد طلبات في هذا القسم.',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Tajawal',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final orders = snapshot.data!.docs;

        // جلب بيانات المستخدمين الناقصة دفعة واحدة (batch)
        _prefetchUserData(orders);

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return _OrderItemWidget(
              order: orders[index],
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedOrderIds.contains(orders[index].id),
              userDataCache: _userDataCache,
              onTap: () => _handleOrderTap(orders[index]),
              onLongPress: () => _handleOrderLongPress(orders[index].id),
              onToggleSelection: () =>
                  _toggleOrderSelection(orders[index].id),
              getStatusColor: _getStatusColor,
              getStatusText: _getStatusText,
              getArabicRole: _getArabicRole,
            );
          },
        );
      },
    ),
    );
  }

  /// جلب بيانات المستخدمين مسبقاً (الي ما موجودين في الكاش فقط)
  void _prefetchUserData(List<QueryDocumentSnapshot> orders) {
    final missingUserIds = <String>{};
    for (final order in orders) {
      final orderData = order.data() as Map<String, dynamic>;
      final userId = orderData['userId'] as String? ?? '';
      if (userId.isNotEmpty && !_userDataCache.containsKey(userId)) {
        missingUserIds.add(userId);
      }
    }

    // جلب بيانات المستخدمين الناقصين
    for (final userId in missingUserIds) {
      _getUserDataCached(userId);
    }
  }

  /// جلب بيانات المستخدم مع كاش
  Future<Map<String, String>> _getUserDataCached(String userId) async {
    // إذا موجود في الكاش، نرجعه فوراً
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId]!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = <String, String>{
          'name': userDoc.data()?['name']?.toString() ?? 'غير معروف',
          'role': userDoc.data()?['role']?.toString() ?? 'غير محدد',
        };
        _userDataCache[userId] = data;
        return data;
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching user data',
        tag: 'CUSTOMER_ORDERS',
        error: e,
      );
    }
    final fallback = {'name': 'غير معروف', 'role': 'غير محدد'};
    _userDataCache[userId] = fallback;
    return fallback;
  }

  void _handleOrderTap(QueryDocumentSnapshot order) {
    final orderData = order.data() as Map<String, dynamic>;
    final status = orderData['status'];
    final isCancelled = status == 'cancelled';

    if (_isSelectionMode) {
      _toggleOrderSelection(order.id);
    } else if (isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا الطلب ملغي.',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
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
  }

  void _handleOrderLongPress(String orderId) {
    if (!_isSelectionMode) {
      _toggleSelectionMode();
      _toggleOrderSelection(orderId);
    }
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

/// ويدجت منفصل لكل عنصر طلب — يمنع إعادة بناء القائمة كاملة عند التحديد
class _OrderItemWidget extends StatelessWidget {
  final QueryDocumentSnapshot order;
  final bool isSelectionMode;
  final bool isSelected;
  final Map<String, Map<String, String>> userDataCache;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleSelection;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusText;
  final String Function(String) getArabicRole;

  const _OrderItemWidget({
    required this.order,
    required this.isSelectionMode,
    required this.isSelected,
    required this.userDataCache,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleSelection,
    required this.getStatusColor,
    required this.getStatusText,
    required this.getArabicRole,
  });

  @override
  Widget build(BuildContext context) {
    final orderData = order.data() as Map<String, dynamic>;
    final status = orderData['status'] as String? ?? '';
    final isCancelled = status == 'cancelled';
    final items = orderData['items'] as List? ?? [];
    final String? imageUrl =
        isCancelled || items.isEmpty ? null : items[0]['imageUrl'];
    final userId = orderData['userId'] as String? ?? '';

    final orderTimestamp = order['timestamp'] as Timestamp;
    final formattedDateTime = DateFormat(
      'h:mm a - yyyy/MM/dd',
      'ar',
    ).format(orderTimestamp.toDate());

    // جلب بيانات المستخدم من الكاش (متزامن — بدون FutureBuilder)
    final cachedUser = userDataCache[userId];
    final userName = cachedUser?['name'] ?? 'جاري التحميل...';
    final userRole = cachedUser?['role'] ?? '';
    final arabicRole = getArabicRole(userRole);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
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
              color: isSelected
                  ? Colors.pink.shade100.withOpacity(0.8)
                  : const Color(0xFFF9D5D3).withOpacity(0.5),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                color: isSelected
                    ? Colors.pink.shade400
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 2.0 : 1.5,
              ),
            ),
            child: Row(
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onToggleSelection(),
                      activeColor: Colors.pink.shade800,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
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
                      Text(
                        isCancelled ? 'طلب ملغي' : 'طلب من: $userName',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isCancelled ? Colors.red.shade400 : Colors.black,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (cachedUser != null) ...[
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
                          color: getStatusColor(status).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          getStatusText(status),
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
  }
}
