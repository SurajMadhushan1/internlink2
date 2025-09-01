import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/internship_model.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get internships from approved companies only
  Stream<List<InternshipModel>> getAvailableInternships() {
    return _firestore
        .collection('internships')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((internshipSnapshot) async {
      final internships = <InternshipModel>[];

      for (var doc in internshipSnapshot.docs) {
        final data = doc.data();
        final companyId = data['companyId'] as String?;
        if (companyId == null || companyId.isEmpty) continue;

        // Only include internships from approved companies
        final companyDoc =
            await _firestore.collection('companies').doc(companyId).get();
        if (companyDoc.exists && companyDoc.data()?['isApproved'] == true) {
          internships.add(InternshipModel.fromFirestore(doc));
        }
      }

      return internships;
    });
  }
}
