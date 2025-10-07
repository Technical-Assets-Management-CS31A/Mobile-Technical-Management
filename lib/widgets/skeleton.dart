import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;

  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.shade300;
    final highlightColor = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      height: size,
      width: size,
      borderRadius: BorderRadius.circular(size / 2),
    );
  }
}

class InventorySkeleton extends StatelessWidget {
  final bool isMobile;
  const InventorySkeleton({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final horizontal = isMobile ? 16.0 : 24.0;
    final gridCrossAxisCount = isMobile ? 2 : 4;
    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: SkeletonBox(height: isMobile ? 28 : 32, width: 180)),
          SizedBox(height: isMobile ? 24 : 32),
          // Summary cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(4, (i) => i)
                .map(
                  (_) => SizedBox(
                    width: isMobile
                        ? (MediaQuery.of(context).size.width -
                                  (horizontal * 2 + 12)) /
                              2
                        : (MediaQuery.of(context).size.width -
                                  (horizontal * 2 + 16 * 3)) /
                              4,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(height: 24, width: 36),
                          SizedBox(height: 12),
                          SkeletonBox(height: 28, width: 80),
                          SizedBox(height: 8),
                          SkeletonBox(height: 16, width: 100),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Search + Filter
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 48)),
              SizedBox(width: 16),
              Expanded(child: SkeletonBox(height: 48)),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              childAspectRatio: isMobile ? 1.2 : 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: gridCrossAxisCount * 2,
            itemBuilder: (context, index) {
              return Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(height: 32, width: 32),
                    SkeletonBox(height: 24, width: 60),
                    SkeletonBox(height: 16, width: 90),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StaffSkeleton extends StatelessWidget {
  final bool isMobile;
  const StaffSkeleton({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final horizontal = isMobile ? 16.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontal),
      child: Column(
        children: [
          Center(child: SkeletonBox(height: isMobile ? 28 : 32, width: 220)),
          SizedBox(height: isMobile ? 24 : 32),
          // Summary
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: isMobile ? 12 : 16,
            children: List.generate(isMobile ? 4 : 3, (i) => i)
                .map(
                  (_) => SizedBox(
                    width: isMobile
                        ? (MediaQuery.of(context).size.width -
                                  (horizontal * 2 + 12)) /
                              2
                        : (MediaQuery.of(context).size.width -
                                  (horizontal * 2 + 16 * 2)) /
                              3,
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(height: 24, width: 36),
                          SizedBox(height: 12),
                          SkeletonBox(height: 28, width: 80),
                          SizedBox(height: 8),
                          SkeletonBox(height: 16, width: 100),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // Search & Filter
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 48)),
              SizedBox(width: 16),
              Expanded(child: SkeletonBox(height: 48)),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 32),
          // List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SkeletonCircle(size: isMobile ? 50 : 60),
                    SizedBox(width: isMobile ? 16 : 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(height: 18, width: 160),
                          SizedBox(height: 8),
                          SkeletonBox(height: 14, width: 100),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: SkeletonBox(height: 24)),
                              SizedBox(width: 12),
                              Expanded(child: SkeletonBox(height: 24)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SkeletonBox(height: 24, width: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  final bool isMobile;
  const DashboardSkeleton({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview title
          Center(child: SkeletonBox(height: isMobile ? 24 : 28, width: 120)),
          const SizedBox(height: 16),
          // Two summary rows (4 cards total)
          Row(
            children: const [
              Expanded(child: _SummarySkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: _SummarySkeletonCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _SummarySkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: _SummarySkeletonCard()),
            ],
          ),
          const SizedBox(height: 24),
          // Recently Borrowed Items card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: SkeletonBox(height: 22, width: double.infinity),
                    ),
                    const SizedBox(width: 16),
                    const SkeletonBox(height: 36, width: 100),
                  ],
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Row(
                          children: [
                            const SkeletonBox(height: 56, width: 56),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  SkeletonBox(height: 20, width: 120),
                                  SizedBox(height: 6),
                                  SkeletonBox(height: 15),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const SkeletonBox(height: 24, width: 80),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(child: SkeletonBox(height: 60)),
                            SizedBox(width: 16),
                            Expanded(child: SkeletonBox(height: 60)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: const [
                            Expanded(child: SkeletonBox(height: 48)),
                            SizedBox(width: 16),
                            Expanded(child: SkeletonBox(height: 48)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }
}

class _SummarySkeletonCard extends StatelessWidget {
  const _SummarySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 28, width: 28),
          const SizedBox(height: 16),
          const SkeletonBox(height: 32, width: 80),
          const SizedBox(height: 8),
          const SkeletonBox(height: 16, width: 100),
          const SizedBox(height: 6),
          // Make the last skeleton box responsive to prevent overflow
          const SkeletonBox(height: 28, width: double.infinity),
        ],
      ),
    );
  }
}

class HistorySkeleton extends StatelessWidget {
  final bool isMobile;
  const HistorySkeleton({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final horizontal = isMobile ? 16.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: SkeletonBox(height: isMobile ? 28 : 32, width: 220)),
          SizedBox(height: isMobile ? 24 : 32),
          // Search & Filter Section
          if (isMobile) ...[
            const SkeletonBox(height: 48),
            const SizedBox(height: 12),
            const SkeletonBox(height: 48),
            const SizedBox(height: 12),
            const SkeletonBox(height: 48),
          ] else
            Row(
              children: const [
                Expanded(flex: 2, child: SkeletonBox(height: 48)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(height: 48)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(height: 48)),
              ],
            ),
          SizedBox(height: isMobile ? 24 : 32),
          // List Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: SkeletonBox(height: 20, width: 120)),
                        SizedBox(width: 12),
                        SkeletonBox(height: 24, width: 80),
                      ],
                    ),
                    SizedBox(height: 12),
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(height: 14),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
