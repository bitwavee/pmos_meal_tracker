import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/meal.dart';
import '../models/period_log.dart';
import '../models/weight_log.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService.instance);

final todayMealsProvider = FutureProvider<List<MealProgress>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getMealProgressForDate(DateTime.now());
});

final dailyHistoryProvider = FutureProvider<List<DailyHistoryEntry>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getLastSevenDaysHistory();
});

final cycleOverviewProvider = FutureProvider<CycleOverview>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCycleOverview();
});

final periodsProvider = FutureProvider<List<PeriodLog>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getPeriods();
});

final weightLogsProvider = FutureProvider<List<WeightLog>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getWeightLogs();
});

final profileHeightProvider = FutureProvider<double?>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getHeight();
});

final currentStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getCurrentStreak();
});
