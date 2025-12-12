class Ad {
  String id;
  final String imageUrl;
  final String shapeType;
  final String companyId;
  final String companyName;
  final int order; // ترتيب العرض
  final bool isVisible; // مخفي أم ظاهر
  final String position; // 'top', 'middle', 'bottom'
  final String sectionId; // معرف القسم الذي ينتمي إليه الإعلان

  Ad({
    required this.id,
    required this.imageUrl,
    required this.shapeType,
    required this.companyId,
    required this.companyName,
    this.order = 0,
    this.isVisible = true,
    this.position = 'middle',
    this.sectionId = 'middle_section', // القيمة الافتراضية
  });

  factory Ad.fromMap(Map<String, dynamic> data) {
    return Ad(
      id: data['id'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      shapeType: data['shapeType'] ?? 'rectangle',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      order: data['order'] ?? 0,
      isVisible: data['isVisible'] ?? true,
      position: data['position'] ?? 'middle',
      sectionId: data['sectionId'] ?? 'middle_section',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shapeType': shapeType,
      'imageUrl': imageUrl,
      'companyId': companyId,
      'companyName': companyName,
      'order': order,
      'isVisible': isVisible,
      'sectionId': sectionId,
    };
  }

  Ad copyWith({
    String? id,
    String? shapeType,
    String? imageUrl,
    String? companyId,
    String? companyName,
    int? order,
    bool? isVisible,
    String? sectionId,
  }) {
    return Ad(
      id: id ?? this.id,
      shapeType: shapeType ?? this.shapeType,
      imageUrl: imageUrl ?? this.imageUrl,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
      position: this.position,
      sectionId: sectionId ?? this.sectionId,
    );
  }
}
