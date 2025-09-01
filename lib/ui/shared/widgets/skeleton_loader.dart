import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class InternshipCardSkeleton extends StatelessWidget {
  const InternshipCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoader(width: double.infinity, height: 16),
                      const SizedBox(height: 8),
                      SkeletonLoader(
                          width: 120,
                          height: 14,
                          borderRadius: BorderRadius.circular(2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonLoader(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            const SkeletonLoader(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            SkeletonLoader(
                width: 200, height: 16, borderRadius: BorderRadius.circular(2)),
            const SizedBox(height: 16),
            Row(
              children: [
                SkeletonLoader(
                    width: 60,
                    height: 24,
                    borderRadius: BorderRadius.circular(12)),
                const SizedBox(width: 8),
                SkeletonLoader(
                    width: 80,
                    height: 24,
                    borderRadius: BorderRadius.circular(12)),
                const SizedBox(width: 8),
                SkeletonLoader(
                    width: 70,
                    height: 24,
                    borderRadius: BorderRadius.circular(12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApplicationCardSkeleton extends StatelessWidget {
  const ApplicationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: SkeletonLoader(width: double.infinity, height: 18),
                ),
                const SizedBox(width: 16),
                SkeletonLoader(
                    width: 80,
                    height: 24,
                    borderRadius: BorderRadius.circular(12)),
              ],
            ),
            const SizedBox(height: 8),
            const SkeletonLoader(width: 150, height: 16),
            const SizedBox(height: 8),
            SkeletonLoader(
                width: 100, height: 14, borderRadius: BorderRadius.circular(2)),
          ],
        ),
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Avatar
        const SkeletonLoader(
            width: 120,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(60))),
        const SizedBox(height: 16),
        // Name
        const SkeletonLoader(width: 200, height: 24),
        const SizedBox(height: 8),
        // Email
        SkeletonLoader(
            width: 160, height: 16, borderRadius: BorderRadius.circular(2)),
        const SizedBox(height: 32),
        // Info sections
        ...List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLoader(width: 120, height: 16),
                        const SizedBox(height: 8),
                        const SkeletonLoader(
                            width: double.infinity, height: 14),
                        const SizedBox(height: 4),
                        SkeletonLoader(
                            width: 180,
                            height: 14,
                            borderRadius: BorderRadius.circular(2)),
                      ],
                    ),
                  ),
                )),
      ],
    );
  }
}
