class CarouselAd {
  String id;
  final String imageUrl;
  final String companyId;
  final String companyName;
  final int order; // ترتيب العرض في السلايدر
  final bool isVisible; // مخفي أم ظاهر

  CarouselAd({
    required this.id, 
    required this.imageUrl,
    required this.companyId,
    required this.companyName,
    this.order = 0,
    this.isVisible = true,
  });

  factory CarouselAd.fromMap(Map<String, dynamic> data) {
    return CarouselAd(
      id: data['id'] ?? '', 
      imageUrl: data['imageUrl'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'imageUrl': imageUrl,
      'companyId': companyId,
      'companyName': companyName,
      'order': order,
      'isVisible': isVisible,
    };
  }

  CarouselAd copyWith({
    String? id,
    String? imageUrl,
    String? companyId,
    String? companyName,
    int? order,
    bool? isVisible,
  }) {
    return CarouselAd(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
