import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/kerala_meals.dart';
import '../models/meal.dart';
import '../models/period_log.dart';
import '../models/weight_log.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static Database? _database;
  void resetDatabaseInstance() {
  _database = null;
}

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pmos_meal_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onOpen: _onDatabaseOpen,
    );
  }

  Future<void> _onDatabaseOpen(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='meals'",
    );
    
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE meals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          whyItHelps TEXT NOT NULL,
          calories INTEGER NOT NULL,
          protein INTEGER NOT NULL,
          type TEXT NOT NULL,
          isKeralaStyle INTEGER NOT NULL,
          category TEXT NOT NULL
        )
      ''');
      await _seedMeals(db);
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meal_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealId TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_meal_logs_unique ON meal_logs (mealId, date)
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        whyItHelps TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        type TEXT NOT NULL,
        isKeralaStyle INTEGER NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weightKg REAL NOT NULL,
        date TEXT NOT NULL,
        bmi REAL,
        heightCm REAL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        heightCm REAL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.insert('user_profile', {
      'id': 1,
      'heightCm': null,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });

    await _seedMeals(db);
  }

  Future<void> _seedMeals(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM meals'));
    if (count == 0) {
      for (final meal in keralalaMeals) {
        await db.insert('meals', meal.toMap());
      }
    }
  }

  // ==================== BACKUP & RESTORE ====================

  Future<void> backupDatabase() async {
    final db = await database;
    final dbPath = db.path;

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${directory.path}/pmos_meal_tracker_backup_$timestamp.db';

    // Close database before copying
    await db.close();
    _database = null;

    await File(dbPath).copy(backupPath);

    // Re-open database
    await database;

    await Share.shareXFiles(
      [XFile(backupPath)],
      text: 'PMOS Meal Tracker Backup',
    );
  }

  Future<void> restoreDatabase(String backupFilePath) async {
    final db = await database;
    final dbPath = db.path;

    // Close current database
    await db.close();
    _database = null;

    // Replace database file
    await File(backupFilePath).copy(dbPath);

    // Re-open
    await database;
  }

  // ==================== EXISTING METHODS ====================

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<List<MealProgress>> getMealProgressForDate(DateTime date) async {
    final db = await database;
    final selectedDate = _dateKey(date);

    final rows = await db.query(
      'meal_logs',
      where: 'date = ?',
      whereArgs: [selectedDate],
    );

    final completedIds = <String>{};
    for (final row in rows) {
      final completed = (row['completed'] as int) == 1;
      if (completed) {
        completedIds.add(row['mealId'] as String);
      }
    }

    final meals = await getMeals();
    return meals
        .map(
          (meal) => MealProgress(
            meal: meal,
            completed: completedIds.contains(meal.id),
          ),
        )
        .toList();
  }

  Future<void> toggleMealCompletion(String mealId, DateTime date, bool completed) async {
    final db = await database;
    final key = _dateKey(date);

    final existing = await db.query(
      'meal_logs',
      where: 'mealId = ? AND date = ?',
      whereArgs: [mealId, key],
      limit: 1,
    );

    final payload = {
      'mealId': mealId,
      'date': key,
      'completed': completed ? 1 : 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    if (existing.isEmpty) {
      await db.insert('meal_logs', payload);
      return;
    }

    await db.update(
      'meal_logs',
      payload,
      where: 'mealId = ? AND date = ?',
      whereArgs: [mealId, key],
    );
  }

  Future<int> getCurrentStreak() async {
    final db = await database;
    const totalMeals = 6;
    final today = DateTime.now();
    int streak = 0;

    for (int offset = 0; offset < 365; offset++) {
      final date = today.subtract(Duration(days: offset));
      final key = _dateKey(date);
      final rows = await db.query(
        'meal_logs',
        where: 'date = ?',
        whereArgs: [key],
      );

      final completedCount = rows.fold<int>(0, (sum, row) {
        final completed = (row['completed'] as int) == 1;
        return completed ? sum + 1 : sum;
      });

      final percent = totalMeals == 0 ? 0 : (completedCount / totalMeals) * 100;
      if (percent >= 80) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<List<DailyHistoryEntry>> getLastSevenDaysHistory() async {
    final db = await database;
    final entries = <DailyHistoryEntry>[];
    const totalMeals = 6;

    for (int offset = 0; offset <= 6; offset++) {
      final date = DateTime.now().subtract(Duration(days: offset));
      final key = _dateKey(date);
      final rows = await db.query(
        'meal_logs',
        where: 'date = ?',
        whereArgs: [key],
      );

      final completedCount = rows.fold<int>(0, (sum, row) {
        final completed = (row['completed'] as int) == 1;
        return completed ? sum + 1 : sum;
      });

      entries.add(
        DailyHistoryEntry(
          date: date,
          completedCount: completedCount,
          totalMeals: totalMeals,
        ),
      );
    }

    return entries;
  }

  Future<double> getDailyCompletionPercent(DateTime date) async {
    final progress = await getMealProgressForDate(date);
    final completed = progress.where((meal) => meal.completed).length;
    return progress.isEmpty ? 0 : (completed / progress.length) * 100;
  }

  Future<void> savePeriod(PeriodLog log) async {
    final db = await database;
    await db.insert('periods', log.toMap());
  }

  Future<List<PeriodLog>> getPeriods() async {
    final db = await database;
    final rows = await db.query(
      'periods',
      orderBy: 'createdAt DESC',
    );

    return rows.map((row) => PeriodLog.fromMap(row)).toList();
  }

  Future<CycleOverview> getCycleOverview() async {
    final periods = await getPeriods();
    final sorted = periods.toList()..sort((a, b) => a.startDate.compareTo(b.startDate));

    int averageLength = 28;
    if (sorted.length >= 2) {
      final cycleLengths = <int>[];
      for (int i = 1; i < sorted.length; i++) {
        final diff = sorted[i].startDate.difference(sorted[i - 1].startDate).inDays;
        cycleLengths.add(diff.abs());
      }
      final avg = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      averageLength = avg.round();
    }

    final nextDate = sorted.isEmpty
        ? DateTime.now().add(const Duration(days: 28))
        : sorted.last.startDate.add(Duration(days: averageLength));

    return CycleOverview(
      previousPeriods: sorted,
      averageCycleLength: averageLength,
      nextPeriodDate: nextDate,
    );
  }

  Future<void> saveWeightLog(WeightLog log) async {
    final db = await database;
    await db.insert('weight_logs', log.toMap());
  }

  Future<List<WeightLog>> getWeightLogs() async {
    final db = await database;
    final rows = await db.query(
      'weight_logs',
      orderBy: 'createdAt DESC',
    );
    return rows.map((row) => WeightLog.fromMap(row)).toList();
  }

  Future<void> saveHeight(double heightCm) async {
    final db = await database;
    await db.update(
      'user_profile',
      {
        'heightCm': heightCm,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<double?> getHeight() async {
    final db = await database;
    final rows = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['heightCm'];
    if (value == null) {
      return null;
    }

    return (value as num).toDouble();
  }

  Future<List<Meal>> getMeals() async {
    final db = await database;
    final rows = await db.query('meals', orderBy: 'name ASC');
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  Future<List<Meal>> getMealsByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'meals',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return rows.map((row) => Meal.fromMap(row)).toList();
  }

  Future<Meal?> getMealById(String mealId) async {
    final db = await database;
    final rows = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [mealId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Meal.fromMap(rows.first);
  }
}