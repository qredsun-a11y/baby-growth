/// 营养素汇总值：一天的摄入或一天的推荐量。
/// 单位：热量 kcal，蛋白质 g，铁/钙 mg，维生素A μg，维生素C mg。
class Nutrient {
  final double kcal;
  final double protein;
  final double iron;
  final double calcium;
  final double vitaminA;
  final double vitaminC;

  const Nutrient({
    this.kcal = 0,
    this.protein = 0,
    this.iron = 0,
    this.calcium = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
  });

  /// 两个营养素相加
  Nutrient operator +(Nutrient other) => Nutrient(
        kcal: kcal + other.kcal,
        protein: protein + other.protein,
        iron: iron + other.iron,
        calcium: calcium + other.calcium,
        vitaminA: vitaminA + other.vitaminA,
        vitaminC: vitaminC + other.vitaminC,
      );

  /// 按每种食物的量累加：食物每 100g 含量 × (克数 / 100)
  Nutrient scale(double ratio) => Nutrient(
        kcal: kcal * ratio,
        protein: protein * ratio,
        iron: iron * ratio,
        calcium: calcium * ratio,
        vitaminA: vitaminA * ratio,
        vitaminC: vitaminC * ratio,
      );

  /// 达成率（0~1+）：摄入 / 推荐
  double ratioOf(Nutrient target, String key) {
    final t = _value(target, key);
    if (t <= 0) return 0;
    return _value(this, key) / t;
  }

  double _value(Nutrient n, String key) {
    switch (key) {
      case 'kcal':
        return n.kcal;
      case 'protein':
        return n.protein;
      case 'iron':
        return n.iron;
      case 'calcium':
        return n.calcium;
      case 'vitaminA':
        return n.vitaminA;
      case 'vitaminC':
        return n.vitaminC;
      default:
        return 0;
    }
  }

  /// 供 UI 展示：标签 + 当前值 + 单位
  static const labels = {
    'kcal': '热量',
    'protein': '蛋白质',
    'iron': '铁',
    'calcium': '钙',
    'vitaminA': '维生素A',
    'vitaminC': '维生素C',
  };
  static const units = {
    'kcal': 'kcal',
    'protein': 'g',
    'iron': 'mg',
    'calcium': 'mg',
    'vitaminA': 'μg',
    'vitaminC': 'mg',
  };

  double valueOf(String key) => _value(this, key);
}
