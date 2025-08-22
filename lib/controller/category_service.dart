import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/categorys.dart';

class CategoryService {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  Future<void> addCategory(Category category) async {
    try {
      final docRef = _categoriesCollection.doc();
      category.id = docRef.id;
      await docRef.set(category.toMap());
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  
  Future<List<Category>> getCategoriesFuture() async {
    final snapshot = await _categoriesCollection.get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Category>> getCategories() {
    return _categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
