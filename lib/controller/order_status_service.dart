import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getOrderStatusNotificationStream({required String userId, required String userRole}) {
    if (userRole == 'admin') {
      // جلب عدد الطلبات غير المسعّرة فقط (pending_pricing) مباشرةً
      // عدد هذه الطلبات قليل جداً دائماً لذلك لن يستهلك قراءات كثيرة
      return _firestore
          .collection('customer_orders')
          .where('status', isEqualTo: 'pending_pricing')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } else {
      // للعملاء، العدد قليل جداً لذلك يمكننا استخدام snapshots بأمان
      Query query = _firestore
          .collection('customer_orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'priced');
      return query.snapshots().map((snapshot) => snapshot.docs.length);
    }
  }
}
