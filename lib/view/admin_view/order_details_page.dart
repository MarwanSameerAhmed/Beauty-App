import 'dart:ui';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_pro/controller/notification_service.dart';
import 'package:test_pro/services/pdf_invoice_service.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';

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
      // Create a mutable copy to handle local state like price controllers
      final mutableItem = Map<String, dynamic>.from(item);

      // Ensure 'userAction' from Firestore is preserved. Default to 'pending' if not present.
      mutableItem.putIfAbsent('userAction', () => 'pending');

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
      isEnabled = _priceControllers.values.any(
        (c) => c.text.isNotEmpty && double.tryParse(c.text) != null,
      );
    } else if (_status == 'awaiting_admin_approval') {
      // Enable only if there are no pending proposals from the user (ignoring rejected items)
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
      final allPriced = _priceControllers.values.every(
        (c) =>
            c.text.isNotEmpty &&
            double.tryParse(c.text) != null &&
            double.parse(c.text) > 0,
      );
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
      builder: (BuildContext context) => const Center(child: Loader()),
    );

    // Update prices and ensure 'userAction' is present
    final List<Map<String, dynamic>> updatedItems = _items.map((item) {
      final key = item['productId']?.toString() ?? item['name']?.toString();
      double price = item['price'] ?? 0.0;
      if (key != null && _priceControllers.containsKey(key)) {
        price = double.tryParse(_priceControllers[key]!.text) ?? price;
      }

      // Create a new map to avoid modifying the original list directly in the loop
      final newItem = Map<String, dynamic>.from(item);
      newItem['price'] = price;

      // If it's the first pricing, set userAction for all items.
      if (_status == 'pending' || _status == 'pending_pricing') {
        newItem['userAction'] = 'pending';
      }

      return newItem;
    }).toList();

    final isFinalApproval = _status == 'awaiting_admin_approval';
    final newStatus = isFinalApproval ? 'final_approved' : 'priced';

    // For final approval, filter out any rejected items before saving.
    final itemsToSave = isFinalApproval
        ? updatedItems
              .where((item) => item['userAction'] != 'rejected')
              .toList()
        : updatedItems;

    try {
      await widget.order.reference.update({
        'items': itemsToSave, // Save the potentially filtered list
        'status': newStatus,
      });

      // Send notification to the user
      bool notificationSent = false;
      String? notificationError;
      
      try {
        final String userId = widget.order['userId'];
        print('📤 Attempting to send notification to user: $userId');
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
          final String userToken = userDoc.data()!['fcmToken'];
          print('📱 User FCM Token found: ${userToken.substring(0, 20)}...');
          
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
            notificationSent = true;
            print('✅ Notification sent successfully');
          } else {
            notificationError = 'FCM Token فارغ';
            print('⚠️ User FCM Token is empty');
          }
        } else {
          notificationError = 'المستخدم ليس لديه FCM Token';
          print('⚠️ User document does not have fcmToken field');
        }
      } catch (e) {
        notificationError = e.toString();
        print('❌ Failed to send notification: $e');
      }

      if (!mounted) return;
      Navigator.pop(context); 

      // Show appropriate message based on notification status
      String message;
      Color backgroundColor;
      
      if (notificationSent) {
        message = isFinalApproval
            ? 'تمت الموافقة النهائية وتم إرسال الإشعار للعميل!'
            : 'تم حفظ الأسعار وإرسال الإشعار للعميل!';
        backgroundColor = Colors.green;
      } else if (notificationError != null) {
        message = isFinalApproval
            ? 'تمت الموافقة لكن فشل إرسال الإشعار: $notificationError'
            : 'تم حفظ الأسعار لكن فشل إرسال الإشعار: $notificationError';
        backgroundColor = Colors.orange;
      } else {
        message = isFinalApproval
            ? 'تمت الموافقة النهائية على الطلب!'
            : 'تم حفظ الأسعار بنجاح!';
        backgroundColor = Colors.green;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
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

  // دالة تحميل الفاتورة للأدمن
  Future<void> _downloadInvoice() async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF52002C),
        ),
      ),
    );

    try {
      // حساب المجموع الكلي
      double totalPrice = 0.0;
      final validItems = _items.where((item) => item['userAction'] != 'rejected').toList();
      
      for (var item in validItems) {
        final price = (item['price'] ?? 0.0).toDouble();
        final quantity = (item['quantity'] ?? 1).toInt();
        totalPrice += price * quantity;
      }

      // جلب بيانات العميل من قاعدة البيانات
      String customerName = 'عميل';
      String customerEmail = 'غير محدد';
      
      final userId = widget.order['userId'];
      if (userId != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            customerName = userData['name'] ?? userData['displayName'] ?? 'عميل';
            customerEmail = userData['email'] ?? 'غير محدد';
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      // إنشاء الفاتورة بنفس الطريقة التي يستخدمها العميل
      final pdfFile = await PdfInvoiceService.generateInvoice(
        items: validItems, // تمرير العناصر كما هي (نفس طريقة العميل)
        totalPrice: totalPrice,
        customerName: customerName,
        customerEmail: customerEmail,
        orderNumber: widget.order.id,
      );

      if (pdfFile != null) {
        if (mounted) {
          Navigator.pop(context); // إخفاء مؤشر التحميل
          _showDownloadOptionsDialog(pdfFile, totalPrice);
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // إخفاء مؤشر التحميل
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في إنشاء الفاتورة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إخفاء مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الفاتورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    final isRejected = item['userAction'] == 'rejected';
                    return Opacity(
                      opacity: isRejected ? 0.6 : 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isRejected
                                  ? Colors.grey.withOpacity(0.4)
                                  : const Color(0xFFF9D5D3).withOpacity(0.5),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 6),
                                      // عرض السعر الأصلي كـ hint أنيق
                                      _buildPriceHint(item),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildItemActions(item, index),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // بوتون تحميل الفاتورة (متاح دائماً للأدمن)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _downloadInvoice,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'تحميل الفاتورة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // بوتون حفظ الأسعار (يظهر حسب حالة الطلب)
                if (_status != 'final_approved' && _status != 'priced')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _updateOrder : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _status == 'awaiting_admin_approval'
                            ? Colors.green.shade700
                            : const Color(0xFFC23A6D),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(
                          0xFFC23A6D,
                        ).withOpacity(0.5),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemActions(Map<String, dynamic> item, int index) {
    final userAction = item['userAction'];

    switch (userAction) {
      case 'rejected':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item['price']?.toStringAsFixed(2) ?? '0.00'} ر.س',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 4),
            const Chip(
              label: Text(
                'رفضه العميل',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(horizontal: 4),
            ),
          ],
        );
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
    showElegantDialog(
      context: context,
      child: ProposePriceDialog(
        onPropose: (newPrice) {
          setState(() {
            item['price'] = newPrice;
            item['userAction'] = 'admin_approved';
            final key =
                item['productId']?.toString() ?? item['name']?.toString();
            if (key != null) {
              _priceControllers[key]?.text = newPrice.toString();
            }
            _validateButtonState(); // Re-validate after price change
          });
        },
      ),
    );
  }

  Widget _buildPriceTextField(Map<String, dynamic> item) {
    final key = item['productId']?.toString() ?? item['name']?.toString();
    final bool isEditable =
        _status == 'pending' || _status == 'pending_pricing';

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
          labelText: 'السعر للوحدة',
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

  // بناء widget لعرض السعر الأصلي بشكل أنيق
  Widget _buildPriceHint(Map<String, dynamic> item) {
    final originalPrice = item['originalPrice'];
    
    if (originalPrice != null && originalPrice > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 12,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                'سعر الوحدة: ${(originalPrice as num).toStringAsFixed(2)} ر.س',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_outlined,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              'أدخل السعر المطلوب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // عرض حوار خيارات التحميل
  void _showDownloadOptionsDialog(dynamic pdfFile, double totalPrice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'خيارات الفاتورة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: Color(0xFF52002C),
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر الإجراء المطلوب:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // بوتون التحميل للجهاز
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _downloadToDevice(pdfFile, totalPrice);
                  },
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'حفظ في الجهاز',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // بوتون المشاركة
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _shareInvoice(pdfFile, totalPrice);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'مشاركة الفاتورة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // تحميل الفاتورة للجهاز مباشرة
  Future<void> _downloadToDevice(dynamic pdfFile, double totalPrice) async {
    try {
      if (kIsWeb) {
        // للويب: تحميل مباشر
        await PdfInvoiceService.shareInvoice(
          pdfFile,
          orderNumber: widget.order.id,
          totalPrice: totalPrice,
        );
      } else {
        // للموبايل: نسخ الملف لمجلد التحميلات
        if (pdfFile is File) {
          // الحصول على مجلد التحميلات
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            // إنشاء مجلد التحميلات إذا لم يكن موجوداً
            final downloadsDir = Directory('${directory.path}/Download');
            if (!await downloadsDir.exists()) {
              await downloadsDir.create(recursive: true);
            }
            
            // نسخ الملف
            final fileName = 'فاتورة_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final newPath = '${downloadsDir.path}/$fileName';
            await pdfFile.copy(newPath);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حفظ الفاتورة في: $newPath'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            // إذا فشل الوصول لمجلد التحميلات، استخدم المشاركة
            await Share.shareXFiles(
              [XFile(pdfFile.path)],
              text: 'فاتورة رقم ${widget.order.id}',
              subject: 'فاتورة - اختر "حفظ في الملفات"',
            );
          }
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل الفاتورة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // مشاركة الفاتورة
  Future<void> _shareInvoice(dynamic pdfFile, double totalPrice) async {
    try {
      await PdfInvoiceService.shareInvoice(
        pdfFile,
        orderNumber: widget.order.id,
        totalPrice: totalPrice,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم مشاركة الفاتورة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}
