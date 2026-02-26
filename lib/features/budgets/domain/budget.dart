import 'package:flutter/foundation.dart';

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
}

