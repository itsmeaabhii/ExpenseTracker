import 'package:flutter/foundation.dart';

@immutable
class GoalModel {
  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.iconCode,
    required this.colorHex,
    required this.createdAt,
  });

  final int id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final int iconCode;
  final int colorHex;
  final DateTime createdAt;

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0, 1);
  }

  double get remainingAmount => targetAmount - savedAmount;

  bool get isCompleted => savedAmount >= targetAmount;

  GoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    int? iconCode,
    int? colorHex,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.millisecondsSinceEpoch,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static GoalModel fromMap(Map<String, Object?> map) {
    return GoalModel(
      id: map['id'] as int,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      iconCode: map['icon_code'] as int? ?? 0xe8f6,
      colorHex: map['color_hex'] as int? ?? 0xFF0B3C5D,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
