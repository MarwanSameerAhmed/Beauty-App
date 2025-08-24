import 'package:flutter/material.dart';
import 'package:test_pro/controller/product_service.dart';
import 'package:test_pro/model/product.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/custom_admin_header.dart';
import 'package:test_pro/widgets/product_card.dart';
import 'package:test_pro/widgets/productDetails.dart';
import 'package:test_pro/widgets/loader.dart';

class CompanyProductsPage extends StatelessWidget {
  final String companyId;
  final String companyName;

  const CompanyProductsPage({
    Key? key,
    required this.companyId,
    required this.companyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductService _productService = ProductService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FlowerBackground(
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,

          body: Column(
            children: [
              CustomAdminHeader(
                title: companyName,
                subtitle: 'استعرض كافة منتجات الشركة',
              ),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _productService.getProductsByCompanyId(companyId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Loader());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('لا توجد منتجات لهذه الشركة حاليًا.'),
                      );
                    }

                    final products = snapshot.data!;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Directionality(
                          textDirection: TextDirection.ltr,
                          child: ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsPage(
                                    product: products[index],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
