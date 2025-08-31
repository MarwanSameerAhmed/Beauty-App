class Category {
  String id;
  final String name;
  final String? parentId;

  Category({required this.id, required this.name, this.parentId});

  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
    };
  }
}

