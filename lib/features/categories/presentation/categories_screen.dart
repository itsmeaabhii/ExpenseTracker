import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_providers.dart';
import '../../../features/categories/domain/category.dart';
import '../../../theme/app_colors.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onEdit: () => _showEditCategoryDialog(context, ref, category),
                onDelete: () => _showDeleteCategoryDialog(context, ref, category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load categories')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        onSave: (name, iconCode, colorHex) async {
          final repo = ref.read(categoryRepositoryProvider);
          final category = CategoryModel(
            id: 0,
            name: name,
            iconCode: iconCode,
            colorHex: colorHex,
          );
          await repo.add(category);
          ref.invalidate(categoryListProvider);
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        category: category,
        onSave: (name, iconCode, colorHex) async {
          final repo = ref.read(categoryRepositoryProvider);
          final updated = category.copyWith(
            name: name,
            iconCode: iconCode,
            colorHex: colorHex,
          );
          await repo.add(updated);
          ref.invalidate(categoryListProvider);
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, WidgetRef ref, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Note: Need to implement delete in repository
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.negative),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(category.colorHex).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconData(category.iconCode, fontFamily: 'MaterialIcons'),
            color: Color(category.colorHex),
          ),
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppColors.negative),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({
    this.category,
    required this.onSave,
  });

  final CategoryModel? category;
  final Function(String name, int iconCode, int colorHex) onSave;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameController;
  late int _selectedIcon;
  late int _selectedColor;

  final List<Map<String, dynamic>> _iconOptions = [
    {'icon': 0xe57a, 'name': 'Food'},
    {'icon': 0xe530, 'name': 'Transport'},
    {'icon': 0xe59c, 'name': 'Shopping'},
    {'icon': 0xe3c6, 'name': 'Entertainment'},
    {'icon': 0xe3f8, 'name': 'Health'},
    {'icon': 0xe30a, 'name': 'Education'},
    {'icon': 0xe3e0, 'name': 'Gifts'},
    {'icon': 0xe263, 'name': 'Investment'},
    {'icon': 0xe19f, 'name': 'Car'},
    {'icon': 0xe587, 'name': 'Home'},
    {'icon': 0xe8f6, 'name': 'Savings'},
    {'icon': 0xe3c3, 'name': 'Bills'},
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
    0xFF3498DB,
    0xFF95A5A6,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.iconCode ?? _iconOptions[0]['icon'];
    _selectedColor = widget.category?.colorHex ?? _colorOptions[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            const SizedBox(height: 16),
            Text('Choose Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((option) {
                final isSelected = _selectedIcon == option['icon'];
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = option['icon']),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navy.withOpacity(0.1) : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: AppColors.navy) : null,
                    ),
                    child: Icon(
                      IconData(option['icon'], fontFamily: 'MaterialIcons'),
                      color: isSelected ? AppColors.navy : AppColors.navyLight,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Choose Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(_nameController.text, _selectedIcon, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
