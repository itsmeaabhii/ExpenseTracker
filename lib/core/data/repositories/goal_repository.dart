import 'package:flutter/foundation.dart';

import '../../../features/goals/domain/goal.dart';
import '../app_database.dart';

@immutable
class GoalRepository {
  const GoalRepository(this._db);

  final AppDatabase _db;

  Future<List<GoalModel>> getAll() {
    return _db.getGoals();
  }

  Future<void> add(GoalModel goal) async {
    await _db.insertGoal(goal);
  }

  Future<void> update(GoalModel goal) async {
    await _db.updateGoal(goal);
  }

  Future<void> remove(int id) async {
    await _db.deleteGoal(id);
  }

  Future<void> addToSavings(int goalId, double amount) async {
    final goals = await _db.getGoals();
    final goal = goals.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(savedAmount: goal.savedAmount + amount);
    await _db.updateGoal(updated);
  }
}
