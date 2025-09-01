import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/application_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/widgets/skeleton_loader.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context
            .read<ApplicationProvider>()
            .loadUserApplications(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('My Applications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Shortlisted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.userApplications.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => const ApplicationCardSkeleton(),
            );
          }

          final applications = provider.userApplications;

          if (applications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_off,
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
                    'Start applying to internships to see them here',
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
              _ApplicationsList(
                applications: applications,
                onOpenResume: _openResume,
              ),
              _ApplicationsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusSubmitted),
                onOpenResume: _openResume,
              ),
              _ApplicationsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusShortlisted),
                onOpenResume: _openResume,
              ),
              _ApplicationsList(
                applications: provider.getApplicationsByStatus(
                    applications, AppConstants.statusRejected),
                onOpenResume: _openResume,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  final List<ApplicationModel> applications;
  final Function(String) onOpenResume;

  const _ApplicationsList({
    required this.applications,
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
                      child: Text(
                        application.jobTitle ?? 'Internship',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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

                // Company name
                Text(
                  application.companyName ?? 'Company',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),

                const SizedBox(height: 8),

                // Dates
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

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onOpenResume(application.resumeUrl),
                        icon: const Icon(Icons.description, size: 16),
                        label: const Text('View Resume'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
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
