import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password, {
    String? roleForCreation,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await FirestoreService.createUserFromFirebaseUser(
          credential.user!,
          role: roleForCreation ?? AppConstants.roleUser,
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static Future<UserCredential?> registerWithEmailPassword(
    String email,
    String password,
    String name,
    String role, {
    String? linkedinUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        final userDoc = UserModel(
          uid: credential.user!.uid,
          role: role,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userDoc.toFirestore());

        // If company role, create/merge company at companies/{uid}
        if (role == AppConstants.roleCompany) {
          final uid = credential.user!.uid;
          final companyRef = _firestore.collection('companies').doc(uid);
          await companyRef.set({
            'ownerUid': uid,
            'name': name,
            'description': '',
            'linkedinUrl': (linkedinUrl ?? '').trim(), // ✅ never null
            'isApproved': false,
            'naitaRecognized': false,
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static Future<UserCredential?> signInWithGoogle(String role) async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      String? accessToken;
      try {
        final GoogleSignInClientAuthorization clientAuth = await account
            .authorizationClient
            .authorizeScopes(<String>['email', 'profile']);
        accessToken = clientAuth.accessToken;
      } catch (_) {
        accessToken = null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await FirestoreService.createUserFromFirebaseUser(
          userCredential.user!,
          role: role,
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      throw 'Google sign-in failed: ${e.description ?? e.toString()}';
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
