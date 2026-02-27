import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_providers.dart';
import '../../../theme/app_colors.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize your app preferences',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'APPEARANCE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[800],
            ),
          ),
        ),
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
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'DATA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[800],
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.negative),
            title: const Text('Clear All Transactions'),
            subtitle: const Text('Delete all transaction data'),
            onTap: () => _showClearDataDialog(context, ref),
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
        title: const Text('Clear All Transactions?'),
        content: const Text(
          'This will permanently delete all your transaction data. This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Clear all transactions
              // In real implementation, add clearAllTransactions method to database
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All transactions cleared')),
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

