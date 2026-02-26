import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/primary_button.dart';
import '../../../core/state/app_providers.dart';
import '../../../features/budgets/domain/budget.dart';
import '../../../theme/app_colors.dart';

class BudgetsTab extends ConsumerWidget {
  const BudgetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Expanded(
            child: budgetsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No budgets yet.'),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final budget = items[index];
                    final ratio = budget.spent / budget.monthlyLimit;
                    final clamped = ratio.clamp(0, 1).toDouble();

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                EditBudgetScreen(existing: budget),
                          ),
                        );
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Category #${budget.categoryId}',
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: clamped,
                                backgroundColor: AppColors.subtleBorder,
                                color: AppColors.navy,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${budget.spent.toStringAsFixed(0)} of ₹${budget.monthlyLimit.toStringAsFixed(0)}',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Could not load budgets'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add budget',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditBudgetScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EditBudgetScreen extends ConsumerStatefulWidget {
  const EditBudgetScreen({super.key, this.existing});

  final BudgetModel? existing;

  @override
  ConsumerState<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends ConsumerState<EditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int _categoryId = 1;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _amountController.text = existing.monthlyLimit.toStringAsFixed(0);
      _categoryId = existing.categoryId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add budget' : 'Edit budget'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _categoryId = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly limit',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a monthly limit';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                PrimaryButton(
                  label: existing == null ? 'Save budget' : 'Update budget',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(budgetRepositoryProvider);
                    final limit =
                        double.parse(_amountController.text.trim());
                    final budget = BudgetModel(
                      id: existing?.id ?? 0,
                      categoryId: _categoryId,
                      monthlyLimit: limit,
                      spent: existing?.spent ?? 0,
                    );
                    await repo.upsert(budget);

                    ref.invalidate(budgetListProvider);
                    ref.invalidate(totalSpentThisMonthProvider);

                    if (!mounted) {
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

