import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../core/constants/app_constants.dart';
import '../models/application_model.dart';
import '../models/company_model.dart';
import '../models/internship_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ----------------------------- USER -----------------------------
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  static Future<UserModel> createUserFromFirebaseUser(
    fb_auth.User firebaseUser, {
    String role = AppConstants.roleUser,
  }) async {
    final userRef = _db.collection('users').doc(firebaseUser.uid);
    final userSnap = await userRef.get();

    if (!userSnap.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        role: role,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toFirestore());
      if (role == AppConstants.roleCompany) {
        await _ensureCompanyDocForOwner(
          ownerUid: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
        );
      }
      return newUser;
    } else {
      final existingUser = UserModel.fromFirestore(userSnap);
      if (role == AppConstants.roleCompany) {
        await _ensureCompanyDocForOwner(
          ownerUid: firebaseUser.uid,
          name: existingUser.name,
        );
      }
      return existingUser;
    }
  }

  static Future<void> updateUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  static Future<void> updateUserPhotoBase64({
    required String uid,
    required String base64,
  }) async {
    await _db.collection('users').doc(uid).set({
      'photoBase64': base64,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ----------------------------- COMPANY -----------------------------
  static Future<CompanyModel?> getCompanyByOwner(String ownerUid) async {
    final doc = await _db.collection('companies').doc(ownerUid).get();
    if (doc.exists) return CompanyModel.fromFirestore(doc);

    final q = await _db
        .collection('companies')
        .where('ownerUid', isEqualTo: ownerUid)
        .get();
    if (q.docs.isEmpty) return null;

    q.docs.sort((a, b) {
      final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return CompanyModel.fromFirestore(q.docs.first);
  }

  static Future<CompanyModel?> getCompany(String companyId) async {
    final doc = await _db.collection('companies').doc(companyId).get();
    return doc.exists ? CompanyModel.fromFirestore(doc) : null;
  }

  static Future<void> updateCompany(CompanyModel company) async {
    await _db
        .collection('companies')
        .doc(company.id)
        .set(company.toFirestore(), SetOptions(merge: true));
  }

  static Future<void> updateCompanyLogoBase64({
    required String ownerUid,
    required String base64,
  }) async {
    await _db.collection('companies').doc(ownerUid).set({
      'logoBase64': base64,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static Future<List<CompanyModel>> getApprovedCompanies() async {
    final query = await _db
        .collection('companies')
        .where('isApproved', isEqualTo: true)
        .get();
    final list = query.docs.map(CompanyModel.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<CompanyModel> createCompanyForOwner({
    required String ownerUid,
    String name = '',
    String description = '',
    String? linkedinUrl,
  }) async {
    final ref = _db.collection('companies').doc(ownerUid);
    await ref.set({
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'linkedinUrl': linkedinUrl,
      'isApproved': false,
      'naitaRecognized': false,
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));
    final snap = await ref.get();
    return CompanyModel.fromFirestore(snap);
  }

  // ----------------------------- INTERNSHIPS -----------------------------
  static Future<List<InternshipModel>> getInternships({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _db
        .collection('internships')
        .where('isActive', isEqualTo: true)
        .limit(limit);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    var internships = snapshot.docs.map(InternshipModel.fromFirestore).toList();

    // hydrate missing company display fields
    final toHydrate = internships
        .where((i) =>
            (i.companyName == null || i.companyLogoBase64 == null) &&
            i.companyId.isNotEmpty)
        .toList();

    if (toHydrate.isNotEmpty) {
      final companyIds = toHydrate.map((i) => i.companyId).toSet().toList();
      final companySnaps = await _db
          .collection('companies')
          .where(FieldPath.documentId, whereIn: companyIds)
          .get();

      final companies = {
        for (final d in companySnaps.docs) d.id: CompanyModel.fromFirestore(d)
      };

      internships = internships
          .map((i) => (companies[i.companyId] != null &&
                  (i.companyName == null || i.companyLogoBase64 == null))
              ? i.copyWith(
                  companyName: i.companyName ?? companies[i.companyId]!.name,
                  companyLogoUrl:
                      i.companyLogoUrl ?? companies[i.companyId]!.logoUrl,
                  companyLogoBase64:
                      i.companyLogoBase64 ?? companies[i.companyId]!.logoBase64,
                  companyNaitaRecognized: i.companyNaitaRecognized ??
                      companies[i.companyId]!.naitaRecognized,
                )
              : i)
          .toList();
    }

    internships.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final s = searchQuery.toLowerCase();
      internships = internships.where((i) {
        return i.title.toLowerCase().contains(s) ||
            (i.companyName?.toLowerCase().contains(s) ?? false) ||
            i.skills.any((x) => x.toLowerCase().contains(s)) ||
            i.location.toLowerCase().contains(s);
      }).toList();
    }

    return internships;
  }

  static Future<InternshipModel?> getInternship(String internshipId) async {
    final doc = await _db.collection('internships').doc(internshipId).get();
    if (!doc.exists) return null;

    final internship = InternshipModel.fromFirestore(doc);

    if ((internship.companyName == null ||
            internship.companyLogoBase64 == null) &&
        internship.companyId.isNotEmpty) {
      final company = await getCompany(internship.companyId);
      if (company != null) {
        return internship.copyWith(
          companyName: company.name,
          companyLogoUrl: company.logoUrl,
          companyLogoBase64: company.logoBase64,
          companyNaitaRecognized: company.naitaRecognized,
        );
      }
    }
    return internship;
  }

  static Future<List<InternshipModel>> getCompanyInternships(
      String companyId) async {
    final query = await _db
        .collection('internships')
        .where('companyId', isEqualTo: companyId)
        .get();

    final list = query.docs.map(InternshipModel.fromFirestore).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<String> createInternship(InternshipModel internship) async {
    CompanyModel? company;
    if (internship.companyId.isNotEmpty) {
      company = await getCompany(internship.companyId);
    }

    final withCompanyFields = internship.copyWith(
      companyName: internship.companyName ?? company?.name,
      companyLogoUrl: internship.companyLogoUrl ?? company?.logoUrl,
      companyLogoBase64: internship.companyLogoBase64 ?? company?.logoBase64,
      companyNaitaRecognized:
          internship.companyNaitaRecognized ?? company?.naitaRecognized,
    );

    final docRef = await _db
        .collection('internships')
        .add(withCompanyFields.toFirestore());
    return docRef.id;
  }

  static Future<void> updateInternship(InternshipModel internship) async {
    await _db
        .collection('internships')
        .doc(internship.id)
        .update(internship.toFirestore());
  }

  static Future<void> deleteInternship(String internshipId) async {
    await _db.collection('internships').doc(internshipId).update({
      'isActive': false,
    });
  }

  static Future<void> batchUpdateInternshipsWithCompanyInfo() async {
    final companiesSnapshot = await _db.collection('companies').get();
    final companies = {
      for (var doc in companiesSnapshot.docs)
        doc.id: CompanyModel.fromFirestore(doc)
    };

    final internshipsSnapshot = await _db.collection('internships').get();
    final batch = _db.batch();

    for (var doc in internshipsSnapshot.docs) {
      final internship = InternshipModel.fromFirestore(doc);
      final company = companies[internship.companyId];
      if (company != null) {
        batch.update(doc.reference, {
          'companyName': company.name,
          'companyLogoUrl': company.logoUrl,
          'companyLogoBase64': company.logoBase64,
          'companyNaitaRecognized': company.naitaRecognized,
        });
      }
    }

    await batch.commit();
  }

  // ----------------------------- INTERNAL -----------------------------
  static Future<void> _ensureCompanyDocForOwner({
    required String ownerUid,
    String name = '',
  }) async {
    final ref = _db.collection('companies').doc(ownerUid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'ownerUid': ownerUid,
        'name': name,
        'description': '',
        'linkedinUrl': '',
        'isApproved': false,
        'naitaRecognized': false,
        'createdAt': Timestamp.now(),
      });
    }
  }

  // ----------------------------- COMPANIES (Admin) -----------------------------
  static Future<List<CompanyModel>> getPendingCompanies() async {
    final q = await _db
        .collection('companies')
        .where('isApproved', isEqualTo: false)
        .get();

    var list = q.docs.map((d) => CompanyModel.fromFirestore(d)).toList();

    final snap = await _db.collection('companies').get();
    final extras = snap.docs
        .where((d) => d.data()['isApproved'] != true)
        .map((d) => CompanyModel.fromFirestore(d))
        .toList();

    final ids = list.map((c) => c.id).toSet();
    for (final c in extras) {
      if (!ids.contains(c.id)) list.add(c);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<List<CompanyModel>> getAllCompanies() async {
    final query = await _db.collection('companies').get();
    final list = query.docs.map((d) => CompanyModel.fromFirestore(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> approveCompany(String companyId, bool approved) async {
    await _db
        .collection('companies')
        .doc(companyId)
        .set({'isApproved': approved}, SetOptions(merge: true));
  }

  // ----------------------------- APPLICATIONS -----------------------------
  static Future<String> createApplication(ApplicationModel application) async {
    final docRef =
        await _db.collection('applications').add(application.toFirestore());
    return docRef.id;
  }

  static Future<List<ApplicationModel>> getUserApplications(
      String userId) async {
    final query = await _db
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => ApplicationModel.fromFirestore(doc))
        .toList();
  }

  static Future<List<ApplicationModel>> getJobApplications(String jobId) async {
    final query = await _db
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => ApplicationModel.fromFirestore(doc))
        .toList();
  }

  static Future<List<ApplicationModel>> getCompanyApplications(
      String companyId) async {
    final query = await _db
        .collection('applications')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .get();
    return query.docs
        .map((doc) => ApplicationModel.fromFirestore(doc))
        .toList();
  }

  static Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    await _db.collection('applications').doc(applicationId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<bool> hasUserApplied(String userId, String jobId) async {
    final query = await _db
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }
}
