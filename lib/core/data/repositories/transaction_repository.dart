import 'package:flutter/foundation.dart';

import '../../../features/transactions/domain/transaction.dart';
import '../app_database.dart';

@immutable
class TransactionRepository {
  const TransactionRepository(this._db);

  final AppDatabase _db;

  Future<List<TransactionModel>> getAll() {
    return _db.getTransactions();
  }

  Future<void> add(TransactionModel tx) async {
    await _db.insertTransaction(tx);
  }

  Future<void> remove(int id) async {
    await _db.deleteTransaction(id);
  }
}

