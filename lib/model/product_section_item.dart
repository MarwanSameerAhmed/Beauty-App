class ProductSectionItem {
  final String id;
  final String sectionId;
  final String productId;
  final int order;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductSectionItem({
    required this.id,
    required this.sectionId,
    required this.productId,
    required this.order,
    this.isVisible = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ProductSectionItem.fromMap(Map<String, dynamic> data) {
    return ProductSectionItem(
      id: data['id'] ?? '',
      sectionId: data['sectionId'] ?? '',
      productId: data['productId'] ?? '',
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sectionId': sectionId,
      'productId': productId,
      'order': order,
      'isVisible': isVisible,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  ProductSectionItem copyWith({
    String? id,
    String? sectionId,
    String? productId,
    int? order,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductSectionItem(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      productId: productId ?? this.productId,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // إنشاء عنصر جديد
  static ProductSectionItem create({
    required String sectionId,
    required String productId,
    required int order,
    bool isVisible = true,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return ProductSectionItem(
      id: 'product_section_${timestamp}_${productId.substring(0, 8)}',
      sectionId: sectionId,
      productId: productId,
      order: order,
      isVisible: isVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSectionItem &&
        other.id == id &&
        other.sectionId == sectionId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ sectionId.hashCode ^ productId.hashCode;
  }

  @override
  String toString() {
    return 'ProductSectionItem(id: $id, sectionId: $sectionId, productId: $productId, order: $order, isVisible: $isVisible)';
  }
}
