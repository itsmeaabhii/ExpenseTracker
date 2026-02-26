import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../features/budgets/domain/budget.dart';
import '../../../features/categories/domain/category.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../../features/goals/domain/goal.dart';
import '../../../features/recurring/domain/recurring_transaction.dart';
import '../../../features/reminders/domain/reminder.dart';

// Conditional import - only import path_provider on non-web platforms
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'app_database_web_stub.dart';

class AppDatabase {
  Database? _db;
  
  // Web in-memory storage
  final Map<int, TransactionModel> _webTransactions = {};
  final Map<int, CategoryModel> _webCategories = {};
  final Map<int, BudgetModel> _webBudgets = {};
  final Map<int, GoalModel> _webGoals = {};
  final Map<int, RecurringTransactionModel> _webRecurring = {};
  final Map<int, ReminderModel> _webReminders = {};
  int _nextTransactionId = 1;
  int _nextCategoryId = 1;
  int _nextBudgetId = 1;
  int _nextGoalId = 1;
  int _nextRecurringId = 1;
  int _nextReminderId = 1;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database not supported on web');
    }
    
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final db = await _openDatabase();
    _db = db;
    return db;
  }

  Future<Database> _openDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Database not supported on web');
    }
    
    // For mobile/desktop, use sqflite normally
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'budget_buddy.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createGoalsTable(db);
          await _createRecurringTable(db);
          await _createRemindersTable(db);
          await _addCurrencyToTransactions(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await _createCategoriesTable(db);
    await _createBudgetsTable(db);
    await _createTransactionsTable(db);
    await _createGoalsTable(db);
    await _createRecurringTable(db);
    await _createRemindersTable(db);
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_hex INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createBudgetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        monthly_limit REAL NOT NULL,
        spent REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        currency TEXT DEFAULT 'INR',
        receipt_path TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  Future<void> _createGoalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0,
        deadline INTEGER,
        icon_code INTEGER DEFAULT 0xe8f6,
        color_hex INTEGER DEFAULT 0xFF0B3C5D,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createRecurringTable(Database db) async {
    await db.execute('''
      CREATE TABLE recurring_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT,
        frequency TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        next_due_date INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
  }

  Future<void> _createRemindersTable(Database db) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date INTEGER NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        amount REAL,
        category_id INTEGER,
        notification_id INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _addCurrencyToTransactions(Database db) async {
    await db.execute('ALTER TABLE transactions ADD COLUMN currency TEXT DEFAULT \'INR\'');
    await db.execute('ALTER TABLE transactions ADD COLUMN receipt_path TEXT');
  }

  // Transactions
  Future<int> insertTransaction(TransactionModel tx) async {
    if (kIsWeb) {
      final id = _nextTransactionId++;
      _webTransactions[id] = tx.copyWith(id: id);
      return id;
    }
    
    final db = await database;
    final map = tx.toMap()..remove('id');
    return db.insert('transactions', map);
  }

  Future<List<TransactionModel>> getTransactions() async {
    if (kIsWeb) {
      final list = _webTransactions.values.toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<void> deleteTransaction(int id) async {
    if (kIsWeb) {
      _webTransactions.remove(id);
      return;
    }
    
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: <Object>[id]);
  }

  // Budgets
  Future<int> upsertBudget(BudgetModel budget) async {
    if (kIsWeb) {
      if (budget.id == 0) {
        final id = _nextBudgetId++;
        _webBudgets[id] = budget.copyWith(id: id);
        return id;
      }
      _webBudgets[budget.id] = budget;
      return budget.id;
    }
    
    final db = await database;
    if (budget.id == 0) {
      final map = budget.toMap()..remove('id');
      return db.insert('budgets', map);
    }
    return db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[budget.id],
    );
  }

  Future<List<BudgetModel>> getBudgets() async {
    if (kIsWeb) {
      return _webBudgets.values.toList();
    }
    
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map(BudgetModel.fromMap).toList();
  }

  // Categories
  Future<int> insertCategory(CategoryModel category) async {
    if (kIsWeb) {
      final id = _nextCategoryId++;
      _webCategories[id] = category.copyWith(id: id);
      return id;
    }
    
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getCategories() async {
    if (kIsWeb) {
      if (_webCategories.isEmpty) {
        return _seedDefaultCategoriesWeb();
      }
      return _webCategories.values.toList();
    }
    
    final db = await database;
    final maps = await db.query('categories');
    if (maps.isEmpty) {
      return _seedDefaultCategories(db);
    }
    return maps.map(CategoryModel.fromMap).toList();
  }
  
  List<CategoryModel> _seedDefaultCategoriesWeb() {
    const defaults = <CategoryModel>[
      CategoryModel(
        id: 1,
        name: 'Food & Dining',
        iconCode: 0xe57a,
        colorHex: 0xFF0B3C5D,
      ),
      CategoryModel(
        id: 2,
        name: 'Transport',
        iconCode: 0xe530,
        colorHex: 0xFF32689B,
      ),
      CategoryModel(
        id: 3,
        name: 'Shopping',
        iconCode: 0xe59c,
        colorHex: 0xFF0B3C5D,
      ),
    ];
    
    for (final c in defaults) {
      _webCategories[c.id] = c;
    }
    _nextCategoryId = 4;
    
    return defaults.toList();
  }

  Future<List<CategoryModel>> _seedDefaultCategories(Database db) async {
    const defaults = <CategoryModel>[
      CategoryModel(
        id: 1,
        name: 'Food & Dining',
        iconCode: 0xe57a,
        colorHex: 0xFF0B3C5D,
      ),
      CategoryModel(
        id: 2,
        name: 'Transport',
        iconCode: 0xe530,
        colorHex: 0xFF32689B,
      ),
      CategoryModel(
        id: 3,
        name: 'Shopping',
        iconCode: 0xe59c,
        colorHex: 0xFF0B3C5D,
      ),
    ];

    for (final c in defaults) {
      await db.insert(
        'categories',
        c.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final rows = await db.query('categories');
    return rows.map(CategoryModel.fromMap).toList();
  }

  // Aggregations
  Future<double> getTotalSpentForMonth(DateTime month) async {
    if (kIsWeb) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      
      double total = 0;
      for (final tx in _webTransactions.values) {
        if (tx.isExpense && 
            tx.date.isAfter(start.subtract(const Duration(days: 1))) && 
            tx.date.isBefore(end)) {
          total += tx.amount;
        }
      }
      return total;
    }
    
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE is_expense = 1 AND date >= ? AND date < ?
      ''',
      <Object>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    final value = result.first['total'] as num?;
    return (value ?? 0).toDouble();
  }

  Future<double> getTotalIncomeForMonth(DateTime month) async {
    if (kIsWeb) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      
      double total = 0;
      for (final tx in _webTransactions.values) {
        if (!tx.isExpense && 
            tx.date.isAfter(start.subtract(const Duration(days: 1))) && 
            tx.date.isBefore(end)) {
          total += tx.amount;
        }
      }
      return total;
    }
    
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE is_expense = 0 AND date >= ? AND date < ?
      ''',
      <Object>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    final value = result.first['total'] as num?;
    return (value ?? 0).toDouble();
  }

  Future<Map<String, double>> getSpendingByCategory(DateTime month) async {
    if (kIsWeb) {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 1);
      
      final Map<String, double> spending = {};
      for (final tx in _webTransactions.values) {
        if (tx.isExpense && 
            tx.date.isAfter(start.subtract(const Duration(days: 1))) && 
            tx.date.isBefore(end)) {
          final category = _webCategories[tx.categoryId]?.name ?? 'Unknown';
          spending[category] = (spending[category] ?? 0) + tx.amount;
        }
      }
      return spending;
    }
    
    final db = await database;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT c.name as category, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.is_expense = 1 AND t.date >= ? AND t.date < ?
      GROUP BY t.category_id
      ''',
      <Object>[
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return Map<String, double>.fromEntries(
      result.map((row) => MapEntry(
        row['category'] as String,
        (row['total'] as num).toDouble(),
      )),
    );
  }

  // Goals
  Future<int> insertGoal(GoalModel goal) async {
    if (kIsWeb) {
      final id = _nextGoalId++;
      _webGoals[id] = goal.copyWith(id: id);
      return id;
    }
    final db = await database;
    final map = goal.toMap()..remove('id');
    return db.insert('goals', map);
  }

  Future<List<GoalModel>> getGoals() async {
    if (kIsWeb) {
      final goals = _webGoals.values.toList();
      goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return goals;
    }
    final db = await database;
    final maps = await db.query('goals', orderBy: 'created_at DESC');
    return maps.map(GoalModel.fromMap).toList();
  }

  Future<void> updateGoal(GoalModel goal) async {
    if (kIsWeb) {
      _webGoals[goal.id] = goal;
      return;
    }
    final db = await database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[goal.id],
    );
  }

  Future<void> deleteGoal(int id) async {
    if (kIsWeb) {
      _webGoals.remove(id);
      return;
    }
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: <Object>[id]);
  }

  // Recurring Transactions
  Future<int> insertRecurring(RecurringTransactionModel rt) async {
    if (kIsWeb) {
      final id = _nextRecurringId++;
      _webRecurring[id] = rt.copyWith(id: id);
      return id;
    }
    final db = await database;
    final map = rt.toMap()..remove('id');
    return db.insert('recurring_transactions', map);
  }

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    if (kIsWeb) {
      final recurring = _webRecurring.values.where((rt) => rt.isActive).toList();
      recurring.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return recurring;
    }
    final db = await database;
    final maps = await db.query(
      'recurring_transactions',
      where: 'is_active = ?',
      whereArgs: <Object>[1],
      orderBy: 'next_due_date ASC',
    );
    return maps.map(RecurringTransactionModel.fromMap).toList();
  }

  Future<void> updateRecurring(RecurringTransactionModel rt) async {
    if (kIsWeb) {
      _webRecurring[rt.id] = rt;
      return;
    }
    final db = await database;
    await db.update(
      'recurring_transactions',
      rt.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[rt.id],
    );
  }

  Future<void> deleteRecurring(int id) async {
    if (kIsWeb) {
      _webRecurring.remove(id);
      return;
    }
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: <Object>[id]);
  }

  // Reminders
  Future<int> insertReminder(ReminderModel reminder) async {
    if (kIsWeb) {
      final id = _nextReminderId++;
      _webReminders[id] = reminder.copyWith(id: id);
      return id;
    }
    final db = await database;
    final map = reminder.toMap()..remove('id');
    return db.insert('reminders', map);
  }

  Future<List<ReminderModel>> getReminders() async {
    if (kIsWeb) {
      final reminders = _webReminders.values.toList();
      reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return reminders;
    }
    final db = await database;
    final maps = await db.query(
      'reminders',
      orderBy: 'due_date ASC',
    );
    return maps.map(ReminderModel.fromMap).toList();
  }

  Future<List<ReminderModel>> getUpcomingReminders() async {
    if (kIsWeb) {
      final now = DateTime.now();
      final reminders = _webReminders.values
          .where((r) => !r.isPaid && r.dueDate.isAfter(now))
          .toList();
      reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return reminders;
    }
    final db = await database;
    final now = DateTime.now();
    final maps = await db.query(
      'reminders',
      where: 'is_paid = ? AND due_date >= ?',
      whereArgs: <Object>[0, now.millisecondsSinceEpoch],
      orderBy: 'due_date ASC',
    );
    return maps.map(ReminderModel.fromMap).toList();
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (kIsWeb) {
      _webReminders[reminder.id] = reminder;
      return;
    }
    final db = await database;
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[reminder.id],
    );
  }

  Future<void> deleteReminder(int id) async {
    if (kIsWeb) {
      _webReminders.remove(id);
      return;
    }
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: <Object>[id]);
  }

  // Search and Filter
  Future<List<TransactionModel>> searchTransactions({
    String? query,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isExpense,
  }) async {
    if (kIsWeb) {
      var results = _webTransactions.values.toList();
      
      if (query != null && query.isNotEmpty) {
        results = results.where((tx) {
          final note = tx.note?.toLowerCase() ?? '';
          final amount = tx.amount.toString();
          final q = query.toLowerCase();
          return note.contains(q) || amount.contains(q);
        }).toList();
      }
      
      if (categoryId != null) {
        results = results.where((tx) => tx.categoryId == categoryId).toList();
      }
      
      if (startDate != null) {
        results = results.where((tx) => 
          tx.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
      }
      
      if (endDate != null) {
        results = results.where((tx) => tx.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }
      
      if (isExpense != null) {
        results = results.where((tx) => tx.isExpense == isExpense).toList();
      }
      
      results.sort((a, b) => b.date.compareTo(a.date));
      return results;
    }
    
    final db = await database;
    
    String whereClause = '1=1';
    final List<Object> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause += ' AND (note LIKE ? OR amount LIKE ?)';
      whereArgs.add('%$query%');
      whereArgs.add('%$query%');
    }

    if (categoryId != null) {
      whereClause += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (isExpense != null) {
      whereClause += ' AND is_expense = ?';
      whereArgs.add(isExpense ? 1 : 0);
    }

    final maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  // Export
  Future<List<TransactionModel>> getAllTransactionsForExport() async {
    if (kIsWeb) {
      final list = _webTransactions.values.toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }
}

