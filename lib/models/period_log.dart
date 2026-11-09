enum PeriodStatus { early, onTime, late }

extension PeriodStatusLabel on PeriodStatus {
  String get label {
    switch (this) {
      case PeriodStatus.early:
        return 'Early';
      case PeriodStatus.onTime:
        return 'On Time';
      case PeriodStatus.late:
        return 'Late';
    }
  }

  String get value {
    return label.toLowerCase();
  }
}

class PeriodLog {
  const PeriodLog({
    this.id,
    required this.startDate,
    this.endDate,
    required this.status,
  });

  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final PeriodStatus status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': _dateKey(startDate),
      'endDate': endDate == null ? null : _dateKey(endDate!),
      'status': status.value,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory PeriodLog.fromMap(Map<String, dynamic> map) {
    return PeriodLog(
      id: map['id'] as int?,
      startDate: _parseDateKey(map['startDate'] as String),
      endDate: map['endDate'] == null ? null : _parseDateKey(map['endDate'] as String),
      status: _statusFromString(map['status'] as String),
    );
  }

  static PeriodStatus _statusFromString(String value) {
    switch (value.toLowerCase()) {
      case 'early':
        return PeriodStatus.early;
      case 'late':
        return PeriodStatus.late;
      case 'on time':
      case 'ontime':
      case 'on_time':
      default:
        return PeriodStatus.onTime;
    }
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

class CycleOverview {
  const CycleOverview({
    required this.previousPeriods,
    required this.averageCycleLength,
    required this.nextPeriodDate,
  });

  final List<PeriodLog> previousPeriods;
  final int averageCycleLength;
  final DateTime nextPeriodDate;
}
