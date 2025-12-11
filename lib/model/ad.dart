class Ad {
  String id;
  final String imageUrl;
  final String shapeType;
  final String companyId;
  final String companyName;
  final int order; // ترتيب العرض
  final bool isVisible; // مخفي أم ظاهر
  final String position; // 'top', 'middle', 'bottom'

  Ad({
    required this.id,
    required this.imageUrl,
    required this.shapeType,
    required this.companyId,
    required this.companyName,
    this.order = 0,
    this.isVisible = true,
    this.position = 'middle',
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'shapeType': shapeType,
      'companyId': companyId,
      'companyName': companyName,
      'order': order,
      'isVisible': isVisible,
      'position': position,
    };
  }
}
