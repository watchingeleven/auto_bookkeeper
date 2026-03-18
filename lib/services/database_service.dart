import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;

/// 本地 SQLite 数据库服务
class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auto_bookkeeper.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            merchant TEXT NOT NULL,
            category TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            raw_notification TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            is_expense INTEGER NOT NULL DEFAULT 1,
            note TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC)',
        );
      },
    );
  }

  Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<model.Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  Future<List<model.Transaction>> getTodayTransactions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  Future<List<model.Transaction>> getMonthTransactions({DateTime? month}) async {
    final now = month ?? DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return getTransactionsByDateRange(startOfMonth, endOfMonth);
  }

  Future<List<model.Transaction>> getUnsyncedTransactions() async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'synced = 0',
    );
    return maps.map((m) => model.Transaction.fromMap(m)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getCategoryStats({
    required bool isExpense,
    DateTime? month,
  }) async {
    final transactions = await getMonthTransactions(month: month);
    final filtered =
        transactions.where((t) => t.isExpense == isExpense).toList();

    final stats = <String, double>{};
    for (final t in filtered) {
      stats[t.category] = (stats[t.category] ?? 0) + t.amount;
    }
    return stats;
  }

  Future<double> getMonthlyExpense({DateTime? month}) async {
    final transactions = await getMonthTransactions(month: month);
    return transactions
        .where((t) => t.isExpense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getMonthlyIncome({DateTime? month}) async {
    final transactions = await getMonthTransactions(month: month);
    return transactions
        .where((t) => !t.isExpense)
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }
}
