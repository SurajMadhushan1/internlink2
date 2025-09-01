import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String uid) async {
    try {
      _setLoading(true);
      _clearError();

      _user = await FirestoreService.getUser(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
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

  Future<void> updateProfileImage(XFile imageFile) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Upload image to storage
      final photoUrl =
          await StorageService.uploadProfileImage(_user!.uid, imageFile);

      // Update user with new photo URL
      final updatedUser = _user!.copyWith(photoUrl: photoUrl);
      await FirestoreService.updateUser(updatedUser);

      _user = updatedUser;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserSkills(List<String> skills) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _user!.copyWith(skills: skills);
      await FirestoreService.updateUser(updatedUser);

      _user = updatedUser;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserPhone(String phone) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _user!.copyWith(phone: phone);
      await FirestoreService.updateUser(updatedUser);

      _user = updatedUser;
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

  void clear() {
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
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
