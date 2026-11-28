import 'dart:convert';

import 'meal.dart';

/// 常用食物组合：一组"食物 id → 克数"，起个名字一键套用。
class FavoriteCombo {
  final int? id;
  final int babyId;
  final String name;
  final String foodsJson; // List<MealFood> 的 JSON

  const FavoriteCombo({
    this.id,
    required this.babyId,
    required this.name,
    required this.foodsJson,
  });

  List<MealFood> get foods {
    try {
      return Meal.decodeFoods(foodsJson);
    } catch (_) {
      return const [];
    }
  }

  /// 便捷构造：从食物 id→克数 map 生成
  factory FavoriteCombo.fromMapData({
    int? id,
    required int babyId,
    required String name,
    required Map<String, double> items,
  }) {
    final foods = items.entries
        .map((e) => MealFood(foodId: e.key, grams: e.value).toMap())
        .toList();
    return FavoriteCombo(
      id: id,
      babyId: babyId,
      name: name,
      foodsJson: jsonEncode(foods),
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'babyId': babyId,
        'name': name,
        'foodsJson': foodsJson,
      };

  factory FavoriteCombo.fromMap(Map<String, Object?> map) => FavoriteCombo(
        id: map['id'] as int?,
        babyId: (map['babyId'] as num?)?.toInt() ?? 1,
        name: map['name'] as String,
        foodsJson: map['foodsJson'] as String,
      );
}
