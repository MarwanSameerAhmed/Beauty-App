import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_pro/model/company.dart';

class CompanyService {
  final CollectionReference _companiesCollection = FirebaseFirestore.instance.collection('companies');

  Future<void> addCompany(Company company) async {
    try {
      final docRef = _companiesCollection.doc();
      company.id = docRef.id; 
      await docRef.set(company.toMap());
    } catch (e) {
      print('Error adding company: $e');
      rethrow;
    }
  }

  Future<List<Company>> getCompaniesFuture() async {
    final snapshot = await _companiesCollection.get();
    return snapshot.docs.map((doc) => Company.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Stream<List<Company>> getCompanies() {
    return _companiesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Company.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> updateCompany(Company company) async {
    try {
      await _companiesCollection.doc(company.id).update(company.toMap());
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      await _companiesCollection.doc(companyId).delete();
    } catch (e) {
      print('Error deleting company: $e');
      rethrow;
    }
  }
}
