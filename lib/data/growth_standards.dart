/// WHO 儿童生长标准（0-3 岁）简化百分位表。
/// 来源：WHO Child Growth Standards — Simplified field tables (percentiles)
///   - Length/height-for-age：0-2 岁用 sft_lhfa_*_p_0_2.pdf（躺着量"身长"），
///     2-3 岁用 sft_lhfa_*_p_2_5.pdf（站立"身高"，比身长小约 0.7cm，24 月处有断层属正常）。
///   - Weight-for-age：sft_wfa_*_p_0_5.pdf。
/// 数组下标 = 月龄（0-36）。仅取 P3 与 P97，用于画参考区间和自动判型。
/// ⚠️ 适用于足月儿；早产儿需按矫正月龄并咨询医生。仅供观察趋势，不是医学诊断。
class GrowthStandards {
  /// 男孩身高/身长 P3 (cm)，下标 0-36 月
  static const List<double> boyHeightP3 = [
    46.3, 51.1, 54.7, 57.6, 60.0, 61.9, 63.6, 65.1, 66.5, 67.7, // 0-9
    69.0, 70.2, 71.3, 72.4, 73.4, 74.4, 75.4, 76.3, 77.2, 78.1, // 10-19
    78.9, 79.7, 80.5, 81.3,                                       // 20-23
    81.4, 82.1, 82.8, 83.5, 84.2, 84.9, 85.5, 86.2, 86.8, 87.4, // 24-33（站立身高表）
    88.0, 88.5, 89.1,                                             // 34-36
  ];

  /// 男孩身高/身长 P97 (cm)
  static const List<double> boyHeightP97 = [
    53.4, 58.4, 62.2, 65.3, 67.8, 69.9, 71.6, 73.2, 74.7, 76.2,
    77.6, 78.9, 80.2, 81.5, 82.7, 83.9, 85.1, 86.2, 87.3, 88.4,
    89.5, 90.5, 91.6, 92.6,
    92.9, 93.8, 94.8, 95.7, 96.6, 97.5, 98.3, 99.2, 100.0, 100.8,
    101.5, 102.3, 103.1,
  ];

  /// 女孩身高/身长 P3 (cm)
  static const List<double> girlHeightP3 = [
    45.6, 50.0, 53.2, 55.8, 58.0, 59.9, 61.5, 62.9, 64.3, 65.6,
    66.8, 68.0, 69.2, 70.3, 71.3, 72.4, 73.3, 74.3, 75.2, 76.2,
    77.0, 77.9, 78.7, 79.6,
    79.6, 80.4, 81.2, 81.9, 82.6, 83.4, 84.0, 84.7, 85.4, 86.0,
    86.7, 87.3, 87.9,
  ];

  /// 女孩身高/身长 P97 (cm)
  static const List<double> girlHeightP97 = [
    52.7, 57.4, 60.9, 63.8, 66.2, 68.2, 70.0, 71.6, 73.2, 74.7,
    76.1, 77.5, 78.9, 80.2, 81.4, 82.7, 83.9, 85.0, 86.2, 87.3,
    88.4, 89.4, 90.5, 91.5,
    91.8, 92.8, 93.7, 94.6, 95.6, 96.4, 97.3, 98.2, 99.0, 99.8,
    100.6, 101.4, 102.2,
  ];

  /// 男孩体重 P3 (kg)
  static const List<double> boyWeightP3 = [
    2.5, 3.4, 4.4, 5.1, 5.6, 6.1, 6.4, 6.7, 7.0, 7.2,
    7.5, 7.7, 7.8, 8.0, 8.2, 8.4, 8.5, 8.7, 8.9, 9.0,
    9.2, 9.3, 9.5, 9.7,
    9.8, 10.0, 10.1, 10.2, 10.4, 10.5, 10.7, 10.8, 10.9, 11.1,
    11.2, 11.3, 11.4,
  ];

  /// 男孩体重 P97 (kg)
  static const List<double> boyWeightP97 = [
    4.3, 5.7, 7.0, 7.9, 8.6, 9.2, 9.7, 10.2, 10.5, 10.9,
    11.2, 11.5, 11.8, 12.1, 12.4, 12.7, 12.9, 13.2, 13.5, 13.7,
    14.0, 14.3, 14.5, 14.8,
    15.1, 15.3, 15.6, 15.9, 16.1, 16.4, 16.6, 16.9, 17.1, 17.3,
    17.6, 17.8, 18.0,
  ];

  /// 女孩体重 P3 (kg)
  static const List<double> girlWeightP3 = [
    2.4, 3.2, 4.0, 4.6, 5.1, 5.5, 5.8, 6.1, 6.3, 6.6,
    6.8, 7.0, 7.1, 7.3, 7.5, 7.7, 7.8, 8.0, 8.2, 8.3,
    8.5, 8.7, 8.8, 9.0,
    9.2, 9.3, 9.5, 9.6, 9.8, 10.0, 10.1, 10.3, 10.4, 10.5,
    10.7, 10.8, 11.0,
  ];

  /// 女孩体重 P97 (kg)
  static const List<double> girlWeightP97 = [
    4.2, 5.4, 6.5, 7.4, 8.1, 8.7, 9.2, 9.6, 10.0, 10.4,
    10.7, 11.0, 11.3, 11.6, 11.9, 12.2, 12.5, 12.7, 13.0, 13.3,
    13.5, 13.8, 14.1, 14.3,
    14.6, 14.9, 15.2, 15.4, 15.7, 16.0, 16.2, 16.5, 16.8, 17.0,
    17.3, 17.6, 17.8,
  ];

  /// 取某月龄的 P3/P97，超出 0-36 用端点值，负数按 0
  static ({double p3, double p97}) heightRange(String gender, int month) =>
      _range(gender, month, boyHeightP3, boyHeightP97, girlHeightP3, girlHeightP97);

  static ({double p3, double p97}) weightRange(String gender, int month) =>
      _range(gender, month, boyWeightP3, boyWeightP97, girlWeightP3, girlWeightP97);

  static ({double p3, double p97}) _range(
    String gender,
    int month,
    List<double> bP3,
    List<double> bP97,
    List<double> gP3,
    List<double> gP97,
  ) {
    final m = month.clamp(0, 36);
    final female = gender == 'female';
    return (
      p3: (female ? gP3 : bP3)[m],
      p97: (female ? gP97 : bP97)[m],
    );
  }

  /// 判断某指标落在哪个区间：-1 低于P3（偏小），0 在P3~P97（正常），1 高于P97（偏大）
  static int classify(double value, double p3, double p97) {
    if (value < p3) return -1;
    if (value > p97) return 1;
    return 0;
  }

  /// 综合身高+体重判定个头偏差：
  /// 身高和体重任一低于 P3 → 偏小；任一高于 P97 → 偏大；都在区间内 → 正常。
  /// 返回 'small' / 'normal' / 'large'。
  static String classifySize(String gender, int month, double heightCm, double weightKg) {
    final h = heightRange(gender, month);
    final w = weightRange(gender, month);
    final hc = classify(heightCm, h.p3, h.p97);
    final wc = classify(weightKg, w.p3, w.p97);
    if (hc < 0 || wc < 0) return 'small';
    if (hc > 0 || wc > 0) return 'large';
    return 'normal';
  }

  static const sizeLabels = {
    'small': '偏小（低于P3）',
    'normal': '正常（P3~P97）',
    'large': '偏大（高于P97）',
  };
}
