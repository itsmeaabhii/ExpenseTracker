import 'package:flutter/foundation.dart';

@immutable
class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.isPaid,
    this.amount,
    this.categoryId,
    this.notificationId,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isPaid;
  final double? amount;
  final int? categoryId;
  final int? notificationId;
  final DateTime createdAt;

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inDays;
  }

  ReminderModel copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isPaid,
    double? amount,
    int? categoryId,
    int? notificationId,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'is_paid': isPaid ? 1 : 0,
      'amount': amount,
      'category_id': categoryId,
      'notification_id': notificationId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static ReminderModel fromMap(Map<String, Object?> map) {
    return ReminderModel(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      isPaid: (map['is_paid'] as int) == 1,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      categoryId: map['category_id'] as int?,
      notificationId: map['notification_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
