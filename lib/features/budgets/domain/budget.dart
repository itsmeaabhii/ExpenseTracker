import 'package:flutter/foundation.dart';

/// Represents a budget for a specific category with spending tracking
@immutable
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.monthlyLimit,
    required this.spent,
  });

  final int id;
  final int categoryId;
  final double monthlyLimit;
  final double spent;

  /// Returns the remaining budget amount
  double get remaining => monthlyLimit - spent;

  /// Returns true if the budget has been exceeded
  bool get isOverBudget => spent > monthlyLimit;

  BudgetModel copyWith({
    int? id,
    int? categoryId,
    double? monthlyLimit,
    double? spent,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      spent: spent ?? this.spent,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'category_id': categoryId,
      'monthly_limit': monthlyLimit,
      'spent': spent,
    };
  }

  static BudgetModel fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      spent: (map['spent'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, monthlyLimit: $monthlyLimit, spent: $spent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.monthlyLimit == monthlyLimit &&
        other.spent == spent;
  }

  @override
  int get hashCode {
    return Object.hash(id, categoryId, monthlyLimit, spent);
  }
}

