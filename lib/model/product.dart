class Product {
  String id;
  final String name;
  final String description;
  final List<String> images;
  final double price;
  final String categoryId;
  final String companyId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    required this.categoryId,
    required this.companyId,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      companyId: data['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'categoryId': categoryId,
      'companyId': companyId,
    };
  }
}
