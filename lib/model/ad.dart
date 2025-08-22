class Ad {
  String id;
  final String imageUrl;
  final String shapeType;
  final String companyId;
  final String companyName;

  Ad({
    required this.id,
    required this.imageUrl,
    required this.shapeType,
    required this.companyId,
    required this.companyName,
  });

  factory Ad.fromMap(Map<String, dynamic> data) {
    return Ad(
      id: data['id'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      shapeType: data['shapeType'] ?? 'rectangle',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'shapeType': shapeType,
      'companyId': companyId,
      'companyName': companyName,
    };
  }
}
