/// 一条成长测量记录（身高/体重），用于画成长曲线。
class GrowthRecord {
  final int? id;
  final int babyId;
  final DateTime date;      // 测量日期
  final double heightCm;    // 身高 cm
  final double weightKg;    // 体重 kg
  final String note;

  const GrowthRecord({
    this.id,
    required this.babyId,
    required this.date,
    required this.heightCm,
    required this.weightKg,
    this.note = '',
  });

  /// 只保留日期部分（同一天算一次测量），用于比较
  DateTime get day => DateTime(date.year, date.month, date.day);

  Map<String, Object?> toMap() => {
        'id': id,
        'babyId': babyId,
        'date': date.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'note': note,
      };

  factory GrowthRecord.fromMap(Map<String, Object?> map) => GrowthRecord(
        id: map['id'] as int?,
        babyId: (map['babyId'] as num?)?.toInt() ?? 1,
        date: DateTime.parse(map['date'] as String),
        heightCm: (map['heightCm'] as num).toDouble(),
        weightKg: (map['weightKg'] as num).toDouble(),
        note: (map['note'] as String?) ?? '',
      );
}
