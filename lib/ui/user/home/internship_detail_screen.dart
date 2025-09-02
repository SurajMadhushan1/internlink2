import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/internship_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../../services/storage_service.dart';
import '../../shared/widgets/loading_overlay.dart';

/// Inline helper: show Base64 first, else URL, else fallback icon.
/// No extra files required.
class _CompanyLogoBox extends StatelessWidget {
  final String? base64Logo;
  final String? urlLogo;
  final double size;
  final double radius;

  const _CompanyLogoBox({
    required this.base64Logo,
    required this.urlLogo,
    this.size = 24,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;

    if (base64Logo != null && base64Logo!.isNotEmpty) {
      try {
        final b64 = base64Logo!.contains(',')
            ? base64Logo!.split(',').last
            : base64Logo!;
        final bytes = Uint8List.fromList(base64Decode(b64));
        provider = MemoryImage(bytes);
      } catch (_) {}
    }

    provider ??= (urlLogo != null && urlLogo!.isNotEmpty)
        ? NetworkImage(urlLogo!)
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: provider != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image(image: provider, fit: BoxFit.cover),
            )
          : Icon(Icons.business,
              size: size * 0.8, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class InternshipDetailScreen extends StatefulWidget {
  final String internshipId;

  const InternshipDetailScreen({
    super.key,
    required this.internshipId,
  });

  @override
  State<InternshipDetailScreen> createState() => _InternshipDetailScreenState();
}

class _InternshipDetailScreenState extends State<InternshipDetailScreen> {
  bool _hasApplied = false;
  bool _isCheckingApplication = true;

  @override
  void initState() {
    super.initState();
    _loadInternship();
    _checkApplicationStatus();
  }

  Future<void> _loadInternship() async {
    await context
        .read<InternshipProvider>()
        .loadInternship(widget.internshipId);
  }

  Future<void> _checkApplicationStatus() async {
    final authProvider = context.read<AuthProvider>();
    final applicationProvider = context.read<ApplicationProvider>();

    if (authProvider.user != null) {
      final hasApplied = await applicationProvider.hasUserApplied(
        authProvider.user!.uid,
        widget.internshipId,
      );

      if (mounted) {
        setState(() {
          _hasApplied = hasApplied;
          _isCheckingApplication = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCheckingApplication = false);
      }
    }
  }

  Future<void> _applyToInternship() async {
    final authProvider = context.read<AuthProvider>();
    final internshipProvider = context.read<InternshipProvider>();
    final applicationProvider = context.read<ApplicationProvider>();

    final user = authProvider.user;
    final internship = internshipProvider.selectedInternship;

    if (user == null || internship == null) return;

    try {
      // Pick PDF resume
      final resumeFile = await StorageService.pickPdfFile();
      if (resumeFile == null) return;

      await applicationProvider.submitApplication(
        jobId: internship.id,
        companyId: internship.companyId,
        userId: user.uid,
        resumeFile: resumeFile,
        jobTitle: internship.title,
        companyName: internship.companyName,
        userName: user.name,
        userEmail: user.email,
        userPhone: user.phone,
        userSkills: user.skills,
      );

      if (!mounted) return;
      setState(() => _hasApplied = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application submitted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InternshipProvider>(
        builder: (context, provider, child) {
          final InternshipModel? internship = provider.selectedInternship;

          if (provider.isLoading || internship == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // App bar with header image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: internship.imageUrl != null &&
                          internship.imageUrl!.isNotEmpty
                      ? Image.network(
                          internship.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _HeaderFallbackIcon(),
                        )
                      : _HeaderFallbackIcon(),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        internship.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Company info (with Base64 logo)
                      Row(
                        children: [
                          _CompanyLogoBox(
                            base64Logo: internship.companyLogoBase64,
                            urlLogo: internship.companyLogoUrl,
                            size: 24,
                            radius: 4,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              internship.companyName ?? 'Company',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ),
                          if (internship.companyNaitaRecognized == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
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
                      ),

                      const SizedBox(height: 16),

                      // Quick info
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: internship.location,
                      ),
                      _InfoRow(
                        icon: Icons.work,
                        label: 'Type',
                        value: internship.type,
                      ),
                      _InfoRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: internship.category,
                      ),
                      if (internship.stipend != null &&
                          internship.stipend!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.attach_money,
                          label: 'Stipend',
                          value: internship.stipend!,
                        ),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Deadline',
                        value:
                            '${internship.deadline.day}/${internship.deadline.month}/${internship.deadline.year}',
                        isUrgent: internship.isExpired,
                      ),

                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About this internship',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        internship.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // Required skills
                      if (internship.skills.isNotEmpty) ...[
                        Text(
                          'Required Skills',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: internship.skills.map((skill) {
                            return Chip(
                              label: Text(skill),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: Consumer<ApplicationProvider>(
                          builder: (context, appProvider, child) {
                            return LoadingOverlay(
                              isLoading: appProvider.isLoading,
                              child: ElevatedButton.icon(
                                onPressed: _hasApplied ||
                                        internship.isExpired ||
                                        _isCheckingApplication
                                    ? null
                                    : _applyToInternship,
                                icon: Icon(
                                  _hasApplied ? Icons.check : Icons.send,
                                ),
                                label: Text(
                                  _isCheckingApplication
                                      ? 'Checking...'
                                      : _hasApplied
                                          ? 'Already Applied'
                                          : internship.isExpired
                                              ? 'Application Closed'
                                              : 'Apply Now',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: _hasApplied
                                      ? Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderFallbackIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Icon(
        Icons.work,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUrgent;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUrgent
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: color),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isUrgent
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
