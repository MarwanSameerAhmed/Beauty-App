class Company {
  String id;
  final String name;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }
}
