import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/primary_button.dart';
import '../../../core/state/app_providers.dart';
import '../../../features/reminders/domain/reminder.dart';
import '../../../theme/app_colors.dart';

class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Bill Reminders',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Never miss a payment deadline',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: remindersAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No reminders yet. Add bills to get notified!'),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final reminder = items[index];
                    return _ReminderCard(reminder: reminder);
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: items.length,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Center(
                child: Text('Could not load reminders'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Add bill reminder',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditReminderScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.reminder});

  final ReminderModel reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = reminder.isOverdue;
    final daysUntil = reminder.daysUntilDue;

    Color statusColor = AppColors.navy;
    String statusText;
    IconData statusIcon;

    if (reminder.isPaid) {
      statusColor = AppColors.positive;
      statusText = 'Paid';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = AppColors.negative;
      statusText = 'Overdue';
      statusIcon = Icons.warning;
    } else if (daysUntil <= 3) {
      statusColor = Colors.orange;
      statusText = daysUntil == 0 ? 'Due today' : '$daysUntil days left';
      statusIcon = Icons.access_time;
    } else {
      statusText = '$daysUntil days left';
      statusIcon = Icons.calendar_today;
    }

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditReminderScreen(existing: reminder),
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
                  Expanded(
                    child: Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reminder.description != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  reminder.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(Icons.event, size: 16, color: AppColors.navyLight),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(reminder.dueDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (reminder.amount != null) ...<Widget>[
                    const SizedBox(width: 16),
                    Icon(Icons.account_balance_wallet, size: 16, color: AppColors.navyLight),
                    const SizedBox(width: 4),
                    Text(
                      '₹${reminder.amount!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
              if (!reminder.isPaid) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final repo = ref.read(reminderRepositoryProvider);
                          await repo.markAsPaid(reminder.id);
                          ref.invalidate(reminderListProvider);
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Mark as Paid'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.positive,
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
}

class EditReminderScreen extends ConsumerStatefulWidget {
  const EditReminderScreen({super.key, this.existing});

  final ReminderModel? existing;

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description ?? '';
      if (existing.amount != null) {
        _amountController.text = existing.amount!.toStringAsFixed(0);
      }
      _dueDate = existing.dueDate;
      _isPaid = existing.isPaid;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Add Reminder' : 'Edit Reminder'),
        actions: existing != null
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Reminder?'),
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
                      final repo = ref.read(reminderRepositoryProvider);
                      await repo.remove(existing.id);
                      ref.invalidate(reminderListProvider);
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Electricity Bill, Rent',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (optional)',
                    prefixText: '₹',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Due Date: ${DateFormat('MMM d, yyyy').format(_dueDate)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _dueDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                if (existing != null) ...<Widget>[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark as Paid'),
                    value: _isPaid,
                    onChanged: (value) {
                      setState(() {
                        _isPaid = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: existing == null ? 'Create Reminder' : 'Update Reminder',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(reminderRepositoryProvider);
                    final amount = _amountController.text.isEmpty
                        ? null
                        : double.tryParse(_amountController.text.trim());

                    final reminder = ReminderModel(
                      id: existing?.id ?? 0,
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                      dueDate: _dueDate,
                      isPaid: _isPaid,
                      amount: amount,
                      categoryId: null,
                      notificationId: null,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    if (existing == null) {
                      await repo.add(reminder);
                    } else {
                      await repo.update(reminder);
                    }

                    ref.invalidate(reminderListProvider);

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
