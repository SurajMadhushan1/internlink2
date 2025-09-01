import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/application_model.dart';
import '../../../providers/application_provider.dart';

class ApplicantDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicantDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  ApplicationModel? _application;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  void _loadApplication() {
    final applicationProvider = context.read<ApplicationProvider>();
    final applications = [
      ...applicationProvider.jobApplications,
      ...applicationProvider.companyApplications,
    ];

    _application = applications.firstWhere(
      (app) => app.id == widget.applicationId,
      orElse: () => applications.first,
    );
  }

  Future<void> _updateStatus(String status) async {
    if (_application == null) return;

    try {
      await context
          .read<ApplicationProvider>()
          .updateApplicationStatus(_application!.id, status);

      setState(() {
        _application = _application!.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to $status'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openResume() async {
    if (_application?.resumeUrl == null) return;

    try {
      final uri = Uri.parse(_application!.resumeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open resume';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open resume: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusSubmitted:
        return Colors.blue;
      case AppConstants.statusViewed:
        return Colors.orange;
      case AppConstants.statusShortlisted:
        return Colors.green;
      case AppConstants.statusRejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_application == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Applicant Detail')),
        body: const Center(child: Text('Application not found')),
      );
    }

    final application = _application!;

    return Scaffold(
      appBar: AppBar(
        title: Text(application.userName ?? 'Applicant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.userName ?? 'Applicant',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (application.userEmail != null)
                                Text(
                                  application.userEmail!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(application.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getStatusColor(application.status)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            application.statusDisplayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(application.status),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Contact info
                    if (application.userPhone != null) ...[
                      _InfoRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: application.userPhone!,
                      ),
                    ],

                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Applied on',
                      value:
                          '${application.createdAt.day}/${application.createdAt.month}/${application.createdAt.year}',
                    ),

                    if (application.updatedAt != application.createdAt)
                      _InfoRow(
                        icon: Icons.update,
                        label: 'Last updated',
                        value:
                            '${application.updatedAt.day}/${application.updatedAt.month}/${application.updatedAt.year}',
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skills card
            if (application.userSkills != null &&
                application.userSkills!.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: application.userSkills!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Resume card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openResume,
                        icon: const Icon(Icons.description),
                        label: const Text('View Resume'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Text(
              'Update Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: application.status == AppConstants.statusViewed
                        ? null
                        : () => _updateStatus(AppConstants.statusViewed),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Mark Viewed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: application.status ==
                            AppConstants.statusShortlisted
                        ? null
                        : () => _updateStatus(AppConstants.statusShortlisted),
                    icon: const Icon(Icons.star),
                    label: const Text('Shortlist'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: application.status == AppConstants.statusRejected
                    ? null
                    : () => _updateStatus(AppConstants.statusRejected),
                icon: const Icon(Icons.close),
                label: const Text('Reject Application'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
