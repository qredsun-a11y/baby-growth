import '../data/food_database.dart';
import '../data/recommendation.dart';
import '../db/database_helper.dart';
import '../models/baby.dart';
import '../models/meal.dart';
import '../models/nutrient.dart';

/// 营养建议引擎：把"每餐记录"汇总成"当日摄入"，对比推荐量，生成建议。
/// 全程本地计算，无网络。
class NutritionService {
  NutritionService._();
  static final NutritionService instance = NutritionService._();

  /// 计算指定日期的总摄入
  Future<Nutrient> intakeForDate(DateTime date) async {
    final meals = await DatabaseHelper.instance.getMealsByDate(date);
    Nutrient total = const Nutrient();
    for (final meal in meals) {
      total = total + _nutrientOfMeal(meal);
    }
    return total;
  }

  /// 单餐营养素 = Σ(食物每100g含量 × 克数/100)
  Nutrient _nutrientOfMeal(Meal meal) {
    Nutrient sum = const Nutrient();
    final List<MealFood> foods;
    try {
      foods = Meal.decodeFoods(meal.foodsJson);
    } catch (_) {
      return sum;
    }
    for (final mf in foods) {
      final food = FoodDatabase.byId(mf.foodId);
      if (food == null) continue;
      final ratio = mf.grams / 100.0;
      sum = sum + Nutrient(
        kcal: food.kcal,
        protein: food.protein,
        iron: food.iron,
        calcium: food.calcium,
        vitaminA: food.vitaminA,
        vitaminC: food.vitaminC,
      ).scale(ratio);
    }
    return sum;
  }

  /// 生成当天的建议清单。
  /// 规则：达成率 < 60% 提示"偏低"并给食物建议；> 130% 提示"偏高"；其余"达标"。
  Future<List<Advice>> adviceForDate(DateTime date, Baby baby) async {
    final intake = await intakeForDate(date);
    final target = Recommendation.forBaby(baby);
    final advice = <Advice>[];

    void check(String key, String foodSuggestion) {
      final r = intake.ratioOf(target, key);
      final label = Nutrient.labels[key]!;
      final value = intake.valueOf(key);
      final goal = target.valueOf(key);
      if (r < 0.6) {
        advice.add(Advice(
          key: key,
          level: AdviceLevel.low,
          text: '$label偏少（${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}），$foodSuggestion',
        ));
      } else if (r > 1.3) {
        advice.add(Advice(
          key: key,
          level: AdviceLevel.high,
          text: '$label偏高（${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}），注意别过量',
        ));
      } else {
        advice.add(Advice(
          key: key,
          level: AdviceLevel.good,
          text: '$label达标（${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}）',
        ));
      }
    }

    check('kcal', '可适当增加主食（米饭/面条）或红薯');
    check('protein', '建议加个鸡蛋或一点瘦肉、鱼');
    check('iron', '建议搭配瘦肉、猪肝（每周1-2次）或菠菜');
    check('calcium', '建议增加牛奶、酸奶、豆腐');
    check('vitaminA', '建议吃胡萝卜、南瓜、西兰花');
    check('vitaminC', '建议吃橙子、猕猴桃、草莓');

    // 定制：过敏提醒排最前
    for (final w in Recommendation.allergyWarnings(baby)) {
      advice.insert(0, Advice(key: 'allergy', level: AdviceLevel.warn, text: w));
    }

    // 没记录任何一餐时，给引导文案
    final meals = await DatabaseHelper.instance.getMealsByDate(date);
    if (meals.isEmpty) {
      advice.insert(
        0,
        const Advice(
          key: 'empty',
          level: AdviceLevel.warn,
          text: '今天还没有记录，先点「记录这一餐」开始吧',
        ),
      );
    }
    return advice;
  }
}

/// 建议等级
enum AdviceLevel { good, low, high, warn }

/// 一条建议
class Advice {
  final String key;
  final AdviceLevel level;
  final String text;

  const Advice({required this.key, required this.level, required this.text});
}
