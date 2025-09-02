import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/internship_model.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../shared/widgets/loading_overlay.dart';

class PostInternshipScreen extends StatefulWidget {
  const PostInternshipScreen({super.key});

  @override
  State<PostInternshipScreen> createState() => _PostInternshipScreenState();
}

class _PostInternshipScreenState extends State<PostInternshipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  final _stipendController = TextEditingController();
  final _skillController = TextEditingController();

  String _selectedCategory = AppConstants.categories[1]; // Skip 'All'
  final List<String> _skills = [];
  DateTime? _deadline;

  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  String? _pickedBase64; // what we store in Firestore

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    _stipendController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 80, // compress to keep base64 small
      );
      if (img == null) return;

      final bytes = await File(img.path).readAsBytes();

      // Enforce a soft limit (~1MB) for Firestore doc sizes
      if (bytes.length > 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image too large. Please pick < 1MB.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() {
        _pickedImage = img;
        _pickedBytes = bytes;
        _pickedBase64 = base64Encode(bytes);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _postInternship() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a deadline'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final companyProvider = context.read<CompanyProvider>();
    final internshipProvider = context.read<InternshipProvider>();
    final company = companyProvider.company;

    if (company == null || !company.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Company must be approved to post internships'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final internship = InternshipModel(
        id: '', // Firestore will generate
        companyId: company.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        skills: _skills,
        location: _locationController.text.trim(),
        type: _typeController.text.trim(),
        stipend: _stipendController.text.trim().isEmpty
            ? null
            : _stipendController.text.trim(),
        deadline: _deadline!,
        imageUrl: null, // not using Storage here
        imageBase64: _pickedBase64, // NEW: store base64 in Firestore
        createdAt: DateTime.now(),
        isActive: true,
        companyName: company.name,
        companyLogoUrl: company.logoUrl,
        companyLogoBase64: company.logoBase64,
        companyNaitaRecognized: company.naitaRecognized,
      );

      await internshipProvider.createInternship(internship);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Internship posted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post internship: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _typeController.clear();
      _stipendController.clear();
      _skillController.clear();
      _selectedCategory = AppConstants.categories[1];
      _skills.clear();
      _deadline = null;
      _pickedImage = null;
      _pickedBytes = null;
      _pickedBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Internship'),
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearForm),
        ],
      ),
      body: Consumer2<CompanyProvider, InternshipProvider>(
        builder: (context, companyProvider, internshipProvider, child) {
          final company = companyProvider.company;

          if (company == null || !company.isApproved) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pending,
                        size: 64, color: Colors.orange.shade600),
                    const SizedBox(height: 16),
                    Text(
                      'Approval Required',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your company account is pending admin approval. You can post internships once approved.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return LoadingOverlay(
            isLoading: internshipProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Internship Title',
                        hintText: 'e.g., Frontend Developer Intern',
                      ),
                      validator: (v) => Validators.required(v, 'Title'),
                    ),
                    const SizedBox(height: 16),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: AppConstants.categories
                          .skip(1)
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      validator: (v) => Validators.required(v, 'Category'),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g., Colombo, Remote, Hybrid',
                      ),
                      validator: (v) => Validators.required(v, 'Location'),
                    ),
                    const SizedBox(height: 16),

                    // Type
                    TextFormField(
                      controller: _typeController,
                      decoration: const InputDecoration(
                        labelText: 'Internship Type',
                        hintText: 'e.g., Full-time, Part-time, Project-based',
                      ),
                      validator: (v) => Validators.required(v, 'Type'),
                    ),
                    const SizedBox(height: 16),

                    // Stipend
                    TextFormField(
                      controller: _stipendController,
                      decoration: const InputDecoration(
                        labelText: 'Stipend (Optional)',
                        hintText: 'e.g., Rs. 25,000/month, Unpaid',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deadline
                    InkWell(
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Application Deadline'),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _deadline != null
                                  ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                  : 'Select deadline',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skills
                    Text(
                      'Required Skills',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skillController,
                            decoration:
                                const InputDecoration(hintText: 'Add a skill'),
                            onFieldSubmitted: (_) => _addSkill(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                            onPressed: _addSkill, child: const Text('Add')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_skills.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills
                            .map((s) => Chip(
                                  label: Text(s),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeSkill(s),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 24),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Describe the internship role, responsibilities, and requirements...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      validator: (v) => Validators.required(v, 'Description'),
                    ),
                    const SizedBox(height: 24),

                    // Image (Base64) picker
                    Text(
                      'Internship Image (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                          ),
                        ),
                        child: _pickedBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(_pickedBytes!,
                                    fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 32,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Post button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _postInternship,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Post Internship'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
