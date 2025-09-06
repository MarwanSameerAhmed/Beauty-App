class CarouselAd {
  String id;
  final String imageUrl;
  final String companyId;
  final String companyName;

  CarouselAd({
    required this.id, 
    required this.imageUrl,
    required this.companyId,
    required this.companyName,
  });

  factory CarouselAd.fromMap(Map<String, dynamic> data) {
    return CarouselAd(
      id: data['id'] ?? '', 
      imageUrl: data['imageUrl'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'imageUrl': imageUrl,
      'companyId': companyId,
      'companyName': companyName,
    };
  }
}
