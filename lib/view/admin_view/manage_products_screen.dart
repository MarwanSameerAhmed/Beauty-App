import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:glamify/controller/product_service.dart';
import 'package:glamify/model/product.dart';
import 'package:glamify/view/admin_view/addProductUi.dart';
import 'package:glamify/widgets/backgroundUi.dart';
import 'package:glamify/widgets/custom_admin_header.dart';
import 'package:glamify/widgets/loader.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FlowerBackground(
          child: Column(
            children: [
              const CustomAdminHeader(
                title: 'إدارة المنتجات',
                subtitle:
                    'إضافة وتعديل وحذف المنتجات مع التحكم بتفاصيلها وصورها وأسعارها',
              ),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: ProductService().getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Loader(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدث خطأ: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد منتجات حالياً.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }

                    final products = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return PlayAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildProductCard(product),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductUi()),
            );
          },
          backgroundColor: const Color(0xFF942A59),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 40,
                            ),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.white.withOpacity(0.5),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Color(0xFF52002C),
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                   
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editProduct(product);
                  } else if (value == 'delete') {
                    _deleteProduct(product.id);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('تعديل'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductUi(product: product),
      ),
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد أنك تريد حذف هذا المنتج؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('حذف'),
              onPressed: () {
                ProductService().deleteProduct(productId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
