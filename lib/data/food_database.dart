import '../models/food.dart';

/// 内置食材营养库（离线可用）。
/// 数据为常见食材每 100g 的近似营养值，用于演示与日常参考；
/// ⚠️ 非权威医学数据，具体请以中国食物成分表为准。
/// 补食物：照着格式加一行即可，App 会自动出现在选择列表。
class FoodDatabase {
  static const List<Food> foods = [
    // ——— 谷物薯类 ———
    Food(id: 'rice', name: '米饭', category: '谷物', kcal: 116, protein: 2.6, iron: 0.3, calcium: 13, vitaminA: 0, vitaminC: 0),
    Food(id: 'congee', name: '白粥', category: '谷物', kcal: 46, protein: 1.1, iron: 0.1, calcium: 5, vitaminA: 0, vitaminC: 0),
    Food(id: 'noodle', name: '面条(煮)', category: '谷物', kcal: 110, protein: 4.5, iron: 1.2, calcium: 13, vitaminA: 0, vitaminC: 0),
    Food(id: 'mantou', name: '馒头', category: '谷物', kcal: 223, protein: 7.0, iron: 1.8, calcium: 38, vitaminA: 0, vitaminC: 0),
    Food(id: 'sweet_potato', name: '红薯', category: '谷物', kcal: 86, protein: 1.6, iron: 0.6, calcium: 30, vitaminA: 709, vitaminC: 26),
    Food(id: 'oat', name: '燕麦粥', category: '谷物', kcal: 68, protein: 2.4, iron: 1.0, calcium: 19, vitaminA: 0, vitaminC: 0),
    // ——— 蛋奶类 ———
    Food(id: 'egg', name: '鸡蛋', category: '蛋奶', kcal: 143, protein: 12.6, iron: 2.3, calcium: 56, vitaminA: 310, vitaminC: 0),
    Food(id: 'milk', name: '牛奶', category: '蛋奶', kcal: 64, protein: 3.3, iron: 0.1, calcium: 120, vitaminA: 24, vitaminC: 1),
    Food(id: 'yogurt', name: '酸奶', category: '蛋奶', kcal: 86, protein: 3.2, iron: 0.1, calcium: 118, vitaminA: 26, vitaminC: 1),
    Food(id: 'cheese', name: '奶酪', category: '蛋奶', kcal: 328, protein: 25.7, iron: 0.6, calcium: 799, vitaminA: 152, vitaminC: 0),
    // ——— 肉鱼禽 ———
    Food(id: 'pork', name: '瘦猪肉', category: '肉鱼', kcal: 143, protein: 20.3, iron: 3.0, calcium: 6, vitaminA: 44, vitaminC: 0),
    Food(id: 'beef', name: '牛肉', category: '肉鱼', kcal: 125, protein: 20.2, iron: 3.2, calcium: 9, vitaminA: 19, vitaminC: 0),
    Food(id: 'chicken', name: '鸡肉', category: '肉鱼', kcal: 167, protein: 19.4, iron: 1.4, calcium: 9, vitaminA: 48, vitaminC: 0),
    Food(id: 'fish', name: '鱼肉', category: '肉鱼', kcal: 104, protein: 17.8, iron: 1.3, calcium: 38, vitaminA: 19, vitaminC: 0),
    Food(id: 'salmon', name: '三文鱼', category: '肉鱼', kcal: 139, protein: 17.2, iron: 0.8, calcium: 9, vitaminA: 45, vitaminC: 0),
    Food(id: 'liver', name: '猪肝', category: '肉鱼', kcal: 129, protein: 19.3, iron: 22.6, calcium: 6, vitaminA: 4972, vitaminC: 20),
    // ——— 豆制品 ———
    Food(id: 'tofu', name: '豆腐', category: '豆类', kcal: 81, protein: 8.1, iron: 1.9, calcium: 164, vitaminA: 0, vitaminC: 0),
    Food(id: 'soymilk', name: '豆浆', category: '豆类', kcal: 31, protein: 3.0, iron: 0.5, calcium: 10, vitaminA: 0, vitaminC: 0),
    // ——— 蔬菜 ———
    Food(id: 'carrot', name: '胡萝卜', category: '蔬菜', kcal: 39, protein: 1.0, iron: 0.4, calcium: 32, vitaminA: 688, vitaminC: 13),
    Food(id: 'spinach', name: '菠菜', category: '蔬菜', kcal: 24, protein: 2.6, iron: 2.9, calcium: 66, vitaminA: 487, vitaminC: 32),
    Food(id: 'broccoli', name: '西兰花', category: '蔬菜', kcal: 34, protein: 2.8, iron: 0.7, calcium: 47, vitaminA: 31, vitaminC: 51),
    Food(id: 'tomato', name: '番茄', category: '蔬菜', kcal: 20, protein: 0.9, iron: 0.4, calcium: 10, vitaminA: 42, vitaminC: 19),
    Food(id: 'pumpkin', name: '南瓜', category: '蔬菜', kcal: 23, protein: 0.7, iron: 0.4, calcium: 16, vitaminA: 148, vitaminC: 9),
    Food(id: 'cabbage', name: '小白菜', category: '蔬菜', kcal: 15, protein: 1.5, iron: 0.7, calcium: 90, vitaminA: 280, vitaminC: 28),
    // ——— 水果 ———
    Food(id: 'apple', name: '苹果', category: '水果', kcal: 54, protein: 0.2, iron: 0.2, calcium: 4, vitaminA: 3, vitaminC: 4),
    Food(id: 'banana', name: '香蕉', category: '水果', kcal: 93, protein: 1.4, iron: 0.4, calcium: 7, vitaminA: 5, vitaminC: 8),
    Food(id: 'orange', name: '橙子', category: '水果', kcal: 48, protein: 0.8, iron: 0.2, calcium: 20, vitaminA: 11, vitaminC: 33),
    Food(id: 'strawberry', name: '草莓', category: '水果', kcal: 32, protein: 1.0, iron: 0.4, calcium: 16, vitaminA: 5, vitaminC: 47),
    Food(id: 'kiwi', name: '猕猴桃', category: '水果', kcal: 61, protein: 0.8, iron: 1.2, calcium: 27, vitaminA: 22, vitaminC: 62),
    Food(id: 'pear', name: '梨', category: '水果', kcal: 51, protein: 0.4, iron: 0.2, calcium: 9, vitaminA: 6, vitaminC: 6),
  ];

  /// 按 id 找食物
  static Food? byId(String id) {
    for (final f in foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// 所有分类（用于选择页分组显示）
  static List<String> get categories {
    final set = <String>{};
    for (final f in foods) {
      set.add(f.category);
    }
    return set.toList();
  }
}
