import 'package:flutter/material.dart';

import '../data/food_database.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../models/nutrient.dart';
import '../theme.dart';

/// 面板里的一条来源：今天吃到的某个食物（或补充剂）提供的该营养量
class FoodSourceItem {
  final String name;
  final String detail;   // 如 "吃了 50g" 或 "补充剂"
  final double amount;   // 该来源提供的营养量
  final bool isSupplement;

  const FoodSourceItem({
    required this.name,
    required this.detail,
    required this.amount,
    this.isSupplement = false,
  });
}

/// 点击营养名称弹出的"今日食物来源"面板：
/// 只统计今天记录里实际吃到的食物，按该食物实际提供的营养量
/// （每100g含量 × 吃到的克数）从高到低排列，并显示占今日总摄入的比例。
/// 维生素A/C 的额外补充剂也作为来源单独列出。全程读本地数据，不联网。
class FoodSourceSheet extends StatelessWidget {
  final String nutrientKey;
  final List<Meal> todayMeals; // 今日全部餐次

  const FoodSourceSheet({
    super.key,
    required this.nutrientKey,
    required this.todayMeals,
  });

  /// 某食物每100g的该营养素含量
  double _per100(Food f) {
    switch (nutrientKey) {
      case 'kcal':
        return f.kcal;
      case 'protein':
        return f.protein;
      case 'iron':
        return f.iron;
      case 'calcium':
        return f.calcium;
      case 'vitaminA':
        return f.vitaminA;
      case 'vitaminC':
        return f.vitaminC;
      default:
        return 0;
    }
  }

  /// 从今日餐次汇总出该营养的来源列表（已按提供量降序）
  List<FoodSourceItem> _buildSources() {
    // 同一食物可能出现在多餐，按食物累计克数
    final gramsByFood = <String, double>{};
    double supplement = 0;
    for (final meal in todayMeals) {
      if (nutrientKey == 'vitaminA') supplement += meal.vitaminASupplement;
      if (nutrientKey == 'vitaminC') supplement += meal.vitaminCSupplement;
      for (final mf in Meal.decodeFoods(meal.foodsJson)) {
        gramsByFood[mf.foodId] = (gramsByFood[mf.foodId] ?? 0) + mf.grams;
      }
    }

    final items = <FoodSourceItem>[];
    gramsByFood.forEach((foodId, grams) {
      final food = FoodDatabase.byId(foodId);
      if (food == null) return;
      final amount = _per100(food) * grams / 100.0;
      if (amount <= 0) return;
      items.add(FoodSourceItem(
        name: food.name,
        detail: '${food.category} · 吃了 ${grams.toStringAsFixed(grams >= 100 ? 0 : 0)}g',
        amount: amount,
      ));
    });
    if (supplement > 0) {
      items.add(FoodSourceItem(
        name: '维生素补充剂',
        detail: '额外补充（非食物）',
        amount: supplement,
        isSupplement: true,
      ));
    }
    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final label = Nutrient.labels[nutrientKey] ?? nutrientKey;
    final unit = Nutrient.units[nutrientKey] ?? '';
    final items = _buildSources();
    final total = items.fold<double>(0, (sum, i) => sum + i.amount);
    final maxAmount = items.isEmpty ? 1 : items.first.amount;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                Icon(Icons.restaurant_menu, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$label · 今日来源',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              items.isEmpty
                  ? '今天还没有记录含「$label」的食物，记一餐后就能看到来源。'
                  : '下面是今天记录里提供「$label」的食物与补充剂，按实际提供的量从高到低排列。'
                      '今日共摄入约 ${total.toStringAsFixed(total >= 100 ? 0 : 1)} $unit。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            '今天还没有记录含「$label」的食物',
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length + 1, // 最后一项是说明
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Text(
                            '⚠️ 含量为内置营养库近似值，仅供日常参考；过敏食物请避开，具体请咨询医生或营养师。',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        );
                      }
                      final item = items[index];
                      final pct = total > 0 ? item.amount / total * 100 : 0;
                      final barRatio = maxAmount > 0 ? item.amount / maxAmount : 0;
                      final color = item.isSupplement ? AppTheme.accent : AppTheme.primary;

                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: color.withOpacity(0.12),
                                    child: Icon(
                                      item.isSupplement ? Icons.healing : Icons.restaurant,
                                      size: 14,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          item.detail,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.amount.toStringAsFixed(item.amount >= 100 ? 0 : 1)} $unit',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                      Text(
                                        '占今日 ${pct.toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barRatio.clamp(0.0, 1.0).toDouble(),
                                  minHeight: 4,
                                  backgroundColor: Colors.grey.shade200,
                                  color: color.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
