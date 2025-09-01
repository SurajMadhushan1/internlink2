import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all companies for admin review (uses companies collection)
  Stream<List<CompanyModel>> getAllCompanies() {
    return _firestore
        .collection('companies')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompanyModel.fromFirestore(doc))
            .toList());
  }

  // Approve company
  Future<void> approveCompany(String companyId) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'isApproved': true,
      });
    } catch (e) {
      print('Error approving company: $e');
      rethrow;
    }
  }

  // Reject company
  Future<void> rejectCompany(String companyId) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'isApproved': false,
      });
    } catch (e) {
      print('Error rejecting company: $e');
      rethrow;
    }
  }
}
