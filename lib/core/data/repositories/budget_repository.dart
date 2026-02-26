import 'package:flutter/foundation.dart';

import '../../../features/budgets/domain/budget.dart';
import '../app_database.dart';

@immutable
class BudgetRepository {
  const BudgetRepository(this._db);

  final AppDatabase _db;

  Future<List<BudgetModel>> getAll() {
    return _db.getBudgets();
  }

  Future<void> upsert(BudgetModel budget) async {
    await _db.upsertBudget(budget);
  }
}

