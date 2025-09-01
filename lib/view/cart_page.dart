import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:test_pro/controller/cart_service.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_Header_user.dart';
import 'package:test_pro/controller/notification_service.dart'; // For sending notifications
import 'package:test_pro/widgets/loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_pro/widgets/elegant_dialog.dart';
import 'package:test_pro/view/loginUi.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoading = false;
  Future<void> _submitForPricing(BuildContext context, CartService cart) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: لم يتم العثور على المستخدم.')),
      );
      return;
    }

    final orderItems = cart.items.values
        .map(
          (item) => {
            'productId': item.productId,
            'name': item.name,
            'quantity': item.quantity,
            'imageUrl': item.images.first,
          },
        )
        .toList();

    try {
      await FirebaseFirestore.instance.collection('customer_orders').add({
        'userId': userId,
        'items': orderItems,
        'status': 'pending_pricing',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notify admins about the new order
      final String? notificationError =
          await NotificationService.sendTopicNotification(
            topic: 'new_orders',
            title: 'طلب تسعير جديد',
            body: 'وصل طلب جديد من أحد العملاء، يرجى مراجعته وتسعيره.',
          );

      // Clear the cart regardless of notification success
      cart.clearCart();

      if (notificationError != null) {
        // If there was an error sending the notification, show it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال الطلب، لكن فشل إرسال الإشعار: $notificationError',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // If everything was successful, show the success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إرسال طلبك للتسعير بنجاح!',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء إرسال الطلب: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return FlowerBackground(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Colors.transparent,

          body: Column(
            children: [
              CustomHeaderUser(
                title: 'السلة',
                subtitle:
                    'هنا تجد جميع المنتجات التي اخترتها وترغب \nفي طلب تسعيرها',
              ),

              Expanded(
                child: cart.items.isEmpty
                    ? const Center(
                        child: Text(
                          'سلتك فارغة حاليًا!',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Tajawal',
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: 16,
                                top: 10,
                              ),
                              itemCount: cart.items.length,
                              itemBuilder: (ctx, i) {
                                final item = cart.items.values.toList()[i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color: Colors.white.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      topRight: Radius.circular(
                                                        20,
                                                      ),
                                                      bottomRight:
                                                          Radius.circular(20),
                                                    ),
                                                child: Image.network(
                                                  item.images.first,
                                                  width: 110,
                                                  height: 110,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                        vertical: 8.0,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      Text(
                                                        item.name,
                                                        style: const TextStyle(
                                                          fontFamily: 'Tajawal',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Color(
                                                            0xFF333333,
                                                          ),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        item.description,
                                                        style: const TextStyle(
                                                          fontFamily: 'Tajawal',
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text(
                                                            'الكمية:',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Tajawal',
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .black54,
                                                            ),
                                                          ),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFF9D5D3,
                                                                  ).withOpacity(
                                                                    0.5,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    30,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                IconButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                  icon: Icon(
                                                                    item.quantity ==
                                                                            1
                                                                        ? Icons
                                                                              .delete_outline
                                                                        : Icons
                                                                              .remove,
                                                                    color: const Color(
                                                                      0xFF52002C,
                                                                    ),
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: () {
                                                                    if (item.quantity ==
                                                                        1) {
                                                                      showElegantDialog(
                                                                        context:
                                                                            context,
                                                                        child: ConfirmActionDialog(
                                                                          message:
                                                                              'هل أنت متأكد من أنك تريد حذف هذا المنتج من السلة؟',
                                                                          confirmText:
                                                                              'نعم, احذف',
                                                                          onConfirm: () {
                                                                            cart.removeItem(
                                                                              item.productId,
                                                                            );
                                                                          },
                                                                        ),
                                                                      );
                                                                    } else {
                                                                      cart.updateQuantity(
                                                                        item.productId,
                                                                        item.quantity -
                                                                            1,
                                                                      );
                                                                    }
                                                                  },
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12.0,
                                                                      ),
                                                                  child: Text(
                                                                    '${item.quantity}',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontFamily:
                                                                          'Tajawal',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  constraints:
                                                                      const BoxConstraints(),
                                                                  icon: const Icon(
                                                                    Icons.add,
                                                                    color: Color(
                                                                      0xFF52002C,
                                                                    ),
                                                                    size: 20,
                                                                  ),
                                                                  onPressed: () =>
                                                                      cart.updateQuantity(
                                                                        item.productId,
                                                                        item.quantity +
                                                                            1,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: cart.items.isEmpty || _isLoading
                                  ? null
                                  : () {
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user == null || user.isAnonymous) {
                                        showElegantDialog(
                                          context: context,
                                          child: ConfirmActionDialog(
                                            message:
                                                'يجب عليك تسجيل الدخول أولاً لإرسال طلب تسعير.',
                                            confirmText: 'تسجيل الدخول',
                                            onConfirm: () {
                                              // The dialog is popped automatically by ConfirmActionDialog.
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginUi(),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      } else {
                                        _submitForPricing(context, cart);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: const Color(0xFF52002C),
                              ),
                              child: _isLoading
                                  ? const Loader(width: 30, height: 30)
                                  : const Text(
                                      'إرسال الطلب للتسعير',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Tajawal',
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 80),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
