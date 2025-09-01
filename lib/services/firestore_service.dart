import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../core/constants/app_constants.dart';
import '../models/application_model.dart';
import '../models/company_model.dart';
import '../models/internship_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -----------------------------
  // USER OPERATIONS
  // -----------------------------
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    } catch (e) {
      throw 'Failed to get user: ${e.toString()}';
    }
  }

  /// Create a minimal user doc for a Firebase user if missing.
  /// If role == company, also ensure a company doc exists at companies/{ownerUid}.
  static Future<UserModel> createUserFromFirebaseUser(
    fb_auth.User firebaseUser, {
    String role = AppConstants.roleUser,
  }) async {
    try {
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
    } catch (e) {
      throw 'Failed to create user: ${e.toString()}';
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update user: ${e.toString()}';
    }
  }

  // -----------------------------
  // COMPANY OPERATIONS
  // -----------------------------

  /// Single source of truth: companies/{ownerUid}
  static Future<CompanyModel?> getCompanyByOwner(String ownerUid) async {
    try {
      // New canonical location
      final doc = await _db.collection('companies').doc(ownerUid).get();
      if (doc.exists) return CompanyModel.fromFirestore(doc);

      // Legacy fallback for older auto-ID docs (pick newest by createdAt)
      final q = await _db
          .collection('companies')
          .where('ownerUid', isEqualTo: ownerUid)
          .get();
      if (q.docs.isEmpty) return null;

      final docs = q.docs.toList()
        ..sort((a, b) {
          final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });
      return CompanyModel.fromFirestore(docs.first);
    } catch (e) {
      throw 'Failed to get company: ${e.toString()}';
    }
  }

  static Future<CompanyModel?> getCompany(String companyId) async {
    try {
      final doc = await _db.collection('companies').doc(companyId).get();
      return doc.exists ? CompanyModel.fromFirestore(doc) : null;
    } catch (e) {
      throw 'Failed to get company: ${e.toString()}';
    }
  }

  static Future<void> updateCompany(CompanyModel company) async {
    try {
      // company.id must be ownerUid in the new scheme
      await _db
          .collection('companies')
          .doc(company.id)
          .set(company.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to update company: ${e.toString()}';
    }
  }

  /// Robust pending fetch (no composite index required):
  /// 1) query isApproved == false
  /// 2) also include legacy docs where isApproved is missing (null)
  static Future<List<CompanyModel>> getPendingCompanies() async {
    try {
      final q = await _db
          .collection('companies')
          .where('isApproved', isEqualTo: false)
          .get();

      var results = q.docs.map((d) => CompanyModel.fromFirestore(d)).toList();

      // Include docs where `isApproved` is null
      final snap = await _db.collection('companies').get();
      final extras = snap.docs
          .where((d) {
            final v = d.data()['isApproved'];
            return v != true; // false or null
          })
          .map((d) => CompanyModel.fromFirestore(d))
          .toList();

      final ids = results.map((c) => c.id).toSet();
      for (final c in extras) {
        if (!ids.contains(c.id)) results.add(c);
      }

      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results;
    } catch (e) {
      throw 'Failed to get pending companies: ${e.toString()}';
    }
  }

  static Future<List<CompanyModel>> getAllCompanies() async {
    try {
      final query = await _db
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .get();
      return query.docs.map((d) => CompanyModel.fromFirestore(d)).toList();
    } catch (e) {
      throw 'Failed to get all companies: ${e.toString()}';
    }
  }

  static Future<List<CompanyModel>> getApprovedCompanies() async {
    try {
      final query = await _db
          .collection('companies')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return query.docs.map((d) => CompanyModel.fromFirestore(d)).toList();
    } catch (e) {
      throw 'Failed to get approved companies: ${e.toString()}';
    }
  }

  /// Create/merge a company doc at companies/{ownerUid}.
  static Future<CompanyModel> createCompanyForOwner({
    required String ownerUid,
    String name = '',
    String description = '',
    String? linkedinUrl, // nullable allowed
  }) async {
    try {
      final ref = _db.collection('companies').doc(ownerUid);
      await ref.set({
        'ownerUid': ownerUid,
        'name': name,
        'description': description,
        'linkedinUrl': linkedinUrl, // <- will persist if provided
        'isApproved': false,
        'naitaRecognized': false,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      final snap = await ref.get();
      return CompanyModel.fromFirestore(snap);
    } catch (e) {
      throw 'Failed to create company: ${e.toString()}';
    }
  }

  static Future<void> approveCompany(String companyId, bool approved) async {
    try {
      await _db
          .collection('companies')
          .doc(companyId)
          .set({'isApproved': approved}, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to approve company: ${e.toString()}';
    }
  }

  // -----------------------------
  // INTERNSHIP OPERATIONS
  // -----------------------------
  static Future<List<InternshipModel>> getInternships({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _db
          .collection('internships')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      var internships =
          snapshot.docs.map((d) => InternshipModel.fromFirestore(d)).toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final s = searchQuery.toLowerCase();
        internships = internships.where((i) {
          return i.title.toLowerCase().contains(s) ||
              (i.companyName?.toLowerCase().contains(s) ?? false) ||
              i.skills.any((x) => x.toLowerCase().contains(s)) ||
              i.location.toLowerCase().contains(s);
        }).toList();
      }

      // Hide internships from unapproved companies for students
      if (internships.isNotEmpty) {
        final companyIds = internships.map((i) => i.companyId).toSet().toList();
        final approvedMap = <String, bool>{};

        for (var i = 0; i < companyIds.length; i += 10) {
          final chunk = companyIds.sublist(
              i, i + 10 > companyIds.length ? companyIds.length : i + 10);
          final companiesSnap = await _db
              .collection('companies')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in companiesSnap.docs) {
            final data = doc.data();
            approvedMap[doc.id] = data['isApproved'] == true;
          }
        }

        internships =
            internships.where((i) => approvedMap[i.companyId] == true).toList();
      }

      return internships;
    } catch (e) {
      throw 'Failed to get internships: ${e.toString()}';
    }
  }

  static Future<InternshipModel?> getInternship(String internshipId) async {
    try {
      final doc = await _db.collection('internships').doc(internshipId).get();
      return doc.exists ? InternshipModel.fromFirestore(doc) : null;
    } catch (e) {
      throw 'Failed to get internship: ${e.toString()}';
    }
  }

  static Future<List<InternshipModel>> getCompanyInternships(
      String companyId) async {
    try {
      final query = await _db
          .collection('internships')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => InternshipModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get company internships: ${e.toString()}';
    }
  }

  static Future<String> createInternship(InternshipModel internship) async {
    try {
      final docRef =
          await _db.collection('internships').add(internship.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create internship: ${e.toString()}';
    }
  }

  static Future<void> updateInternship(InternshipModel internship) async {
    try {
      await _db
          .collection('internships')
          .doc(internship.id)
          .update(internship.toFirestore());
    } catch (e) {
      throw 'Failed to update internship: ${e.toString()}';
    }
  }

  static Future<void> deleteInternship(String internshipId) async {
    try {
      await _db.collection('internships').doc(internshipId).update({
        'isActive': false,
      });
    } catch (e) {
      throw 'Failed to delete internship: ${e.toString()}';
    }
  }

  // -----------------------------
  // APPLICATION OPERATIONS
  // -----------------------------
  static Future<String> createApplication(ApplicationModel application) async {
    try {
      final docRef =
          await _db.collection('applications').add(application.toFirestore());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create application: ${e.toString()}';
    }
  }

  static Future<List<ApplicationModel>> getUserApplications(
      String userId) async {
    try {
      final query = await _db
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get user applications: ${e.toString()}';
    }
  }

  static Future<List<ApplicationModel>> getJobApplications(String jobId) async {
    try {
      final query = await _db
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get job applications: ${e.toString()}';
    }
  }

  static Future<List<ApplicationModel>> getCompanyApplications(
      String companyId) async {
    try {
      final query = await _db
          .collection('applications')
          .where('companyId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get company applications: ${e.toString()}';
    }
  }

  static Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    try {
      await _db.collection('applications').doc(applicationId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw 'Failed to update application status: ${e.toString()}';
    }
  }

  static Future<bool> hasUserApplied(String userId, String jobId) async {
    try {
      final query = await _db
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check application status: ${e.toString()}';
    }
  }

  // -----------------------------
  // BATCH UTILS
  // -----------------------------
  static Future<void> batchUpdateInternshipsWithCompanyInfo() async {
    try {
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
            'companyNaitaRecognized': company.naitaRecognized,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to batch update internships: ${e.toString()}';
    }
  }

  // -----------------------------
  // ADMIN HELPERS
  // -----------------------------
  static Future<List<UserModel>> getAdminUsers() async {
    try {
      final query = await _db
          .collection('users')
          .where('role', isEqualTo: AppConstants.roleAdmin)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Failed to get admin users: ${e.toString()}';
    }
  }

  static Future<UserModel> createAdminUser(
      String uid, String email, String name) async {
    try {
      final adminUser = UserModel(
        uid: uid,
        role: AppConstants.roleAdmin,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(adminUser.toFirestore());
      return adminUser;
    } catch (e) {
      throw 'Failed to create admin user: ${e.toString()}';
    }
  }

  // -----------------------------
  // INTERNAL
  // -----------------------------
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
        'linkedinUrl': '', // initialize as empty string (not null)
        'isApproved': false,
        'naitaRecognized': false,
        'createdAt': Timestamp.now(),
      });
    }
  }
}
