import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';

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
                      onPressed: () =>
                          _sendWhatsAppInvoice(context, _items, _totalPrice),
                      icon: const Icon(
                        Icons.whatshot,
                        color: Colors.white,
                      ), // Using a placeholder icon
                      label: const Text(
                        'تأكيد الطلب عبر واتساب',
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

  void _sendWhatsAppInvoice(
    BuildContext context,
    List items,
    double totalPrice,
  ) async {
    const String phoneNumber =
        '+967779836590'; // Business WhatsApp number without '+'

    // Build the invoice string
    String invoiceText = '📋 *فاتورة طلب* 📋\n\n';
    invoiceText += 'تفاصيل الطلب:\n';
    invoiceText += '-----------------\n';

    for (var item in items) {
      final name = item['name'];
      final quantity = item['quantity'];
      final price = item['price'] ?? 0.0;
      final subtotal = price * quantity;
      invoiceText += '- *المنتج:* $name\n';
      invoiceText += '  *الكمية:* $quantity\n';
      invoiceText += '  *السعر:* ${price.toStringAsFixed(2)} ر.س\n';
      invoiceText += '  *الإجمالي:* ${subtotal.toStringAsFixed(2)} ر.س\n';
      invoiceText += '-----------------\n';
    }

    invoiceText +=
        '\n💰 *الإجمالي النهائي:* ${totalPrice.toStringAsFixed(2)} ر.س';

    // Encode the message for the URL
    final String encodedMessage = Uri.encodeComponent(invoiceText);

    // Create the WhatsApp URL
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=$encodedMessage',
    );

    // Launch the URL
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الواتساب. يرجى التأكد من تثبيته.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }
}
