import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../../services/storage_service.dart';
import '../../shared/widgets/loading_overlay.dart';

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

      setState(() {
        _hasApplied = hasApplied;
        _isCheckingApplication = false;
      });
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

      if (mounted) {
        setState(() {
          _hasApplied = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Application submitted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<InternshipProvider>(
        builder: (context, provider, child) {
          final internship = provider.selectedInternship;

          if (provider.isLoading || internship == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // App bar with image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: internship.imageUrl != null
                      ? Image.network(
                          internship.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Icon(
                              Icons.work,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(
                            Icons.work,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job title
                      Text(
                        internship.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Company info
                      Row(
                        children: [
                          if (internship.companyLogoUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                internship.companyLogoUrl!,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.business,
                                  size: 24,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
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
                          if (internship.companyNaitaRecognized == true) ...[
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

                      if (internship.stipend != null)
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        internship.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Required skills
                      if (internship.skills.isNotEmpty) ...[
                        Text(
                          'Required Skills',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    _hasApplied ? Icons.check : Icons.send),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isUrgent
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
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
