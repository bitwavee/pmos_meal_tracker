class WeightLog {
  const WeightLog({
    this.id,
    required this.weightKg,
    required this.date,
    this.bmi,
    this.heightCm,
  });

  final int? id;
  final double weightKg;
  final DateTime date;
  final double? bmi;
  final double? heightCm;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weightKg': weightKg,
      'date': _dateKey(date),
      'bmi': bmi,
      'heightCm': heightCm,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] as int?,
      weightKg: (map['weightKg'] as num).toDouble(),
      date: _parseDateKey(map['date'] as String),
      bmi: map['bmi'] == null ? null : (map['bmi'] as num).toDouble(),
      heightCm: map['heightCm'] == null ? null : (map['heightCm'] as num).toDouble(),
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime _parseDateKey(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
