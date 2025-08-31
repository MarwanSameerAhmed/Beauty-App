import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> getOrderStatusNotificationStream({required String userId, required String userRole}) {
    Query query;

    if (userRole == 'admin') {
      query = _firestore
          .collection('customer_orders')
          .where('status', isEqualTo: 'pending_pricing');
    } else {
      query = _firestore
          .collection('customer_orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'priced');
    }

    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }
}
