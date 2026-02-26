import 'package:flutter/foundation.dart';

@immutable
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
  });

  final int id;
  final String name;
  final int iconCode;
  final int colorHex;

  CategoryModel copyWith({
    int? id,
    String? name,
    int? iconCode,
    int? colorHex,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_hex': colorHex,
    };
  }

  static CategoryModel fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as int,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorHex: map['color_hex'] as int,
    );
  }
}

