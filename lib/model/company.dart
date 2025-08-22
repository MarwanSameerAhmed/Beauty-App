class Company {
  String id;
  final String name;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  // fromMap method to create a Company object from a map (e.g., from Firestore)
  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }

  // toMap method to convert a Company object to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }
}
