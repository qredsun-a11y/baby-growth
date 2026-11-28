/// 宝宝档案模型。
/// V1 单宝宝；V2 多宝宝；V2.1 加性别（百分位标准男女不同）+ 个头偏差可手动覆盖。
class Baby {
  final int? id;
  final String name;
  final String gender;      // 'male' / 'female'，用于选 WHO 百分位标准曲线
  final DateTime birthDate; // 出生日期，年龄自动算
  final double heightCm;    // 身高（最新测量）
  final double weightKg;    // 体重（最新测量）
  final String allergies;   // 过敏食物，逗号分隔
  final String sizeStatus;  // 个头偏差：small / normal / large（可由百分位自动判定或手动覆盖）
  final bool sizeStatusManual; // 是否手动指定了 sizeStatus（true 则不自动覆盖）
  final bool ironRisk;      // 是否有缺铁风险

  static const genderMale = 'male';
  static const genderFemale = 'female';
  static const genderLabels = {genderMale: '男', genderFemale: '女'};

  const Baby({
    this.id,
    required this.name,
    this.gender = genderMale,
    required this.birthDate,
    required this.heightCm,
    required this.weightKg,
    this.allergies = '',
    this.sizeStatus = 'normal',
    this.sizeStatusManual = false,
    this.ironRisk = false,
  });

  /// 按今天算月龄（用于选营养推荐档位）
  int get ageInMonths {
    final now = DateTime.now();
    int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
    if (now.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  /// 指定日期的月龄（成长曲线用）
  int ageInMonthsAt(DateTime date) {
    int months = (date.year - birthDate.year) * 12 + (date.month - birthDate.month);
    if (date.day < birthDate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  String get genderLabel => genderLabels[gender] ?? '男';

  /// 显示用文案：1 岁 3 个月
  String get ageLabel {
    final m = ageInMonths;
    return '${m ~/ 12} 岁 ${m % 12} 个月';
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'gender': gender,
        'birthDate': birthDate.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'allergies': allergies,
        'sizeStatus': sizeStatus,
        'sizeStatusManual': sizeStatusManual ? 1 : 0,
        'ironRisk': ironRisk ? 1 : 0,
      };

  factory Baby.fromMap(Map<String, Object?> map) => Baby(
        id: map['id'] as int?,
        name: map['name'] as String,
        gender: (map['gender'] as String?) ?? genderMale,
        birthDate: DateTime.parse(map['birthDate'] as String),
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        allergies: (map['allergies'] as String?) ?? '',
        sizeStatus: (map['sizeStatus'] as String?) ?? 'normal',
        sizeStatusManual: (map['sizeStatusManual'] as int?) == 1,
        ironRisk: (map['ironRisk'] as int?) == 1,
      );
}
