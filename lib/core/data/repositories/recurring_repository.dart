import 'package:flutter/foundation.dart';

import '../../../features/recurring/domain/recurring_transaction.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../app_database.dart';

@immutable
class RecurringRepository {
  const RecurringRepository(this._db);

  final AppDatabase _db;

  Future<List<RecurringTransactionModel>> getAll() {
    return _db.getRecurringTransactions();
  }

  Future<void> add(RecurringTransactionModel rt) async {
    await _db.insertRecurring(rt);
  }

  Future<void> update(RecurringTransactionModel rt) async {
    await _db.updateRecurring(rt);
  }

  Future<void> remove(int id) async {
    await _db.deleteRecurring(id);
  }

  Future<void> processDueRecurring() async {
    final now = DateTime.now();
    final recurring = await _db.getRecurringTransactions();

    for (final rt in recurring) {
      if (rt.nextDueDate.isBefore(now) || rt.nextDueDate.isAtSameMomentAs(now)) {
        // Create transaction
        final tx = TransactionModel(
          id: 0,
          amount: rt.amount,
          isExpense: rt.isExpense,
          categoryId: rt.categoryId,
          date: rt.nextDueDate,
          note: rt.note,
        );
        await _db.insertTransaction(tx);

        // Update next due date
        final nextDue = rt.calculateNextDueDate();
        final updated = rt.copyWith(nextDueDate: nextDue);
        await _db.updateRecurring(updated);
      }
    }
  }
}
