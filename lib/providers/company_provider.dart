import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CompanyProvider extends ChangeNotifier {
  CompanyModel? _company;
  List<CompanyModel> _pendingCompanies = [];
  int _totalCompanies = 0;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  CompanyModel? get company => _company;
  List<CompanyModel> get pendingCompanies => _pendingCompanies;
  int get totalCompanies => _totalCompanies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isApproved => _company?.isApproved ?? false;

  CompanyProvider() {
    AuthService.authStateChanges.listen((fbUser) {
      if (fbUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_disposed) return;
          loadCompanyByOwner(fbUser.uid);
        });
      } else {
        clear();
      }
    });
  }

  Future<void> loadCompanyByOwner(String ownerUid) async {
    try {
      _setLoading(true);
      _clearError();

      _company = await FirestoreService.getCompanyByOwner(ownerUid);
      _company ??= await FirestoreService.createCompanyForOwner(
        ownerUid: ownerUid,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCompany(String companyId) async {
    try {
      _setLoading(true);
      _clearError();
      _company = await FirestoreService.getCompany(companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCompany(CompanyModel updatedCompany) async {
    try {
      _setLoading(true);
      _clearError();
      await FirestoreService.updateCompany(updatedCompany);
      _company = updatedCompany;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Pick from gallery → convert to base64 → store in Firestore
  Future<void> updateCompanyLogoFromGallery() async {
    if (_company == null) return;
    try {
      _setLoading(true);
      _clearError();

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (picked == null) {
        _setLoading(false);
        return;
      }

      final bytes = await File(picked.path).readAsBytes();

      // Check file size (limit to 1MB for base64 storage)
      if (bytes.length > 1024 * 1024) {
        throw 'Image size must be less than 1MB';
      }

      final base64Str = base64Encode(bytes);

      // Update in Firestore
      await FirestoreService.updateCompanyLogoBase64(
        ownerUid: _company!.id, // company doc id == ownerUid
        base64: base64Str,
      );

      // Update local model
      _company = _company!.copyWith(logoBase64: base64Str);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingCompanies() async {
    try {
      _setLoading(true);
      _clearError();
      _pendingCompanies = await FirestoreService.getPendingCompanies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingCompaniesAndTotals() async {
    try {
      _setLoading(true);
      _clearError();

      final pending = await FirestoreService.getPendingCompanies();
      final all = await FirestoreService.getAllCompanies();

      _pendingCompanies = pending;
      _totalCompanies = all.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveCompany(String companyId, bool approved) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.approveCompany(companyId, approved);

      _pendingCompanies.removeWhere((c) => c.id == companyId);
      if (_company?.id == companyId) {
        _company = _company!.copyWith(isApproved: approved);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCompanyDescription(String description) async {
    if (_company == null) return;
    try {
      _setLoading(true);
      _clearError();

      final updated = _company!.copyWith(description: description);
      await FirestoreService.updateCompany(updated);
      _company = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNaitaRecognition(bool naitaRecognized) async {
    if (_company == null) return;
    try {
      _setLoading(true);
      _clearError();

      final updated = _company!.copyWith(naitaRecognized: naitaRecognized);
      await FirestoreService.updateCompany(updated);
      _company = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }

  void _clearError() {
    _error = null;
    _safeNotify();
  }

  void clearError() => _clearError();

  void clear() {
    _company = null;
    _pendingCompanies.clear();
    _totalCompanies = 0;
    _error = null;
    _isLoading = false;
    _safeNotify();
  }

  void _safeNotify() {
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      super.notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) super.notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
