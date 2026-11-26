/// 食物模型：一种食材 + 它每 100g 所含的营养素。
/// 营养数据是"内置营养库"的核心，全部打包在 App 里，离线可读。
class Food {
  final String id;
  final String name;
  final String category;      // 分类：谷物/蛋奶/肉鱼/蔬菜/水果
  final double kcal;          // 热量（千卡 / 100g）
  final double protein;       // 蛋白质（克 / 100g）
  final double iron;          // 铁（毫克 / 100g）
  final double calcium;       // 钙（毫克 / 100g）
  final double vitaminA;      // 维生素A（微克视黄醇当量 / 100g）
  final double vitaminC;      // 维生素C（毫克 / 100g）

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.kcal,
    required this.protein,
    required this.iron,
    required this.calcium,
    required this.vitaminA,
    required this.vitaminC,
  });
}
