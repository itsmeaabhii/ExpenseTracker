import 'package:flutter/foundation.dart';

import '../../../features/categories/domain/category.dart';
import '../app_database.dart';

@immutable
class CategoryRepository {
  const CategoryRepository(this._db);

  final AppDatabase _db;

  Future<List<CategoryModel>> getAll() {
    return _db.getCategories();
  }

  Future<void> add(CategoryModel category) async {
    await _db.insertCategory(category);
  }
}

