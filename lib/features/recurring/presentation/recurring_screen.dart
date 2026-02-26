import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/primary_button.dart';
import '../../../core/state/app_providers.dart';
import '../../../features/recurring/domain/recurring_transaction.dart';
import '../../../theme/app_colors.dart';

class RecurringTab extends ConsumerWidget {
  const RecurringTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Recurring Transactions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically track regular income and expenses',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recurringAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No recurring transactions yet.'),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final rt = items[index];
                    return _RecurringCard(rt: rt);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Could not load recurring transactions'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add recurring transaction',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditRecurringScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.rt});

  final RecurringTransactionModel rt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = rt.isExpense;
    final amountPrefix = isExpense ? '-' : '+';
    final amountColor = isExpense ? AppColors.negative : AppColors.positive;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditRecurringScreen(existing: rt),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpense ? 'Expense' : 'Income',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rt.frequency.displayName,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$amountPrefix₹${rt.amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: amountColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                rt.note ?? 'Category #${rt.categoryId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.calendar_today, size: 14, color: AppColors.navyLight),
                  const SizedBox(width: 4),
                  Text(
                    'Next due: ${DateFormat('MMM d, yyyy').format(rt.nextDueDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditRecurringScreen extends ConsumerStatefulWidget {
  const EditRecurringScreen({super.key, this.existing});

  final RecurringTransactionModel? existing;

  @override
  ConsumerState<EditRecurringScreen> createState() => _EditRecurringScreenState();
}

class _EditRecurringScreenState extends ConsumerState<EditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isExpense = true;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  int _categoryId = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(0);
      _noteController.text = existing.note ?? '';
      _isExpense = existing.isExpense;
      _frequency = existing.frequency;
      _categoryId = existing.categoryId;
      _startDate = existing.startDate;
      _endDate = existing.endDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add Recurring' : 'Edit Recurring'),
        actions: existing != null
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete?'),
                        content: const Text('This will stop tracking this recurring transaction.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final repo = ref.read(recurringRepositoryProvider);
                      await repo.remove(existing.id);
                      ref.invalidate(recurringListProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: <bool>{_isExpense},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isExpense = value.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  items: const <DropdownMenuItem<int>>[
                    DropdownMenuItem<int>(
                      value: 1,
                      child: Text('Food & Dining'),
                    ),
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text('Transport'),
                    ),
                    DropdownMenuItem<int>(
                      value: 3,
                      child: Text('Shopping'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _categoryId = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RecurringFrequency>(
                  value: _frequency,
                  items: RecurringFrequency.values.map((f) {
                    return DropdownMenuItem<RecurringFrequency>(
                      value: f,
                      child: Text(f.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _frequency = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g., Netflix Subscription, Salary',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _endDate == null
                            ? 'No end date'
                            : 'End: ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                          });
                        }
                      },
                      child: Text(_endDate == null ? 'Set End Date' : 'Change'),
                    ),
                    if (_endDate != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: existing == null ? 'Create Recurring' : 'Update Recurring',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(recurringRepositoryProvider);
                    final amount = double.parse(_amountController.text.trim());

                    final rt = RecurringTransactionModel(
                      id: existing?.id ?? 0,
                      amount: amount,
                      isExpense: _isExpense,
                      categoryId: _categoryId,
                      note: _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                      frequency: _frequency,
                      startDate: _startDate,
                      endDate: _endDate,
                      nextDueDate: existing?.nextDueDate ?? _startDate,
                      isActive: true,
                    );

                    if (existing == null) {
                      await repo.add(rt);
                    } else {
                      await repo.update(rt);
                    }

                    ref.invalidate(recurringListProvider);

                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
