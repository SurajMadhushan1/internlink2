import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/internship_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/internship_provider.dart';
import '../../shared/widgets/skeleton_loader.dart';

// Inline helper: show Base64 first, else URL, else icon
class _CompanyLogoBox extends StatelessWidget {
  final String? base64Logo;
  final String? urlLogo;
  final double size;
  final double radius;

  const _CompanyLogoBox({
    required this.base64Logo,
    required this.urlLogo,
    this.size = 48,
    this.radius = 8,
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
          : Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternshipProvider>().loadInternships(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<InternshipProvider>().loadMoreInternships();
    }
  }

  void _onSearchChanged(String query) {
    context.read<InternshipProvider>().setSearchQuery(query);
  }

  void _onCategorySelected(String category) {
    context.read<InternshipProvider>().setCategory(category);
  }

  Future<void> _onRefresh() async {
    await context.read<InternshipProvider>().loadInternships(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${authProvider.user?.name ?? 'Student'}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Find your perfect internship',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search internships, companies, skills...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Consumer<InternshipProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  height: 50,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.categories.length,
                    itemBuilder: (context, index) {
                      final category = AppConstants.categories[index];
                      final isSelected = provider.selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _onCategorySelected(category),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer<InternshipProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.internships.isEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          const InternshipCardSkeleton(),
                    );
                  }

                  if (provider.error != null) {
                    return Center(child: Text(provider.error!));
                  }

                  if (provider.internships.isEmpty) {
                    return const Center(child: Text('No internships found'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.internships.length +
                        (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.internships.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final internship = provider.internships[index];
                      return InternshipCard(
                        internship: internship,
                        onTap: () =>
                            context.go('/user/internship/${internship.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InternshipCard extends StatelessWidget {
  final InternshipModel internship;
  final VoidCallback onTap;

  const InternshipCard({
    super.key,
    required this.internship,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                _CompanyLogoBox(
                  base64Logo: internship.companyLogoBase64,
                  urlLogo: internship.companyLogoUrl,
                  size: 48,
                  radius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(
                              internship.companyName ?? 'Company',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (internship.companyNaitaRecognized == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'NAITA',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade800),
                              ),
                            ),
                        ]),
                        Text(
                          internship.location,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6)),
                        ),
                      ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              internship.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              internship.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            if (internship.skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: internship.skills.take(3).map((skill) {
                  return Chip(
                    label: Text(skill, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.access_time,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  internship.timeLeft,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: internship.isExpired
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                ),
              ]),
              if (internship.stipend != null)
                Text(
                  internship.stipend!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
