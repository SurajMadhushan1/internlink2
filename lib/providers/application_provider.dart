import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/application_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ApplicationProvider extends ChangeNotifier {
  List<ApplicationModel> _userApplications = [];
  List<ApplicationModel> _jobApplications = [];
  List<ApplicationModel> _companyApplications = [];
  bool _isLoading = false;
  String? _error;

  List<ApplicationModel> get userApplications => _userApplications;
  List<ApplicationModel> get jobApplications => _jobApplications;
  List<ApplicationModel> get companyApplications => _companyApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserApplications(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      _userApplications = await FirestoreService.getUserApplications(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadJobApplications(String jobId) async {
    try {
      _setLoading(true);
      _clearError();

      _jobApplications = await FirestoreService.getJobApplications(jobId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCompanyApplications(String companyId) async {
    try {
      _setLoading(true);
      _clearError();

      _companyApplications =
          await FirestoreService.getCompanyApplications(companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitApplication({
    required String jobId,
    required String companyId,
    required String userId,
    required PlatformFile resumeFile,
    String? jobTitle,
    String? companyName,
    String? userName,
    String? userEmail,
    String? userPhone,
    List<String>? userSkills,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Generate application ID
      final appId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload resume to storage
      final resumeUrl =
          await StorageService.uploadResume(userId, appId, resumeFile);

      // Create application model
      final application = ApplicationModel(
        id: appId,
        jobId: jobId,
        companyId: companyId,
        userId: userId,
        resumeUrl: resumeUrl,
        status: 'submitted',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        jobTitle: jobTitle,
        companyName: companyName,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        userSkills: userSkills,
      );

      // Save to Firestore
      final id = await FirestoreService.createApplication(application);
      final createdApplication = application.copyWith(id: id);

      // Add to user applications list
      _userApplications.insert(0, createdApplication);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateApplicationStatus(
      String applicationId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.updateApplicationStatus(applicationId, status);

      // Update in all relevant lists
      _updateApplicationInList(_userApplications, applicationId, status);
      _updateApplicationInList(_jobApplications, applicationId, status);
      _updateApplicationInList(_companyApplications, applicationId, status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> hasUserApplied(String userId, String jobId) async {
    try {
      return await FirestoreService.hasUserApplied(userId, jobId);
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void _updateApplicationInList(List<ApplicationModel> applications,
      String applicationId, String status) {
    final index = applications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      applications[index] = applications[index].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Filter applications by status
  List<ApplicationModel> getApplicationsByStatus(
      List<ApplicationModel> applications, String status) {
    return applications.where((app) => app.status == status).toList();
  }

  // Get applications count by status
  Map<String, int> getApplicationsCountByStatus(
      List<ApplicationModel> applications) {
    final counts = <String, int>{
      'submitted': 0,
      'viewed': 0,
      'shortlisted': 0,
      'rejected': 0,
    };

    for (final app in applications) {
      counts[app.status] = (counts[app.status] ?? 0) + 1;
    }

    return counts;
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
    _userApplications.clear();
    _jobApplications.clear();
    _companyApplications.clear();
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
