import '../models/baby.dart';
import '../models/nutrient.dart';

/// 1-3 岁每日营养推荐量规则（离线内置）。
/// 数值参考《中国居民膳食营养素参考摄入量(DRIs)》的近似值，
/// 分 1-2 岁、2-3 岁两档，并按体重/过敏/个头/缺铁风险做定制微调。
/// ⚠️ 仅供日常参考，不替代医生和营养师的专业建议。
class Recommendation {
  /// 基础推荐量（一天总量）
  static Nutrient baseFor(int ageInMonths) {
    if (ageInMonths < 24) {
      // 1-2 岁档
      return const Nutrient(
        kcal: 1100, protein: 35, iron: 10,
        calcium: 600, vitaminA: 400, vitaminC: 40,
      );
    }
    // 2-3 岁档（含 3 岁以上兜底）
    return const Nutrient(
      kcal: 1250, protein: 40, iron: 12,
      calcium: 600, vitaminA: 400, vitaminC: 45,
    );
  }

  /// 按宝宝档案定制推荐量：
  /// - 个头偏小：能量/蛋白质上调 10%
  /// - 缺铁风险：铁上调 20%
  /// - 体重偏离标准较多：能量微调（简化为 ±10%）
  static Nutrient forBaby(Baby baby) {
    final base = baseFor(baby.ageInMonths);

    double kcal = base.kcal;
    double protein = base.protein;
    double iron = base.iron;

    if (baby.sizeStatus == 'small') {
      kcal *= 1.10;
      protein *= 1.10;
    } else if (baby.sizeStatus == 'large') {
      kcal *= 0.95;
    }

    // 体重参考区间（1-3 岁粗估 9~15kg），偏离时微调能量
    if (baby.weightKg < 10) {
      kcal *= 1.05;
    } else if (baby.weightKg > 16) {
      kcal *= 0.95;
    }

    if (baby.ironRisk) {
      iron *= 1.20;
    }

    return Nutrient(
      kcal: kcal,
      protein: protein,
      iron: iron,
      calcium: base.calcium,
      vitaminA: base.vitaminA,
      vitaminC: base.vitaminC,
    );
  }

  /// 过敏食物提醒：把妈妈标记的过敏食物转成文案，建议在里避开。
  static List<String> allergyWarnings(Baby baby) {
    if (baby.allergies.trim().isEmpty) return const [];
    return baby.allergies
        .split(RegExp(r'[,，、\s]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => '已标记过敏：$s，制作辅食时请避开')
        .toList();
  }
}
