import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/widgets/primary_button.dart';
import '../../../core/state/app_providers.dart';
import '../../../features/goals/domain/goal.dart';
import '../../../theme/app_colors.dart';

class GoalsTab extends ConsumerWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Expanded(
            child: goalsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No savings goals yet. Create one to start tracking!'),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final goal = items[index];
                    return _GoalCard(goal: goal);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: items.length,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Could not load goals'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add savings goal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditGoalScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.progressPercentage;
    final isCompleted = goal.isCompleted;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditGoalScreen(existing: goal),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(goal.colorHex).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconData(goal.iconCode, fontFamily: 'MaterialIcons'),
                      color: Color(goal.colorHex),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (goal.deadline != null)
                          Text(
                            'Due: ${_formatDate(goal.deadline!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.check_circle, color: AppColors.positive, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Done!',
                            style: TextStyle(
                              color: AppColors.positive,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.subtleBorder,
                  color: isCompleted ? AppColors.positive : AppColors.navy,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '₹${goal.savedAmount.toStringAsFixed(0)} saved',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'of ₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (!isCompleted) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddSavingsDialog(context, ref, goal),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Savings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddSavingsDialog(BuildContext context, WidgetRef ref, GoalModel goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Savings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                final repo = ref.read(goalRepositoryProvider);
                await repo.addToSavings(goal.id, amount);
                ref.invalidate(goalListProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class EditGoalScreen extends ConsumerStatefulWidget {
  const EditGoalScreen({super.key, this.existing});

  final GoalModel? existing;

  @override
  ConsumerState<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends ConsumerState<EditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _deadline;
  int _selectedIcon = 0xe8f6;
  int _selectedColor = 0xFF0B3C5D;

  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': 0xe8f6, 'name': 'Savings'},
    {'icon': 0xe19f, 'name': 'Car'},
    {'icon': 0xe587, 'name': 'Home'},
    {'icon': 0xe3c6, 'name': 'Travel'},
    {'icon': 0xe30a, 'name': 'Education'},
    {'icon': 0xe3e0, 'name': 'Gift'},
    {'icon': 0xe3c3, 'name': 'Emergency'},
    {'icon': 0xe263, 'name': 'Investment'},
  ];

  final List<int> _colorOptions = [
    0xFF0B3C5D,
    0xFF2E8B57,
    0xFF32689B,
    0xFFE67E22,
    0xFF9B59B6,
    0xFFE74C3C,
    0xFF1ABC9C,
    0xFF34495E,
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _targetController.text = existing.targetAmount.toStringAsFixed(0);
      _deadline = existing.deadline;
      _selectedIcon = existing.iconCode;
      _selectedColor = existing.colorHex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add Goal' : 'Edit Goal'),
        actions: existing != null
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Goal?'),
                        content: const Text('This action cannot be undone.'),
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
                      final repo = ref.read(goalRepositoryProvider);
                      await repo.remove(existing.id);
                      ref.invalidate(goalListProvider);
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    hintText: 'e.g., New Car, Vacation',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a goal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₹',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a target amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _deadline == null
                            ? 'No deadline set'
                            : 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _deadline ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _deadline = picked;
                          });
                        }
                      },
                      child: Text(_deadline == null ? 'Set Deadline' : 'Change'),
                    ),
                    if (_deadline != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _deadline = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose Icon',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _iconOptions.map((option) {
                    final isSelected = _selectedIcon == option['icon'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIcon = option['icon'];
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.navy.withOpacity(0.1)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.navy, width: 2)
                              : null,
                        ),
                        child: Icon(
                          IconData(option['icon'], fontFamily: 'MaterialIcons'),
                          color: isSelected ? AppColors.navy : AppColors.navyLight,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose Color',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor == color;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(color),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: Color(color).withOpacity(0.5), blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: existing == null ? 'Create Goal' : 'Update Goal',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(goalRepositoryProvider);
                    final target = double.parse(_targetController.text.trim());
                    
                    final goal = GoalModel(
                      id: existing?.id ?? 0,
                      name: _nameController.text.trim(),
                      targetAmount: target,
                      savedAmount: existing?.savedAmount ?? 0,
                      deadline: _deadline,
                      iconCode: _selectedIcon,
                      colorHex: _selectedColor,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing == null) {
                      await repo.add(goal);
                    } else {
                      await repo.update(goal);
                    }

                    ref.invalidate(goalListProvider);

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
