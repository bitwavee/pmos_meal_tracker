import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'database_service.dart';

const String backupTaskName = "dailyBackupTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backupTaskName) {
      try {
        await _performBackup();
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  });
}

Future<void> _performBackup() async {
  final dbService = DatabaseService.instance;
  final db = await dbService.database;
  final dbPath = db.path;

  final directory = await getApplicationDocumentsDirectory();
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
  final backupPath = '${directory.path}/auto_backup_$timestamp.db';

  // Close and copy
  await db.close();
  DatabaseService.instance.resetDatabaseInstance(); // We'll add this method

  await File(dbPath).copy(backupPath);

  // Re-open
  await dbService.database;

  // Optional: Keep only last 7 backups
  await _cleanupOldBackups(directory);
}

Future<void> _cleanupOldBackups(Directory directory) async {
  final files = directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('auto_backup_') && f.path.endsWith('.db'))
      .toList();

  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

  if (files.length > 7) {
    for (var i = 7; i < files.length; i++) {
      await files[i].delete();
    }
  }
}