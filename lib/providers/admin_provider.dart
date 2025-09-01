import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/company_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  List<CompanyModel> _pendingCompanies = [];
  List<CompanyModel> _allCompanies = [];
  final List<UserModel> _adminUsers = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<CompanyModel> get pendingCompanies => _pendingCompanies;
  List<CompanyModel> get allCompanies => _allCompanies;
  List<UserModel> get adminUsers => _adminUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminProvider() {
    // Auto-load data when admin logs in
    AuthService.authStateChanges.listen((fbUser) {
      if (fbUser != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_disposed) return;
          loadAdminData();
        });
      } else {
        clear();
      }
    });
  }

  Future<void> loadAdminData() async {
    await Future.wait([
      loadPendingCompanies(),
      loadAllCompanies(),
    ]);
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

  Future<void> loadAllCompanies() async {
    try {
      _setLoading(true);
      _clearError();

      _allCompanies = await FirestoreService.getAllCompanies();
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

      // Update local state
      _pendingCompanies.removeWhere((company) => company.id == companyId);

      // Update in all companies list
      final companyIndex = _allCompanies.indexWhere((c) => c.id == companyId);
      if (companyIndex != -1) {
        _allCompanies[companyIndex] = _allCompanies[companyIndex].copyWith(
          isApproved: approved,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createAdminUser(String email, String name) async {
    try {
      _setLoading(true);
      _clearError();

      // This would require admin creation logic
      // For now, admins should be created manually in Firebase Console
      // or through a separate admin creation endpoint
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  int get approvedCompaniesCount =>
      _allCompanies.where((c) => c.isApproved).length;

  int get rejectedCompaniesCount => _allCompanies
      .where(
          (c) => !c.isApproved && _pendingCompanies.every((p) => p.id != c.id))
      .length;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotify();
  }

  void _clearError() {
    _error = null;
    _safeNotify();
  }

  void clearError() {
    _clearError();
  }

  void clear() {
    _pendingCompanies.clear();
    _allCompanies.clear();
    _adminUsers.clear();
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
