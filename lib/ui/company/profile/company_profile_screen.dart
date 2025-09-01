import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/storage_service.dart';
import '../../shared/widgets/loading_overlay.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkedinController = TextEditingController();

  bool _isEditing = false;
  bool _naitaRecognized = false;
  String? _loadedCompanyId;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyProvider = context.read<CompanyProvider>();
      if (companyProvider.company == null) {
        final auth = context.read<AuthProvider>();
        final uid = auth.firebaseUser?.uid;
        if (uid != null) {
          companyProvider.loadCompanyByOwner(uid);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  void _loadCompanyData() {
    final company = context.read<CompanyProvider>().company;
    if (company != null) {
      _loadedCompanyId = company.id;
      _nameController.text = company.name;
      _descriptionController.text = company.description;
      _linkedinController.text = company.linkedinUrl ?? '';
      _naitaRecognized = company.naitaRecognized;
    }
  }

  Future<void> _updateLogo() async {
    try {
      final imageFile = await StorageService.pickImage();
      if (imageFile != null) {
        await context.read<CompanyProvider>().updateCompanyLogo(imageFile);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logo updated successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update logo: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final companyProvider = context.read<CompanyProvider>();
    final company = companyProvider.company;
    if (company == null) return;

    String? li = _linkedinController.text.trim();
    if (li.isEmpty) li = null; // store null, not empty

    try {
      final updatedCompany = company.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        linkedinUrl: li,
        naitaRecognized: _naitaRecognized,
      );

      await companyProvider.updateCompany(updatedCompany);

      setState(() {
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadCompanyData();
  }

  Future<void> _openLinkedIn() async {
    final company = context.read<CompanyProvider>().company;
    final url = company?.linkedinUrl?.trim();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No LinkedIn URL set'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open LinkedIn profile';
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open LinkedIn profile'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      // AuthProvider handles sign out
      // ignore: use_build_context_synchronously
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        actions: [
          if (_isEditing) ...[
            TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
            TextButton(onPressed: _saveProfile, child: const Text('Save')),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ],
      ),
      body: Consumer<CompanyProvider>(
        builder: (context, companyProvider, child) {
          final company = companyProvider.company;

          if (company != null && company.id != _loadedCompanyId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _loadCompanyData();
              setState(() {});
            });
          }

          if (company == null) {
            return const Center(child: Text('Company profile not found'));
          }

          return LoadingOverlay(
            isLoading: companyProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _updateLogo : null,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: company.logoUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.network(
                                            company.logoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                              Icons.business,
                                              size: 60,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.business,
                                          size: 60,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!company.isApproved) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Pending Approval',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (company.naitaRecognized) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'NAITA Recognized',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                      enabled: _isEditing,
                      validator: (value) =>
                          Validators.required(value, 'Company name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Company Description',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      enabled: _isEditing,
                      validator: (value) =>
                          Validators.required(value, 'Description'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkedinController,
                      decoration: InputDecoration(
                        labelText: 'LinkedIn URL',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: !_isEditing
                            ? IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: _openLinkedIn,
                              )
                            : null,
                      ),
                      enabled: _isEditing,
                      validator: Validators.linkedinUrl,
                    ),
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      SwitchListTile(
                        title: const Text('NAITA Recognized'),
                        subtitle: const Text(
                            'Check if your company is recognized by NAITA'),
                        value: _naitaRecognized,
                        onChanged: (value) {
                          setState(() {
                            _naitaRecognized = value;
                          });
                        },
                        secondary: const Icon(Icons.verified),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Column(
                        children: [
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) {
                              return SwitchListTile(
                                title: const Text('Dark Mode'),
                                subtitle: const Text(
                                    'Switch between light and dark theme'),
                                value: themeProvider.isDarkMode,
                                onChanged: (value) {
                                  themeProvider.toggleTheme();
                                },
                                secondary: const Icon(Icons.dark_mode),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Sign Out'),
                            subtitle: const Text('Sign out of your account'),
                            onTap: _signOut,
                          ),
                        ],
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
