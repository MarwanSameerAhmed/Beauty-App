import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/controller/notification_service.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';

class OrderDetailsPage extends StatefulWidget {
  final DocumentSnapshot order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late List<Map<String, dynamic>> _items;
  late String _status;
  final Map<String, TextEditingController> _priceControllers = {};
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    _items = (widget.order['items'] as List).map<Map<String, dynamic>>((item) {
      final mutableItem = Map<String, dynamic>.from(item);
      final key =
          mutableItem['productId']?.toString() ??
          mutableItem['name']?.toString();
      if (key != null) {
        final controller = TextEditingController(
          text: mutableItem['price']?.toString() ?? '',
        );
        controller.addListener(_validateButtonState);
        _priceControllers[key] = controller;
      }
      return mutableItem;
    }).toList();
    _validateButtonState();
  }

  @override
  void dispose() {
    _priceControllers.forEach((_, controller) {
      controller.removeListener(_validateButtonState);
      controller.dispose();
    });
    super.dispose();
  }

  void _validateButtonState() {
    if (!mounted) return;

    bool isEnabled = false;
    if (_status == 'pending' || _status == 'pending_pricing') {
      // Enable if at least one price is entered
      isEnabled = _priceControllers.values.any((c) => c.text.isNotEmpty && double.tryParse(c.text) != null);
    } else if (_status == 'awaiting_admin_approval') {
      // Enable only if there are no pending proposals from the user
      isEnabled = !_items.any((item) => item['userAction'] == 'proposed');
    } else {
      isEnabled = false;
    }

    if (_isButtonEnabled != isEnabled) {
      setState(() {
        _isButtonEnabled = isEnabled;
      });
    }
  }

  Future<void> _updateOrder() async {
    if (!mounted) return;

    // Validate that all items have a price if the status is 'pending' or 'pending_pricing'
    if (_status == 'pending' || _status == 'pending_pricing') {
      final allPriced = _priceControllers.values.every((c) => c.text.isNotEmpty && double.tryParse(c.text) != null && double.parse(c.text) > 0);
      if (!allPriced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إدخال سعر صحيح لجميع المنتجات قبل الإرسال.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: Loader()),
    );

    // Update prices from text controllers back into the local _items list
    for (var item in _items) {
      final key = item['productId']?.toString() ?? item['name']?.toString();
      if (key != null) {
        final priceText = _priceControllers[key]?.text ?? '0.0';
        item['price'] = double.tryParse(priceText) ?? 0.0;
      }
    }

    final isFinalApproval = _status == 'awaiting_admin_approval';
    final newStatus = isFinalApproval ? 'final_approved' : 'priced';

    try {
      await widget.order.reference.update({
        'items': _items,
        'status': newStatus,
      });

      // Send notification to the user
      try {
        final String userId = widget.order['userId'];
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
          final String userToken = userDoc.data()!['fcmToken'];
          if (userToken.isNotEmpty) {
            await NotificationService.sendNotification(
              token: userToken,
              title: isFinalApproval
                  ? '✅ طلبك جاهز للتأكيد!'
                  : '✨ تم تسعير طلبك!',
              body: isFinalApproval
                  ? 'وافق المسؤول على الأسعار. يمكنك الآن تأكيد طلبك عبر واتساب.'
                  : 'قام المسؤول بتحديث أسعار طلبك. اضغط للمشاهدة.',
            );
          }
        }
      } catch (e) {
        print('Failed to send notification: $e');
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFinalApproval
                ? 'تمت الموافقة النهائية على الطلب!'
                : 'تم حفظ الأسعار بنجاح!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to the previous screen
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
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
              const CustomAdminHeader(
                title: 'تفاصيل الطلب',
                subtitle: 'مراجعة وتسعير المنتجات',
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9D5D3).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  item['imageUrl'],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الكمية: ${item['quantity']}',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildItemActions(item, index),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: _status == 'final_approved' || _status == 'priced'
              ? const SizedBox.shrink() // Hide button if order is final or already priced
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: _isButtonEnabled ? _updateOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _status == 'awaiting_admin_approval'
                          ? Colors.green.shade700
                          : const Color(0xFFC23A6D),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFC23A6D).withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black45,
                    ),
                    child: Text(
                      _status == 'awaiting_admin_approval'
                          ? 'موافقة نهائية وإرسال للعميل'
                          : 'حفظ الأسعار وإرسال للعميل',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildItemActions(Map<String, dynamic> item, int index) {
    final userAction = item['userAction'];

    switch (userAction) {
      case 'accepted':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPriceTextField(item),
            const Chip(
              label: Text(
                'وافق العميل',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        );

      case 'proposed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'السعر: ${item['price']?.toStringAsFixed(2) ?? '0.00'} ر.س',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'مقترح: ${item['proposedPrice']?.toStringAsFixed(2) ?? '0.00'} ر.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        item['price'] = item['proposedPrice'];
                        item['userAction'] = 'admin_approved';
                        final key =
                            item['productId']?.toString() ??
                            item['name']?.toString();
                        if (key != null) {
                          _priceControllers[key]?.text = item['price']
                              .toString();
                        }
                      });
                    },
                    child: const Text('قبول', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () => _showPriceEditDialog(item, index),
                    child: const Text('تعديل', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'admin_approved':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPriceTextField(item),
            const Chip(
              label: Text(
                'تمت الموافقة',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        );

      default: // 'pending' or null
        return SizedBox(width: 90, child: _buildPriceTextField(item));
    }
  }

  void _showPriceEditDialog(Map<String, dynamic> item, int index) {
    final controller = TextEditingController(
      text: item['price']?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل سعر ${item['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'السعر الجديد'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final newPrice =
                    double.tryParse(controller.text) ?? item['price'];
                item['price'] = newPrice;
                item['userAction'] = 'admin_approved';
                final key =
                    item['productId']?.toString() ?? item['name']?.toString();
                if (key != null) {
                  _priceControllers[key]?.text = newPrice.toString();
                }
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTextField(Map<String, dynamic> item) {
    final key = item['productId']?.toString() ?? item['name']?.toString();
    final bool isEditable = _status == 'pending' || _status == 'pending_pricing';

    return SizedBox(
      width: 90,
      child: TextField(
        controller: _priceControllers[key],
        enabled: isEditable,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: 'السعر',
          labelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            color: Colors.black54,
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
