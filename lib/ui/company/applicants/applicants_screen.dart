import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/application_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../shared/widgets/skeleton_loader.dart';

class ApplicantsScreen extends StatefulWidget {
  final String jobId;

  const ApplicantsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final applicationProvider = context.read<ApplicationProvider>();
    final internshipProvider = context.read<InternshipProvider>();

    await Future.wait([
      applicationProvider.loadJobApplications(widget.jobId),
      internshipProvider.loadInternship(widget.jobId),
    ]);
  }

  Future<void> _updateApplicationStatus(
      String applicationId, String status) async {
    try {
      await context
          .read<ApplicationProvider>()
          .updateApplicationStatus(applicationId, status);

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

  Future<void> _openResume(String resumeUrl) async {
    try {
      final uri = Uri.parse(resumeUrl);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<InternshipProvider>(
          builder: (context, provider, child) {
            final internship = provider.selectedInternship;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Applicants'),
                if (internship != null)
                  Text(
                    internship.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
              ],
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'New'),
            Tab(text: 'Shortlisted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.jobApplications.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ApplicationCardSkeleton(),
            );
          }

          final applications = provider.jobApplications;

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applications will appear here when students apply',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _ApplicantsList(
                applications: applications,
                onUpdateStatus: _updateApplicationStatus,
                onOpenResume: _openResume,
              ),
              _ApplicantsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusSubmitted),
                onUpdateStatus: _updateApplicationStatus,
                onOpenResume: _openResume,
              ),
              _ApplicantsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusShortlisted),
                onUpdateStatus: _updateApplicationStatus,
                onOpenResume: _openResume,
              ),
              _ApplicantsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusRejected),
                onUpdateStatus: _updateApplicationStatus,
                onOpenResume: _openResume,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicantsList extends StatelessWidget {
  final List<ApplicationModel> applications;
  final Function(String, String) onUpdateStatus;
  final Function(String) onOpenResume;

  const _ApplicantsList({
    required this.applications,
    required this.onUpdateStatus,
    required this.onOpenResume,
  });

  Color _getStatusColor(BuildContext context, String status) {
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
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No applications in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            application.userEmail ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, application.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(context, application.status)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        application.statusDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(context, application.status),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Contact info
                if (application.userPhone != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        application.userPhone!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Skills
                if (application.userSkills != null &&
                    application.userSkills!.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: application.userSkills!.take(3).map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(fontSize: 11),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Applied date
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Applied on ${application.createdAt.day}/${application.createdAt.month}/${application.createdAt.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onOpenResume(application.resumeUrl),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('View Resume'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (status) =>
                          onUpdateStatus(application.id, status),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: AppConstants.statusViewed,
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('Mark as Viewed'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: AppConstants.statusShortlisted,
                          child: Row(
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Shortlist'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: AppConstants.statusRejected,
                          child: Row(
                            children: [
                              Icon(Icons.close, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Reject'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
