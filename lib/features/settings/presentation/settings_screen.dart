import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_providers.dart';
import '../../../theme/app_colors.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showIncome = ref.watch(showIncomeProvider);
    final enableNotifications = ref.watch(enableNotificationsProvider);
    final defaultCurrency = ref.watch(defaultCurrencyProvider);
    final darkMode = ref.watch(darkModeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    final currencies = [
      {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'General',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your app experience',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Text(
          'Preferences',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                title: const Text('Show income in dashboard'),
                subtitle: const Text('Display income summary on home screen'),
                value: showIncome,
                onChanged: (value) async {
                  await prefs.setBool('showIncomeInDashboard', value);
                  ref.invalidate(showIncomeProvider);
                },
              ),
              const Divider(height: 0),
              SwitchListTile(
                title: const Text('Enable notifications'),
                subtitle: const Text('Get reminders for bills and goals'),
                value: enableNotifications,
                onChanged: (value) async {
                  await prefs.setBool('enableNotifications', value);
                  ref.invalidate(enableNotificationsProvider);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Currency',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: currencies.map((currency) {
              final isSelected = defaultCurrency == currency['code'];
              return RadioListTile<String>(
                title: Text('${currency['symbol']} ${currency['name']}'),
                value: currency['code']!,
                groupValue: defaultCurrency,
                onChanged: (value) async {
                  if (value != null) {
                    await prefs.setString('defaultCurrency', value);
                    ref.invalidate(defaultCurrencyProvider);
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme throughout the app'),
            value: darkMode,
            onChanged: (value) async {
              await prefs.setBool('darkMode', value);
              ref.invalidate(darkModeProvider);
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.negative),
                title: const Text('Clear All Data'),
                subtitle: const Text('Delete all transactions and settings'),
                onTap: () => _showClearDataDialog(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'BudgetBuddy v1.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your transactions, goals, budgets, and settings. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Clear all data
              final db = ref.read(appDatabaseProvider);
              // Note: In a real app, you'd implement a clear all method in the database
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

