import 'package:flutter/foundation.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  String get value => name;

  static RecurringFrequency fromString(String value) {
    return RecurringFrequency.values.firstWhere(
      (f) => f.name == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

@immutable
class RecurringTransactionModel {
  const RecurringTransactionModel({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.categoryId,
    this.note,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    required this.isActive,
  });

  final int id;
  final double amount;
  final bool isExpense;
  final int categoryId;
  final String? note;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringTransactionModel copyWith({
    int? id,
    double? amount,
    bool? isExpense,
    int? categoryId,
    String? note,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'category_id': categoryId,
      'note': note,
      'frequency': frequency.value,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  static RecurringTransactionModel fromMap(Map<String, Object?> map) {
    return RecurringTransactionModel(
      id: map['id'] as int,
      amount: (map['amount'] as num).toDouble(),
      isExpense: (map['is_expense'] as int) == 1,
      categoryId: map['category_id'] as int,
      note: map['note'] as String?,
      frequency: RecurringFrequency.fromString(map['frequency'] as String),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: map['end_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int)
          : null,
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date'] as int),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  DateTime calculateNextDueDate() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextDueDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case RecurringFrequency.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
    }
  }
}
