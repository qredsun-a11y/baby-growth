/// 宝宝档案模型。
/// id 固定为 1：V1 只支持一个宝宝（多宝宝切换放 V2）。
class Baby {
  final int? id;
  final String name;
  final DateTime birthDate;   // 出生日期，年龄自动算
  final double heightCm;      // 身高
  final double weightKg;      // 体重
  final String allergies;     // 过敏食物，逗号分隔（如"花生,牛奶"）
  final String sizeStatus;    // 个头偏差：small / normal / large
  final bool ironRisk;        // 是否有缺铁风险

  const Baby({
    this.id,
    required this.name,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    this.allergies = '',
    this.sizeStatus = 'normal',
    this.ironRisk = false,
  });

  /// 按今天算月龄（用于选营养推荐档位）
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// 显示用文案：1 岁 3 个月
  String get ageLabel {
    final m = ageInMonths;
    return '${m ~/ 12} 岁 ${m % 12} 个月';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'birthDate': birthDate.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'allergies': allergies,
        'sizeStatus': sizeStatus,
        'ironRisk': ironRisk ? 1 : 0,
      };

  factory Baby.fromMap(Map<String, Object?> map) => Baby(
        id: map['id'] as int?,
        name: map['name'] as String,
        birthDate: DateTime.parse(map['birthDate'] as String),
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        allergies: (map['allergies'] as String?) ?? '',
        sizeStatus: (map['sizeStatus'] as String?) ?? 'normal',
        ironRisk: (map['ironRisk'] as int?) == 1,
      );
}
