import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../../core/state/app_providers.dart';
import '../../../theme/app_colors.dart';

final exportDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final transactions = await db.getAllTransactionsForExport();
  final categories = await db.getCategories();
  
  final categoryMap = {for (var c in categories) c.id: c.name};
  
  return transactions.map((tx) => {
    'Date': DateFormat('yyyy-MM-dd').format(tx.date),
    'Type': tx.isExpense ? 'Expense' : 'Income',
    'Category': categoryMap[tx.categoryId] ?? 'Unknown',
    'Amount': tx.amount.toStringAsFixed(2),
    'Currency': tx.currency,
    'Note': tx.note ?? '',
  }).toList();
});

class ExportTab extends ConsumerWidget {
  const ExportTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportDataAsync = ref.watch(exportDataProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Export Data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Export your transactions for backup or analysis',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.table_chart, color: AppColors.navy),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'CSV Export',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Export all transactions as a CSV file',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  exportDataAsync.when(
                    data: (data) {
                      return Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(Icons.numbers, size: 16, color: AppColors.navyLight),
                              const SizedBox(width: 8),
                              Text(
                                '${data.length} transactions',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _exportToCSV(context, data),
                              icon: const Icon(Icons.download),
                              label: const Text('Export to CSV'),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Could not load data'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.positive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.share, color: AppColors.positive),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Share Data',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'Share your transactions via email or messaging apps',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  exportDataAsync.when(
                    data: (data) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareCSV(context, data),
                          icon: const Icon(Icons.share),
                          label: const Text('Share CSV'),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Export Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: exportDataAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Text('No transactions to export'),
                  );
                }
                return Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: data.length.clamp(0, 10),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return ListTile(
                        dense: true,
                        title: Text('${item['Category']} - ${item['Type']}'),
                        subtitle: Text('${item['Date']}'),
                        trailing: Text(
                          '${item['Currency']} ${item['Amount']}',
                          style: TextStyle(
                            color: item['Type'] == 'Expense'
                                ? AppColors.negative
                                : AppColors.positive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load preview')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      final rows = <List<dynamic>>[
        data.first.keys.toList(),
        ...data.map((row) => row.values.toList()),
      ];
      final csvData = _convertToCSV(rows);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  String _convertToCSV(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final cellStr = cell.toString();
        if (cellStr.contains(',') || cellStr.contains('"') || cellStr.contains('\n')) {
          return '"${cellStr.replaceAll('"', '""')}"';
        }
        return cellStr;
      }).join(',');
    }).join('\n');
  }

  Future<void> _shareCSV(BuildContext context, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to share')),
      );
      return;
    }

    try {
      final rows = <List<dynamic>>[
        data.first.keys.toList(),
        ...data.map((row) => row.values.toList()),
      ];
      final csvData = _convertToCSV(rows);

      final directory = await getTemporaryDirectory();
      final fileName = 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My BudgetBuddy Transactions',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }
}
