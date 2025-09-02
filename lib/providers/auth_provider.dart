import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => _firebaseUser != null;
  bool get isUser => _user?.role == AppConstants.roleUser;
  bool get isCompany => _user?.role == AppConstants.roleCompany;
  bool get isAdmin => _user?.role == AppConstants.roleAdmin;

  AuthProvider() {
    _init();
  }

  void _init() {
    AuthService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;

    if (firebaseUser != null) {
      try {
        _user = await FirestoreService.getUser(firebaseUser.uid);
        _user ??= await FirestoreService.createUserFromFirebaseUser(
          firebaseUser,
        );

        if (_user?.role == AppConstants.roleCompany) {
          final existingCompany =
              await FirestoreService.getCompanyByOwner(firebaseUser.uid);
          if (existingCompany == null) {
            await FirestoreService.createCompanyForOwner(
              ownerUid: firebaseUser.uid,
              name: _user?.name ?? '',
            );
          }
        }
      } catch (e) {
        _error = e.toString();
        debugPrint('Error loading user data: $e');
      }
    } else {
      _user = null;
    }

    notifyListeners();
  }

  Future<void> signInWithEmailPassword(String email, String password,
      {String? roleForCreation}) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.signInWithEmailPassword(email, password,
          roleForCreation: roleForCreation);
      await ensureProfileLoaded();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? linkedinUrl,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.registerWithEmailPassword(
        email,
        password,
        name,
        role,
        linkedinUrl: linkedinUrl,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle(String role) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.signInWithGoogle(role);
      await ensureProfileLoaded();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await AuthService.resetPassword(email);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.updateUser(updatedUser);
      _user = updatedUser;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // NEW: pick from gallery -> encode base64 -> store in Firestore -> update local model
  Future<void> updateUserPhotoFromGallery() async {
    if (_firebaseUser == null || _user == null) return;
    try {
      _setLoading(true);
      _clearError();

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        _setLoading(false);
        return;
      }

      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);

      await FirestoreService.updateUserPhotoBase64(
        uid: _user!.uid,
        base64: base64Str,
      );

      _user = _user!.copyWith(photoBase64: base64Str);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  Future<UserModel?> ensureProfileLoaded() async {
    final fbUser = _firebaseUser;
    if (fbUser == null) return null;
    if (_user != null) return _user;
    try {
      _user = await FirestoreService.getUser(fbUser.uid);
      _user ??= await FirestoreService.createUserFromFirebaseUser(fbUser);
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
    return _user;
  }

  @override
  void notifyListeners() {
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      super.notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        super.notifyListeners();
      });
    }
  }
}
