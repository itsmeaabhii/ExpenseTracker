import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/state/app_providers.dart';
import '../../../theme/app_colors.dart';

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final totalSpentAsync = ref.watch(totalSpentThisMonthProvider);
    final totalIncomeAsync = ref.watch(totalIncomeThisMonthProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your spending patterns',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  title: 'Income',
                  valueAsync: totalIncomeAsync,
                  color: AppColors.positive,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Expenses',
                  valueAsync: totalSpentAsync,
                  color: AppColors.negative,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Spending by Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: spendingAsync.when(
                      data: (data) {
                        if (data.isEmpty) {
                          return const Center(
                            child: Text('No spending data available'),
                          );
                        }
                        return PieChart(
                          PieChartData(
                            sections: _createPieSections(data),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (_, __) => const Center(
                        child: Text('Could not load chart'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          spendingAsync.when(
            data: (data) {
              if (data.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Category Breakdown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...data.entries.map((entry) {
                        final total = data.values.fold<double>(0, (sum, v) => sum + v);
                        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
                        return _CategoryBar(
                          category: entry.key,
                          amount: entry.value,
                          percentage: percentage.toDouble(),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(Map<String, double> data) {
    final colors = [
      AppColors.navy,
      AppColors.navyLight,
      AppColors.positive,
      AppColors.negative,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    
    return data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final value = entry.value.value;
      final percentage = total > 0 ? (value / total * 100) : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Text(
          category.substring(0, category.length > 8 ? 8 : category.length),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.valueAsync,
    required this.color,
    required this.icon,
  });

  final String title;
  final AsyncValue<double> valueAsync;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            valueAsync.when(
              data: (value) => Text(
                '₹${value.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                    ),
              ),
              loading: () => const Text('—'),
              error: (_, __) => const Text('—'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final String category;
  final double amount;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                category,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '₹${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.subtleBorder,
              color: AppColors.navy,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
