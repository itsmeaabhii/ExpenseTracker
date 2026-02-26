import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/summary_card.dart';
import '../../../core/state/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../transactions/presentation/transactions_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSpentAsync = ref.watch(totalSpentThisMonthProvider);
    final totalIncomeAsync = ref.watch(totalIncomeThisMonthProvider);
    final budgetsAsync = ref.watch(budgetListProvider);
    final txAsync = ref.watch(transactionListProvider);
    final goalsAsync = ref.watch(goalListProvider);
    final remindersAsync = ref.watch(upcomingRemindersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: <Widget>[
          // Quick Actions
          Row(
            children: <Widget>[
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_upward,
                  label: 'Add Expense',
                  color: AppColors.negative,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddTransactionScreen(initialIsExpense: true),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_downward,
                  label: 'Add Income',
                  color: AppColors.positive,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AddTransactionScreen(initialIsExpense: false),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Summary Cards
          Row(
            children: <Widget>[
              Expanded(
                child: totalIncomeAsync.when(
                  data: (value) => SummaryCard(
                    title: 'Income',
                    value: '₹${value.toStringAsFixed(0)}',
                    valueColor: AppColors.positive,
                    subtitle: 'This month',
                  ),
                  loading: () => const SummaryCard(
                    title: 'Income',
                    value: '—',
                    subtitle: 'Loading...',
                  ),
                  error: (_, __) => const SummaryCard(
                    title: 'Income',
                    value: '—',
                    subtitle: 'Could not load',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: totalSpentAsync.when(
                  data: (value) => SummaryCard(
                    title: 'Expenses',
                    value: '₹${value.toStringAsFixed(0)}',
                    valueColor: AppColors.negative,
                    subtitle: 'This month',
                  ),
                  loading: () => const SummaryCard(
                    title: 'Expenses',
                    value: '—',
                    subtitle: 'Loading...',
                  ),
                  error: (_, __) => const SummaryCard(
                    title: 'Expenses',
                    value: '—',
                    subtitle: 'Could not load',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Upcoming Reminders
          remindersAsync.when(
            data: (reminders) {
              if (reminders.isEmpty) return const SizedBox.shrink();
              final urgent = reminders.where((r) => r.daysUntilDue <= 3).toList();
              if (urgent.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: 'Upcoming Bills',
                    actionLabel: 'View All',
                    onActionTap: () {
                      // Navigate to reminders
                    },
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.notifications_active, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${urgent.length} bill${urgent.length > 1 ? 's' : ''} due soon',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₹${urgent.fold<double>(0, (sum, r) => sum + (r.amount ?? 0)).toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Goals Progress
          goalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) return const SizedBox.shrink();
              final activeGoals = goals.where((g) => !g.isCompleted).toList();
              if (activeGoals.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(title: 'Goal Progress'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: activeGoals.take(2).map((goal) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      goal.name,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
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
                                    value: goal.progressPercentage,
                                    backgroundColor: AppColors.subtleBorder,
                                    color: Color(goal.colorHex),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Budget Overview
          budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SectionHeader(title: 'Budget Overview'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: budgets.take(3).map((budget) {
                          final ratio = budget.spent / budget.monthlyLimit;
                          final isOverBudget = ratio > 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      'Category #${budget.categoryId}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '₹${budget.spent.toStringAsFixed(0)} / ₹${budget.monthlyLimit.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: ratio.clamp(0, 1).toDouble(),
                                    backgroundColor: AppColors.subtleBorder,
                                    color: isOverBudget ? AppColors.negative : AppColors.navy,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Recent Transactions
          const SectionHeader(title: 'Recent Transactions'),
          const SizedBox(height: 12),
          txAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Add your first transaction to start tracking spending.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              final recent = items.take(5).toList();
              return Card(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < recent.length; i++) ...<Widget>[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.navy.withOpacity(0.08),
                          foregroundColor: AppColors.navy,
                          child: Icon(
                            recent[i].isExpense
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ),
                        title: Text('Category #${recent[i].categoryId}'),
                        subtitle: Text(
                          recent[i].note ?? DateFormat('MMM d, yyyy').format(recent[i].date),
                        ),
                        trailing: Text(
                          '${recent[i].isExpense ? '-' : '+'}${recent[i].currency == 'INR' ? '₹' : '\$'}${recent[i].amount.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: recent[i].isExpense
                                        ? AppColors.negative
                                        : AppColors.positive,
                                  ),
                        ),
                      ),
                      if (i != recent.length - 1) const Divider(height: 0),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load transactions'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

