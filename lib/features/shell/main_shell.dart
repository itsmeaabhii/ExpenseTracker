import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../analytics/presentation/analytics_screen.dart';
import '../budgets/presentation/budgets_screen.dart';
import '../categories/presentation/categories_screen.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../export/presentation/export_screen.dart';
import '../goals/presentation/goals_screen.dart';
import '../recurring/presentation/recurring_screen.dart';
import '../reminders/presentation/reminders_screen.dart';
import '../settings/presentation/settings_screen.dart';
import '../transactions/presentation/transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const <Widget>[
    DashboardTab(),
    TransactionsTab(),
    GoalsTab(),
    AnalyticsTab(),
    MoreTab(),
  ];

  String get _title {
    switch (_currentIndex) {
      case 0:
        return 'BudgetBuddy';
      case 1:
        return 'Transactions';
      case 2:
        return 'Savings Goals';
      case 3:
        return 'Analytics';
      case 4:
        return 'More';
      default:
        return 'BudgetBuddy';
    }
  }

  FloatingActionButton? _buildFab(BuildContext context) {
    if (_currentIndex == 1) {
      return FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black 
            : Colors.white,
        elevation: 6,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'More Options',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Access additional features',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        _MenuCard(
          icon: Icons.pie_chart_outline,
          title: 'Budgets',
          subtitle: 'Manage your monthly budgets',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BudgetsTab(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.category_outlined,
          title: 'Categories',
          subtitle: 'Manage transaction categories',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoriesScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.repeat,
          title: 'Recurring Transactions',
          subtitle: 'Set up automatic transaction tracking',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecurringTab(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.notifications_outlined,
          title: 'Bill Reminders',
          subtitle: 'Never miss a payment deadline',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RemindersTab(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.download,
          title: 'Export Data',
          subtitle: 'Export your transactions to CSV',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ExportTab(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MenuCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences and options',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsTab(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? theme.colorScheme.primary : AppColors.navy;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

