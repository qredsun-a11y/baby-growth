import 'dart:convert';

/// 一餐里的一道食物：食物 id + 吃了多少克。
class MealFood {
  final String foodId;
  final double grams;

  const MealFood({required this.foodId, required this.grams});

  Map<String, Object?> toMap() => {'foodId': foodId, 'grams': grams};

  factory MealFood.fromMap(Map<String, Object?> map) => MealFood(
        foodId: map['foodId'] as String,
        grams: (map['grams'] as num).toDouble(),
      );
}

/// 一餐记录。
/// foods 用 JSON 字符串存进数据库（V1 简单起见，不上关联表）。
class Meal {
  final int? id;
  final String mealType;    // breakfast / lunch / dinner / snack
  final DateTime date;      // 哪一餐（含日期）
  final String foodsJson;   // List<MealFood> 的 JSON
  final String? photoPath;  // 照片在 App 私有目录里的路径
  final String note;        // 备注

  static const typeBreakfast = 'breakfast';
  static const typeLunch = 'lunch';
  static const typeDinner = 'dinner';
  static const typeSnack = 'snack';

  static const typeLabels = {
    typeBreakfast: '早餐',
    typeLunch: '午餐',
    typeDinner: '晚餐',
    typeSnack: '加餐',
  };

  const Meal({
    this.id,
    required this.mealType,
    required this.date,
    required this.foodsJson,
    this.photoPath,
    this.note = '',
  });

  String get typeLabel => typeLabels[mealType] ?? '其他';

  /// 把食物列表编码成 JSON 字符串存库
  static String encodeFoods(List<Map<String, Object?>> foods) => jsonEncode(foods);

  /// 从 JSON 字符串解码出食物列表
  static List<MealFood> decodeFoods(String json) {
    final raw = jsonDecode(json) as List<dynamic>;
    return raw.map((e) => MealFood.fromMap(e as Map<String, Object?>)).toList();
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'mealType': mealType,
        'date': date.toIso8601String(),
        'foodsJson': foodsJson,
        'photoPath': photoPath,
        'note': note,
      };

  factory Meal.fromMap(Map<String, Object?> map) => Meal(
        id: map['id'] as int?,
        mealType: map['mealType'] as String,
        date: DateTime.parse(map['date'] as String),
        foodsJson: map['foodsJson'] as String,
        photoPath: map['photoPath'] as String?,
        note: (map['note'] as String?) ?? '',
      );
}
