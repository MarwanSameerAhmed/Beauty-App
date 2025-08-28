import 'package:test_pro/model/product.dart';

class CartItem {
  final String productId;
  final String name;
  final String description;
  final List<String> images;
  int quantity;
  double price; // This might be the initial price, or the priced value later

  CartItem({
    required this.productId,
    required this.name,
    required this.description,
    required this.images,
    this.quantity = 1,
    this.price = 0.0, // Default to 0, will be set from product
  });

  // A factory constructor to create a CartItem from a Product
  factory CartItem.fromProduct(Product product) {
    return CartItem(
      productId: product.id,
      name: product.name,
      description: product.description,
      images: product.images,
      quantity: 1,
    );
  }

  // Methods to convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'images': images,
      'quantity': quantity,
      'price': price,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'],
      name: json['name'],
      description: json['description'] ?? '', // Handle legacy items without description
      images: List<String>.from(json['images']),
      quantity: json['quantity'],
      price: json['price'],
    );
  }
}
