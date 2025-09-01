import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../models/company_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class CompanyProvider extends ChangeNotifier {
  CompanyModel? _company;
  List<CompanyModel> _pendingCompanies = [];
  int _totalCompanies = 0; // NEW
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  CompanyModel? get company => _company;
  List<CompanyModel> get pendingCompanies => _pendingCompanies;
  int get totalCompanies => _totalCompanies; // NEW
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCompanyLogo(XFile imageFile) async {
    if (_company == null) return;
    try {
      _setLoading(true);
      _clearError();

      final logoUrl =
          await StorageService.uploadCompanyLogo(_company!.id, imageFile);
      final updatedCompany = _company!.copyWith(logoUrl: logoUrl);
      await FirestoreService.updateCompany(updatedCompany);
      _company = updatedCompany;
    } catch (e) {
      _error = e.toString();
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

  /// NEW: Admin dashboard helper – loads both pending list and total count.
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
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
    } catch (e) {
      _error = e.toString();
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
