import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/reminder_repository.dart';
import '../../../features/budgets/domain/budget.dart';
import '../../../features/categories/domain/category.dart';
import '../../../features/transactions/domain/transaction.dart';
import '../../../features/goals/domain/goal.dart';
import '../../../features/recurring/domain/recurring_transaction.dart';
import '../../../features/reminders/domain/reminder.dart';

// Settings Provider - using AsyncNotifier for better state management
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in ProviderScope overrides');
});

// Simple settings using Provider for each setting (re-reads when invalidated)
final showIncomeProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('showIncomeInDashboard') ?? true;
});

final enableNotificationsProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('enableNotifications') ?? true;
});

final defaultCurrencyProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('defaultCurrency') ?? 'INR';
});

final darkModeProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('darkMode') ?? true; // Default to dark mode
});

// Core database + repositories

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(appDatabaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(appDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(appDatabaseProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(appDatabaseProvider));
});

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(appDatabaseProvider));
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(ref.watch(appDatabaseProvider));
});

// Entity lists

final transactionListProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAll();
});

final budgetListProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getAll();
});

final categoryListProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

// Summaries

final totalSpentThisMonthProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return db.getTotalSpentForMonth(now);
});

final totalIncomeThisMonthProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return db.getTotalIncomeForMonth(now);
});

final spendingByCategoryProvider = FutureProvider<Map<String, double>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  return db.getSpendingByCategory(now);
});

final goalListProvider = FutureProvider<List<GoalModel>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getAll();
});

final recurringListProvider = FutureProvider<List<RecurringTransactionModel>>((ref) async {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.getAll();
});

final reminderListProvider = FutureProvider<List<ReminderModel>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getAll();
});

final upcomingRemindersProvider = FutureProvider<List<ReminderModel>>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getUpcoming();
});

// Search provider (family for parameters)
final searchTransactionsProvider = FutureProvider.family<List<TransactionModel>, TransactionSearchParams>((ref, params) async {
  final db = ref.watch(appDatabaseProvider);
  return db.searchTransactions(
    query: params.query,
    categoryId: params.categoryId,
    startDate: params.startDate,
    endDate: params.endDate,
    isExpense: params.isExpense,
  );
});

class TransactionSearchParams {
  const TransactionSearchParams({
    this.query,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.isExpense,
  });

  final String? query;
  final int? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isExpense;
}

