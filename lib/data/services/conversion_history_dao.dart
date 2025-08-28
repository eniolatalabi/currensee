// lib/data/services/conversion_history_dao.dart
import 'package:sqflite/sqflite.dart';
import 'local_db_service.dart';
import '../models/conversion_history_model.dart';

class ConversionHistoryDao {
  ConversionHistoryDao();

  static const String tableName = 'conversion_history';

  Future<int> insertConversion(ConversionHistory conversion) async {
    final db = await LocalDbService.instance.database;
    final id = await db.insert(
      tableName,
      conversion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<ConversionHistory>> getRecentConversions(int limit) async {
    final db = await LocalDbService.instance.database;
    final maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
      limit: limit, // Fixed: removed .toString()
    );
    return maps.map((m) => ConversionHistory.fromMap(m)).toList();
  }

  Future<List<ConversionHistory>> getAllConversions({
    String? baseCurrency,
    String? targetCurrency,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await LocalDbService.instance.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (baseCurrency != null) {
      whereClauses.add('baseCurrency = ?');
      whereArgs.add(baseCurrency);
    }

    if (targetCurrency != null) {
      whereClauses.add('targetCurrency = ?');
      whereArgs.add(targetCurrency);
    }

    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.toIso8601String());
    }

    final maps = await db.query(
      tableName,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return maps.map((m) => ConversionHistory.fromMap(m)).toList();
  }

  Future<int> deleteConversion(int id) async {
    final db = await LocalDbService.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAll() async {
    final db = await LocalDbService.instance.database;
    return await db.delete(tableName);
  }

  Future<int> getConversionCount() async {
    final db = await LocalDbService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<ConversionHistory>> searchConversions(String query) async {
    final db = await LocalDbService.instance.database;
    final maps = await db.query(
      tableName,
      where: 'baseCurrency LIKE ? OR targetCurrency LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ConversionHistory.fromMap(m)).toList();
  }

  // Additional helper methods for better functionality
  Future<ConversionHistory?> getConversionById(int id) async {
    final db = await LocalDbService.instance.database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ConversionHistory.fromMap(maps.first);
  }

  Future<List<ConversionHistory>> getConversionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await LocalDbService.instance.database;
    final maps = await db.query(
      tableName,
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ConversionHistory.fromMap(m)).toList();
  }

  Future<List<ConversionHistory>> getTodaysConversions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getConversionsByDateRange(startOfDay, endOfDay);
  }

  Future<List<String>> getUniqueCurrencies() async {
    final db = await LocalDbService.instance.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT baseCurrency FROM $tableName
      UNION
      SELECT DISTINCT targetCurrency FROM $tableName
      ORDER BY baseCurrency
    ''');

    return result.map((row) => row['baseCurrency'] as String).toList();
  }

  Future<double> getTotalConvertedAmount(String currency) async {
    final db = await LocalDbService.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(convertedAmount) as total FROM $tableName 
      WHERE targetCurrency = ?
    ''',
      [currency],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
