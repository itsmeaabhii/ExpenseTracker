import 'package:flutter/foundation.dart';

@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.isExpense,
    required this.categoryId,
    required this.date,
    this.note,
    this.currency = 'INR',
    this.receiptPath,
  });

  final int id;
  final double amount;
  final bool isExpense;
  final int categoryId;
  final DateTime date;
  final String? note;
  final String currency;
  final String? receiptPath;

  TransactionModel copyWith({
    int? id,
    double? amount,
    bool? isExpense,
    int? categoryId,
    DateTime? date,
    String? note,
    String? currency,
    String? receiptPath,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      isExpense: isExpense ?? this.isExpense,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'amount': amount,
      'is_expense': isExpense ? 1 : 0,
      'category_id': categoryId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'currency': currency,
      'receipt_path': receiptPath,
    };
  }

  static TransactionModel fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int,
      amount: (map['amount'] as num).toDouble(),
      isExpense: (map['is_expense'] as int) == 1,
      categoryId: map['category_id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      currency: map['currency'] as String? ?? 'INR',
      receiptPath: map['receipt_path'] as String?,
    );
  }
}

