import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';
import 'package:test_pro/services/pdf_invoice_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_pro/controller/notification_service.dart';

class CustomerOrderDetailsPage extends StatefulWidget {
  final DocumentSnapshot order;

  const CustomerOrderDetailsPage({Key? key, required this.order})
    : super(key: key);

  @override
  _CustomerOrderDetailsPageState createState() =>
      _CustomerOrderDetailsPageState();
}

class _CustomerOrderDetailsPageState extends State<CustomerOrderDetailsPage> {
  late List<Map<String, dynamic>> _items;
  late String _status;
  double _totalPrice = 0;
  bool _hasProposedPrice = false;
  bool _allActionsTaken = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    // Deep copy and add negotiation fields
    _items = (widget.order['items'] as List).map<Map<String, dynamic>>((item) {
      final newItem = Map<String, dynamic>.from(item);
      // Preserve existing userAction from Firestore, otherwise default to pending.
      newItem.putIfAbsent('userAction', () => 'pending');
      // Ensure proposedPrice field exists for local state management.
      newItem.putIfAbsent('proposedPrice', () => null);
      return newItem;
    }).toList();

    _calculateTotalPrice();
    _updateButtonStates(); // Check for proposals and actions initially
  }

  void _calculateTotalPrice() {
    double total = 0;
    // Calculate total price if it has been priced or has final approval
    if (_status == 'priced' ||
        _status == 'awaiting_customer_approval' ||
        _status == 'final_approved') {
      for (var item in _items) {
        if (item['userAction'] != 'rejected') {
          total += (item['price'] ?? 0.0) * (item['quantity'] ?? 1);
        }
      }
    }
    if (mounted) {
      setState(() {
        _totalPrice = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const CustomAdminHeader(
                title: 'تفاصيل طلبك',
                subtitle: 'هنا تجد كل تفاصيل طلبك وحالته',
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final price = item['price'] ?? 0.0;
                    final isRejected = item['userAction'] == 'rejected';

                    return Container(
                      key: ValueKey(
                        item.hashCode +
                            DateTime.now().millisecondsSinceEpoch.toInt(),
                      ), // Stronger unique key
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Opacity(
                            opacity: isRejected ? 0.5 : 1.0,
                            child: Container(
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _status == 'priced' ||
                                          _status ==
                                              'awaiting_customer_approval' ||
                                          _status == 'final_approved'
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${price.toStringAsFixed(2)} ر.س',
                                              style: const TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 16,
                                                color: Color(0xFF006400),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_status !=
                                                'final_approved') ...[
                                              const SizedBox(height: 8),
                                              _buildActionButtons(index),
                                            ] else ...[
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                height: 30,
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _showFinalCancelConfirmationDialog(
                                                        index,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.cancel_outlined,
                                                    size: 16,
                                                  ),
                                                  label: const Text('إلغاء'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red.shade400,
                                                        foregroundColor:
                                                            Colors.white,
                                                        textStyle:
                                                            const TextStyle(
                                                              fontFamily:
                                                                  'Tajawal',
                                                              fontSize: 12,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade700
                                                .withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            _status == 'awaiting_admin_approval'
                                                ? 'بانتظار الموافقة'
                                                : 'بانتظار السعر',
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_status == 'priced' ||
                  _status == 'awaiting_customer_approval' ||
                  _status == 'final_approved')
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFC23A6D).withOpacity(0.8),
                              const Color(0xFFD96C8D).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _status == 'final_approved'
                                  ? 'الإجمالي النهائي:'
                                  : 'الإجمالي المبدئي:',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_totalPrice.toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_status == 'priced' ||
                  _status == 'awaiting_customer_approval')
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _allActionsTaken
                          ? () {
                              if (_hasProposedPrice) {
                                _submitForReview();
                              } else {
                                _acceptAllPrices();
                              }
                            }
                          : null,
                      child: Text(
                        _hasProposedPrice
                            ? 'إرسال للمراجعة'
                            : 'قبول جميع الأسعار',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasProposedPrice
                            ? const Color(0xFFC23A6D)
                            : Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              if (_status == 'final_approved')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 10.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _generateAndShareInvoice(),
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'إنشاء فاتورة PDF وإرسالها',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 70,
              ), // To avoid overlap with bottom nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(int index) {
    final item = _items[index];
    final action = item['userAction'];

    if (action == 'rejected') {
      return Column(
        children: [
          const Chip(
            label: Text('مرفوض', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            avatar: Icon(Icons.cancel, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _items[index]['userAction'] = 'pending'; // Revert to pending
                  _calculateTotalPrice();
                  _updateButtonStates();
                });
              },
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('تراجع'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      );
    }

    if (action == 'accepted') {
      return const Chip(
        label: Text('تم القبول', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        avatar: Icon(Icons.check_circle, color: Colors.white, size: 18),
      );
    }

    if (action == 'proposed') {
      return Chip(
        label: Text(
          'مقترح: ${item['proposedPrice']}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        avatar: const Icon(Icons.edit, color: Colors.white, size: 18),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _items[index]['userAction'] = 'accepted';
                    _updateButtonStates();
                  });
                },
                child: const Text(
                  'قبول',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () => _showProposalDialog(index),
                child: const Text(
                  'اقتراح',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          width: 150, // Match width of the two buttons above
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteConfirmationDialog(index),
            icon: const Icon(Icons.delete, size: 16, color: Colors.white),
            label: const Text('حذف', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    showElegantDialog(
      context: context,
      child: ConfirmActionDialog(
        message: 'هل أنت متأكد من رغبتك في رفض هذا المنتج من الطلب؟',
        confirmText: 'نعم, ارفض',
        onConfirm: () {
          final nonRejectedItems = _items
              .where((item) => item['userAction'] != 'rejected')
              .toList();
          if (nonRejectedItems.length == 1) {
            _cancelOrder();
            return;
          }

          setState(() {
            _items[index]['userAction'] = 'rejected';
            _calculateTotalPrice();
            _updateButtonStates();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفض المنتج. يمكنك التراجع عن القرار.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      ),
    );
  }

  void _showProposalDialog(int index) {
    showElegantDialog(
      context: context,
      child: ProposePriceDialog(
        onPropose: (proposedPrice) {
          if (proposedPrice > 0) {
            setState(() {
              _items[index]['userAction'] = 'proposed';
              _items[index]['proposedPrice'] = proposedPrice;
              _updateButtonStates();
            });
          }
        },
      ),
    );
  }

  void _updateButtonStates() {
    if (mounted) {
      setState(() {
        _hasProposedPrice = _items.any(
          (item) => item['userAction'] == 'proposed',
        );
        // All non-rejected items must have an action (accepted or proposed).
        final activeItems = _items
            .where((i) => i['userAction'] != 'rejected')
            .toList();
        _allActionsTaken =
            activeItems.isNotEmpty &&
            activeItems.every((item) => item['userAction'] != 'pending');
      });
    }
  }

  Future<void> _cancelOrder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Loader(),
    );
    try {
      await widget.order.reference.update({'status': 'cancelled'});
      
      // Send notification to admin about order cancellation
      try {
        await NotificationService.sendTopicNotification(
          topic: 'admin_notifications',
          title: '❌ عميل ألغى طلبه',
          body: 'تم إلغاء طلب رقم ${widget.order.id} من قبل العميل.',
        );
      } catch (e) {
        print('Failed to send admin notification: $e');
      }
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loader
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب.')));
      Navigator.of(context).pop(); // Go back from details page
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loader
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إلغاء الطلب: $e')));
    }
  }

  Future<void> _acceptAllPrices() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Loader(),
    );

    try {
      // Map all items, keeping their status. For pending items, mark as accepted.
      final itemsToUpdate = _items.map((item) {
        final action = item['userAction'];
        return {
          'name': item['name'],
          'quantity': item['quantity'],
          'imageUrl': item['imageUrl'],
          'price': item['price'],
          // If action is pending, accept it. Otherwise, keep the existing action (accepted, rejected, proposed).
          'userAction': action == 'pending' ? 'accepted' : action,
          'proposedPrice': item['proposedPrice'],
        };
      }).toList();

      // If all items were rejected, cancel the order.
      if (itemsToUpdate.every((item) => item['userAction'] == 'rejected')) {
        _cancelOrder();
        return;
      }

      await widget.order.reference.update({
        'items': itemsToUpdate,
        'status': 'awaiting_admin_approval', // Status for admin to review
      });

      // Send notification to admin about customer acceptance
      try {
        await NotificationService.sendTopicNotification(
          topic: 'admin_notifications',
          title: '✅ عميل وافق على الأسعار',
          body: 'طلب رقم ${widget.order.id} جاهز للمراجعة النهائية والموافقة.',
        );
      } catch (e) {
        print('Failed to send admin notification: $e');
      }

      Navigator.of(context).pop(); // Dismiss dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم قبول الأسعار! سيتم إعلامك بعد المراجعة النهائية من الإدارة.',
          ),
        ),
      );

      setState(() {
        _status = 'awaiting_admin_approval';
      });
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  Future<void> _submitForReview() async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Loader();
      },
    );

    try {
      // The _items list already contains all necessary fields.
      // The _items list already contains the correct user actions. We send it as is.
      final itemsToUpdate = _items.map((item) {
        return {
          'name': item['name'],
          'quantity': item['quantity'],
          'imageUrl': item['imageUrl'],
          'price': item['price'],
          'userAction': item['userAction'],
          'proposedPrice': item['proposedPrice'],
        };
      }).toList();

      // If all items were rejected, cancel the order.
      if (itemsToUpdate.every((item) => item['userAction'] == 'rejected')) {
        _cancelOrder();
        return;
      }

      await widget.order.reference.update({
        'items': itemsToUpdate,
        'status': 'awaiting_admin_approval',
      });

      // Hide loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال ردك للمراجعة بنجاح!')),
      );

      // Optionally, navigate back or disable buttons
      setState(() {
        _status = 'awaiting_admin_approval';
      });
    } catch (e) {
      // Hide loading indicator
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال المراجعة: $e')),
      );
    }
  }

  void _showFinalCancelConfirmationDialog(int index) {
    showElegantDialog(
      context: context,
      child: ConfirmActionDialog(
        message: 'هل أنت متأكد من رغبتك في إلغاء هذا المنتج من الطلب؟',
        confirmText: 'نعم, إلغاء',
        onConfirm: () async {
          if (_items.length == 1) {
            _cancelOrder();
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => const Loader(),
          );

          try {
            final updatedItems = List<Map<String, dynamic>>.from(_items);
            updatedItems.removeAt(index);

            await widget.order.reference.update({'items': updatedItems});

            if (mounted) {
              setState(() {
                _items = updatedItems;
                _calculateTotalPrice();
              });
            }

            Navigator.of(context).pop(); // Dismiss loader

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إلغاء المنتج بنجاح.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop(); // Dismiss loader
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('حدث خطأ أثناء إلغاء المنتج: $e')),
            );
          }
        },
      ),
    );
  }

  Future<void> _generateAndShareInvoice() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Loader(),
      );

      // Get user data
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('userName') ?? user?.displayName ?? 'عميل';
      final userEmail = user?.email ?? 'customer@example.com';

      // Filter out rejected items
      final activeItems = _items
          .where((item) => item['userAction'] != 'rejected')
          .toList();

      // Generate PDF
      final pdfFile = await PdfInvoiceService.generateInvoice(
        items: activeItems,
        totalPrice: _totalPrice,
        customerName: userName,
        customerEmail: userEmail,
        orderNumber: widget.order.id,
      );

      // Hide loading dialog
      Navigator.of(context).pop();

      // Show options dialog
      _showInvoiceOptionsDialog(pdfFile);
    } catch (e) {
      // Hide loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء الفاتورة: $e')),
      );
    }
  }

  void _showInvoiceOptionsDialog(File pdfFile) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.03,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        const Color(0xFFF9D5D3).withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF52002C).withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success icon - responsive size
                      Container(
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: MediaQuery.of(context).size.width * 0.15,
                        constraints: const BoxConstraints(
                          minWidth: 60,
                          maxWidth: 90,
                          minHeight: 60,
                          maxHeight: 90,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.width * 0.08,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.025,
                      ),

                      // Success message - responsive text
                      Text(
                        'تم إنشاء الفاتورة بنجاح!',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: MediaQuery.of(context).size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF52002C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.02,
                        ),
                        child: Text(
                          'اختر طريقة الإرسال المناسبة لك',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.share_rounded,
                              label: 'مشاركة',
                              color: const Color(0xFF25D366),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await PdfInvoiceService.shareInvoice(
                                  pdfFile,
                                  orderNumber: widget.order.id,
                                  totalPrice: _totalPrice,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.send_rounded,
                              label: 'للمتجر',
                              color: const Color(0xFF52002C),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _sendPdfToWhatsApp(pdfFile);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),

                      // Close button - responsive
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.08,
                            vertical:
                                MediaQuery.of(context).size.height * 0.015,
                          ),
                        ),
                        child: Text(
                          'إغلاق',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade600,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendPdfToWhatsApp(File pdfFile) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Loader(),
      );

      // Get user data
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final userName =
          prefs.getString('userName') ?? user?.displayName ?? 'عميل';

      // Create detailed WhatsApp message
      final String message =
          '''🧾 *فاتورة طلب جديد*

👤 *العميل:* $userName
📋 *رقم الطلب:* ${widget.order.id}
💰 *المبلغ الإجمالي:* ${_totalPrice.toStringAsFixed(2)} ر.س

📄 تجدون في المرفق فاتورة PDF مفصلة بجميع المنتجات والأسعار.

شكراً لكم على خدماتكم المميزة 🙏''';

      // Send notification to admin about invoice being sent
      try {
        await NotificationService.sendTopicNotification(
          topic: 'admin_notifications',
          title: '📄 عميل أرسل فاتورة للمتجر',
          body: 'العميل $userName أرسل فاتورة طلب رقم ${widget.order.id} - المبلغ: ${_totalPrice.toStringAsFixed(2)} ر.س',
        );
      } catch (e) {
        print('Failed to send admin notification: $e');
      }

      // Hide loading
      Navigator.of(context).pop();

      // Show dialog with options
      _showWhatsAppSendOptions(pdfFile, message);
    } catch (e) {
      // Hide loading if still showing
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال الفاتورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWhatsAppSendOptions(File pdfFile, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.send_rounded, color: Color(0xFF52002C), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'إرسال الفاتورة للمتجر',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر طريقة الإرسال المناسبة:',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 20),

              // Option 1: Direct WhatsApp link
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Show dialog with instructions
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text(
                            'إرسال الفاتورة',
                            style: TextStyle(fontFamily: 'Tajawal'),
                            textAlign: TextAlign.center,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 50,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 15),
                              const Text(
                                'سيتم فتح واتساب مع رسالة جاهزة.\nبعدها ارجع للتطبيق لإرسال ملف الفاتورة.',
                                style: TextStyle(fontFamily: 'Tajawal'),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'رقم المتجر: 0554055582',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();

                                // Open WhatsApp with message
                                const String businessPhone = '967779836590';
                                final String whatsappUrl =
                                    'https://wa.me/$businessPhone?text=${Uri.encodeComponent(message)}';

                                if (await canLaunchUrl(
                                  Uri.parse(whatsappUrl),
                                )) {
                                  await launchUrl(
                                    Uri.parse(whatsappUrl),
                                    mode: LaunchMode.externalApplication,
                                  );

                                  // Show persistent notification to send file
                                  _showPersistentFileReminder(pdfFile);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                              ),
                              child: const Text(
                                'فتح واتساب',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text(
                    'فتح واتساب مباشرة\n(رقم المتجر: 0554055582)',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Option 2: Share menu
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Share.shareXFiles(
                      [XFile(pdfFile.path)],
                      text: message,
                      subject: 'فاتورة طلب رقم: ${widget.order.id}',
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'اختيار من قائمة التطبيقات',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF52002C),
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPersistentFileReminder(File pdfFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.05,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon and title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attachment,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              'إرسال ملف الفاتورة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Content
                      const Text(
                        'تم إرسال الرسالة لواتساب بنجاح!\nالآن اضغط الزر أدناه لإرسال ملف الفاتورة.',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await Share.shareXFiles([XFile(pdfFile.path)]);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال ملف الفاتورة بنجاح!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            'إرسال ملف الفاتورة الآن',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Later button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'يمكنك إرسال الملف لاحقاً من قائمة الطلبات',
                              ),
                              backgroundColor: Colors.grey,
                            ),
                          );
                        },
                        child: Text(
                          'إرسال لاحقاً',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.065,
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: MediaQuery.of(context).size.width * 0.045,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.038,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
