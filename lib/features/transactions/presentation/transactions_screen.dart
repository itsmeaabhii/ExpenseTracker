import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/state/app_providers.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../../features/categories/domain/category.dart';
import '../../../theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class TransactionsTab extends ConsumerStatefulWidget {
  const TransactionsTab({super.key});

  @override
  ConsumerState<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<TransactionsTab> {
  String _searchQuery = '';
  int? _filterCategoryId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  bool? _filterIsExpense;

  @override
  Widget build(BuildContext context) {
    final searchParams = TransactionSearchParams(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      categoryId: _filterCategoryId,
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      isExpense: _filterIsExpense,
    );
    final transactionsAsync = ref.watch(searchTransactionsProvider(searchParams));
    final categoriesAsync = ref.watch(categoryListProvider);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _FilterChip(
                      label: 'All',
                      isSelected: _filterIsExpense == null,
                      onTap: () => setState(() => _filterIsExpense = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Expenses',
                      isSelected: _filterIsExpense == true,
                      onTap: () => setState(() => _filterIsExpense = true),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Income',
                      isSelected: _filterIsExpense == false,
                      onTap: () => setState(() => _filterIsExpense = false),
                    ),
                    const SizedBox(width: 8),
                    categoriesAsync.when(
                      data: (categories) => _FilterChip(
                        label: _filterCategoryId == null
                            ? 'All Categories'
                            : categories.firstWhere((c) => c.id == _filterCategoryId, orElse: () => categories.first).name,
                        isSelected: _filterCategoryId != null,
                        onTap: () => _showCategoryFilter(context, categories),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _filterStartDate == null && _filterEndDate == null
                          ? 'All Time'
                          : 'Date Range',
                      isSelected: _filterStartDate != null || _filterEndDate != null,
                      onTap: () => _showDateFilter(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: transactionsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('No transactions found.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final tx = items[index];
                  return _TransactionTile(tx: tx);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: items.length,
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const Center(
              child: Text('Could not load transactions'),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryFilter(BuildContext context, List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('All Categories'),
              leading: const Icon(Icons.clear_all),
              selected: _filterCategoryId == null,
              onTap: () {
                setState(() => _filterCategoryId = null);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ...categories.map((category) => ListTile(
              title: Text(category.name),
              leading: Icon(IconData(category.iconCode, fontFamily: 'MaterialIcons')),
              selected: _filterCategoryId == category.id,
              onTap: () {
                setState(() => _filterCategoryId = category.id);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showDateFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('All Time'),
              leading: const Icon(Icons.calendar_today),
              onTap: () {
                setState(() {
                  _filterStartDate = null;
                  _filterEndDate = null;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('This Month'),
              leading: const Icon(Icons.today),
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _filterStartDate = DateTime(now.year, now.month, 1);
                  _filterEndDate = DateTime(now.year, now.month + 1, 0);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Last Month'),
              leading: const Icon(Icons.navigate_before),
              onTap: () {
                final now = DateTime.now();
                setState(() {
                  _filterStartDate = DateTime(now.year, now.month - 1, 1);
                  _filterEndDate = DateTime(now.year, now.month, 0);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Custom Range'),
              leading: const Icon(Icons.date_range),
              onTap: () async {
                Navigator.pop(context);
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: _filterStartDate != null && _filterEndDate != null
                      ? DateTimeRange(start: _filterStartDate!, end: _filterEndDate!)
                      : null,
                );
                if (picked != null) {
                  setState(() {
                    _filterStartDate = picked.start;
                    _filterEndDate = picked.end;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? theme.colorScheme.primary : AppColors.navy;
    final unselectedColor = isDark ? theme.colorScheme.surface : AppColors.cardBackground;
    final borderColor = isDark 
        ? (isSelected ? theme.colorScheme.primary : theme.dividerColor)
        : (isSelected ? AppColors.navy : AppColors.subtleBorder);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.tx});

  final TransactionModel tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = tx.isExpense;
    final amountPrefix = isExpense ? '-' : '+';
    final amountColor = isExpense 
        ? (isDark ? const Color(0xFFEF5350) : AppColors.negative)
        : (isDark ? const Color(0xFF66BB6A) : AppColors.positive);
    final currencySymbol = tx.currency == 'INR' ? '₹' : 
                          tx.currency == 'USD' ? '\$' :
                          tx.currency == 'EUR' ? '€' :
                          tx.currency == 'GBP' ? '£' : tx.currency;

    return Card(
      child: InkWell(
        onTap: () => _showTransactionOptions(context, ref),
        child: ListTile(
          leading: tx.receiptPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(tx.receiptPath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              : CircleAvatar(
                  backgroundColor: amountColor.withOpacity(0.1),
                  foregroundColor: amountColor,
                  child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward),
                ),
          title: Text(
            'Category #${tx.categoryId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            tx.note ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '$amountPrefix$currencySymbol${tx.amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                ),
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditTransactionScreen(transaction: tx),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(transactionRepositoryProvider);
              await repo.remove(tx.id);
              ref.invalidate(transactionListProvider);
              ref.invalidate(searchTransactionsProvider);
              ref.invalidate(totalSpentThisMonthProvider);
              ref.invalidate(totalIncomeThisMonthProvider);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.initialIsExpense = true});

  final bool initialIsExpense;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late bool _isExpense;
  DateTime _selectedDate = DateTime.now();
  int _categoryId = 1;
  String _currency = 'INR';
  File? _receiptImage;

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  ];

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _receiptImage = File(picked.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add transaction'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    if (parsed <= 0) {
                      return 'Amount must be positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Date: ${_selectedDate.toLocal().toString().split(' ').first}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _currency,
                  items: _currencies.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['code'],
                      child: Text('${c['symbol']} ${c['name']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currency = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: _receiptImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.file(_receiptImage!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _receiptImage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.secondary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Add Receipt Photo',
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Save transaction',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(transactionRepositoryProvider);
                    final amount =
                        double.parse(_amountController.text.trim());
                    final tx = TransactionModel(
                      id: 0,
                      amount: amount,
                      isExpense: _isExpense,
                      categoryId: _categoryId,
                      date: _selectedDate,
                      note: _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                      currency: _currency,
                      receiptPath: _receiptImage?.path,
                    );
                    await repo.add(tx);

                    ref.invalidate(transactionListProvider);
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

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transaction});

  final TransactionModel transaction;

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late bool _isExpense;
  late DateTime _selectedDate;
  late int _categoryId;
  late String _currency;
  File? _receiptImage;

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'SGD', 'symbol': 'S\$', 'name': 'Singapore Dollar'},
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: tx.amount.toStringAsFixed(0));
    _noteController = TextEditingController(text: tx.note ?? '');
    _isExpense = tx.isExpense;
    _selectedDate = tx.date;
    _categoryId = tx.categoryId;
    _currency = tx.currency;
    if (tx.receiptPath != null) {
      _receiptImage = File(tx.receiptPath!);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _receiptImage = File(picked.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    if (parsed <= 0) {
                      return 'Amount must be positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Date: ${_selectedDate.toLocal().toString().split(' ').first}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _currency,
                  items: _currencies.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['code'],
                      child: Text('${c['symbol']} ${c['name']}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _currency = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: _receiptImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.file(_receiptImage!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _receiptImage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.secondary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Add Receipt Photo',
                                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Update Transaction',
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final repo = ref.read(transactionRepositoryProvider);
                    final amount = double.parse(_amountController.text.trim());
                    final updated = widget.transaction.copyWith(
                      amount: amount,
                      isExpense: _isExpense,
                      categoryId: _categoryId,
                      date: _selectedDate,
                      note: _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                      currency: _currency,
                      receiptPath: _receiptImage?.path,
                    );
                    // Note: Need to add update method to repository
                    await repo.remove(widget.transaction.id);
                    await repo.add(updated);

                    ref.invalidate(transactionListProvider);
                    ref.invalidate(totalSpentThisMonthProvider);
                    ref.invalidate(totalIncomeThisMonthProvider);

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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final repo = ref.read(transactionRepositoryProvider);
              await repo.remove(widget.transaction.id);
              ref.invalidate(transactionListProvider);
              ref.invalidate(totalSpentThisMonthProvider);
              ref.invalidate(totalIncomeThisMonthProvider);
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

