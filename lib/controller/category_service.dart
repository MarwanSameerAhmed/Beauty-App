import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glamify/model/categorys.dart';
import '../utils/logger.dart';

class CategoryService {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  Future<void> addCategory(Category category) async {
    try {
      final docRef = _categoriesCollection.doc();
      category.id = docRef.id;
      await docRef.set(category.toMap());
    } catch (e) {
      AppLogger.error('Error adding category', tag: 'CATEGORY', error: e);
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

  Future<void> updateCategory(Category category) async {
    try {
      await _categoriesCollection.doc(category.id).update(category.toMap());
    } catch (e) {
      AppLogger.error('Error updating category', tag: 'CATEGORY', error: e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
    } catch (e) {
      AppLogger.error('Error deleting category', tag: 'CATEGORY', error: e);
      rethrow;
    }
  }
}
