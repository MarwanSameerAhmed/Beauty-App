class CarouselAd {
  String id;
  final String imageUrl;

  CarouselAd({required this.id, required this.imageUrl});

  factory CarouselAd.fromMap(Map<String, dynamic> data) {
    return CarouselAd(id: data['id'] ?? '', imageUrl: data['imageUrl'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'imageUrl': imageUrl};
  }
}
