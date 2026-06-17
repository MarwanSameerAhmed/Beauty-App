import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getOrderStatusNotificationStream({required String userId, required String userRole}) {
    if (userRole == 'admin') {
      // استخدام العداد المنفصل للإدارة بدلاً من جلب كل الطلبات (لتوفير Reads)
      return _firestore
          .collection('metadata')
          .doc('orders_status')
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final count = snapshot.data()!['pending_orders_count'] ?? 0;
          return count < 0 ? 0 : count as int; // التأكد أن الرقم لا يصبح سالب
        }
        return 0;
      });
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
