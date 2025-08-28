// lib/data/services/local_db_service.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  LocalDbService._init();
  static final LocalDbService instance = LocalDbService._init();

  static const String _dbName = 'currensee.db';
  static const int _dbVersion = 1;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      // Optionally add onUpgrade later when schema changes
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    // Enable foreign keys if you later introduce relations
    await db.execute('PRAGMA foreign_keys = ON');
  }

  FutureOr<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE conversion_history (
id INTEGER PRIMARY KEY AUTOINCREMENT,
baseCurrency TEXT NOT NULL,
targetCurrency TEXT NOT NULL,
baseAmount REAL NOT NULL,
convertedAmount REAL NOT NULL,
rate REAL NOT NULL,
timestamp TEXT NOT NULL
);
''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
