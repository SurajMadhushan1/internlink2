import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../models/internship_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class InternshipProvider extends ChangeNotifier {
  final List<InternshipModel> _internships = [];
  List<InternshipModel> _companyInternships = [];
  InternshipModel? _selectedInternship;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  List<InternshipModel> get internships => _internships;
  List<InternshipModel> get companyInternships => _companyInternships;
  InternshipModel? get selectedInternship => _selectedInternship;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;

  Future<void> loadInternships({
    bool refresh = false,
    String? category,
    String? searchQuery,
  }) async {
    if (refresh) {
      _internships.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    try {
      _setLoading(true);
      _clearError();

      final newInternships = await FirestoreService.getInternships(
        category: category ?? _selectedCategory,
        searchQuery: searchQuery ?? _searchQuery,
        lastDocument: _lastDocument,
      );

      if (newInternships.isNotEmpty) {
        _internships.addAll(newInternships);
        // Note: In a real implementation, you'd get the lastDocument from the query
        // _lastDocument = snapshot.docs.last;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreInternships() async {
    if (!_hasMore || _isLoadingMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final newInternships = await FirestoreService.getInternships(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        lastDocument: _lastDocument,
      );

      if (newInternships.isNotEmpty) {
        _internships.addAll(newInternships);
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadInternship(String internshipId) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedInternship = await FirestoreService.getInternship(internshipId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCompanyInternships(String companyId) async {
    try {
      _setLoading(true);
      _clearError();

      _companyInternships =
          await FirestoreService.getCompanyInternships(companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createInternship(InternshipModel internship) async {
    try {
      _setLoading(true);
      _clearError();

      final id = await FirestoreService.createInternship(internship);
      final createdInternship = internship.copyWith(id: id);

      _companyInternships.insert(0, createdInternship);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateInternship(InternshipModel internship) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.updateInternship(internship);

      // Update in company internships list
      final index =
          _companyInternships.indexWhere((i) => i.id == internship.id);
      if (index != -1) {
        _companyInternships[index] = internship;
      }

      // Update in main internships list
      final mainIndex = _internships.indexWhere((i) => i.id == internship.id);
      if (mainIndex != -1) {
        _internships[mainIndex] = internship;
      }

      // Update selected internship
      if (_selectedInternship?.id == internship.id) {
        _selectedInternship = internship;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteInternship(String internshipId) async {
    try {
      _setLoading(true);
      _clearError();

      await FirestoreService.deleteInternship(internshipId);

      // Remove from lists
      _companyInternships.removeWhere((i) => i.id == internshipId);
      _internships.removeWhere((i) => i.id == internshipId);

      // Clear selected if it was deleted
      if (_selectedInternship?.id == internshipId) {
        _selectedInternship = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadInternshipImage(String jobId, XFile imageFile) async {
    try {
      _setLoading(true);
      _clearError();

      final imageUrl =
          await StorageService.uploadInternshipImage(jobId, imageFile);

      // Update internship with image URL
      if (_selectedInternship != null) {
        final updatedInternship =
            _selectedInternship!.copyWith(imageUrl: imageUrl);
        await updateInternship(updatedInternship);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadInternships(refresh: true, category: category);
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      loadInternships(refresh: true, searchQuery: query);
    }
  }

  void clearSearch() {
    _searchQuery = '';
    loadInternships(refresh: true);
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
    _internships.clear();
    _companyInternships.clear();
    _selectedInternship = null;
    _error = null;
    _isLoading = false;
    _isLoadingMore = false;
    _selectedCategory = 'All';
    _searchQuery = '';
    _lastDocument = null;
    _hasMore = true;
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
