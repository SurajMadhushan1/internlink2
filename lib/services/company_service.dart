import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/company_model.dart';
import '../models/internship_model.dart';
import 'firestore_service.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CompanyModel?> getCurrentCompany() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final query = await _firestore
          .collection('companies')
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return CompanyModel.fromFirestore(query.docs.first);
    } catch (e) {
      print('Error getting current company: $e');
      return null;
    }
  }

  Future<void> updateCompanyProfile({
    required String name,
    required String description,
    String? logoUrl,
    String linkedinUrl = '',
    String? companyEmail,
    String? companyPhone,
    String? companyLocation,
    String? companyWebsite,
    List<String>? industries,
    int? employeeCount,
    DateTime? foundedDate,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existing = await _firestore
          .collection('companies')
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      final updates = <String, dynamic>{
        'ownerUid': user.uid,
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'linkedinUrl': linkedinUrl,
        if (companyEmail != null) 'companyEmail': companyEmail,
        if (companyPhone != null) 'companyPhone': companyPhone,
        if (companyLocation != null) 'companyLocation': companyLocation,
        if (companyWebsite != null) 'companyWebsite': companyWebsite,
        if (industries != null) 'industries': industries,
        if (employeeCount != null) 'employeeCount': employeeCount,
        if (foundedDate != null) 'foundedDate': foundedDate,
      };

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(updates);
      } else {
        await _firestore.collection('companies').add({
          ...updates,
          'isApproved': false,
          'naitaRecognized': false,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating company profile: $e');
      rethrow;
    }
  }

  Future<void> createCompanyProfile({
    required String name,
    required String description,
    String? logoUrl,
    String linkedinUrl = '',
    String? companyEmail,
    String? companyPhone,
    String? companyLocation,
    String? companyWebsite,
    List<String>? industries,
    int? employeeCount,
    DateTime? foundedDate,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('companies').add({
        'ownerUid': user.uid,
        'name': name,
        'description': description,
        'logoUrl': logoUrl,
        'linkedinUrl': linkedinUrl,
        'isApproved': false,
        'naitaRecognized': false,
        'createdAt': Timestamp.now(),
        'companyEmail': companyEmail,
        'companyPhone': companyPhone,
        'companyLocation': companyLocation,
        'companyWebsite': companyWebsite,
        'industries': industries,
        'employeeCount': employeeCount,
        'foundedDate': foundedDate,
      });
    } catch (e) {
      print('Error creating company profile: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> createInternship(InternshipModel internship) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not found');

      final company = await getCurrentCompany();
      if (company == null) throw Exception('Company profile not found');
      if (!company.isApproved) {
        throw Exception(
            'Your company must be approved before posting internships.');
      }

      final id = await FirestoreService.createInternship(internship);
      return id;
    } catch (e) {
      print('Error creating internship: $e');
      rethrow;
    }
  }

  Stream<List<InternshipModel>> getCompanyInternships() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('internships')
        .where('companyId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(InternshipModel.fromFirestore).toList());
  }
}
