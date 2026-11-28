import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/baby.dart';
import '../models/favorite_combo.dart';
import '../models/growth_record.dart';
import '../models/meal.dart';

/// 本地数据库封装（sqflite）。
/// 所有数据存在 App 私有目录，不联网、不上传。
/// V2：多宝宝（baby_id）、成长记录、常用组合、设置项。
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const _dbName = 'baby_nutrition.db';
  static const _dbVersion = 3;

  // V1 老库里 baby 和 meals 固定 id=1；迁移后作为第一个宝宝
  static const legacyBabyId = 1;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 全新安装：直接建 v2 结构
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE baby (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender TEXT NOT NULL DEFAULT 'male',
        birthDate TEXT NOT NULL,
        heightCm REAL NOT NULL,
        weightKg REAL NOT NULL,
        allergies TEXT NOT NULL DEFAULT '',
        sizeStatus TEXT NOT NULL DEFAULT 'normal',
        sizeStatusManual INTEGER NOT NULL DEFAULT 0,
        ironRisk INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        babyId INTEGER NOT NULL DEFAULT 1,
        mealType TEXT NOT NULL,
        date TEXT NOT NULL,
        foodsJson TEXT NOT NULL,
        photoPath TEXT,
        note TEXT NOT NULL DEFAULT '',
        vitaminASupplement REAL NOT NULL DEFAULT 0,
        vitaminCSupplement REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders (
        mealType TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL DEFAULT 0,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE growth_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        babyId INTEGER NOT NULL DEFAULT 1,
        date TEXT NOT NULL,
        heightCm REAL NOT NULL,
        weightKg REAL NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE favorite_combos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        babyId INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        foodsJson TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _seedReminders(db);
  }

  /// v1 → v2 升级：保留老数据（baby id=1、meals 全部归到 baby 1）
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE meals ADD COLUMN babyId INTEGER NOT NULL DEFAULT 1');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS growth_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          babyId INTEGER NOT NULL DEFAULT 1,
          date TEXT NOT NULL,
          heightCm REAL NOT NULL,
          weightKg REAL NOT NULL,
          note TEXT NOT NULL DEFAULT ''
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_combos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          babyId INTEGER NOT NULL DEFAULT 1,
          name TEXT NOT NULL,
          foodsJson TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE baby ADD COLUMN gender TEXT NOT NULL DEFAULT 'male'");
      await db.execute('ALTER TABLE baby ADD COLUMN sizeStatusManual INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE meals ADD COLUMN vitaminASupplement REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE meals ADD COLUMN vitaminCSupplement REAL NOT NULL DEFAULT 0');
    }
  }

  Future<void> _seedReminders(Database db) async {
    await db.insert('reminders', {'mealType': Meal.typeBreakfast, 'enabled': 0, 'hour': 8, 'minute': 0});
    await db.insert('reminders', {'mealType': Meal.typeLunch, 'enabled': 0, 'hour': 12, 'minute': 0});
    await db.insert('reminders', {'mealType': Meal.typeDinner, 'enabled': 0, 'hour': 18, 'minute': 0});
  }

  // ——— 设置项（当前宝宝 id） ———

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ——— 宝宝档案（多宝宝） ———

  Future<List<Baby>> getBabies() async {
    final db = await database;
    final rows = await db.query('baby', orderBy: 'id ASC');
    return rows.map(Baby.fromMap).toList();
  }

  Future<Baby?> getBaby(int id) async {
    final db = await database;
    final rows = await db.query('baby', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Baby.fromMap(rows.first);
  }

  /// 新增/更新宝宝；id 为空则新增，返回新 id
  Future<int> saveBaby(Baby baby) async {
    final db = await database;
    if (baby.id != null) {
      await db.update('baby', baby.toMap(), where: 'id = ?', whereArgs: [baby.id]);
      return baby.id!;
    }
    return db.insert('baby', baby.toMap());
  }

  /// 删除宝宝及其所有关联数据（餐次/成长/组合），并结转当前宝宝
  Future<void> deleteBaby(int id) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('baby', where: 'id = ?', whereArgs: [id]);
    batch.delete('meals', where: 'babyId = ?', whereArgs: [id]);
    batch.delete('growth_records', where: 'babyId = ?', whereArgs: [id]);
    batch.delete('favorite_combos', where: 'babyId = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
  }

  // ——— 每餐记录（按宝宝） ———

  Future<int> insertMeal(Meal meal) async {
    final db = await database;
    return db.insert('meals', meal.toMap());
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await database;
    return db.update('meals', meal.toMap(), where: 'id = ?', whereArgs: [meal.id]);
  }

  Future<int> deleteMeal(int id) async {
    final db = await database;
    return db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Meal?> getMeal(int id) async {
    final db = await database;
    final rows = await db.query('meals', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Meal.fromMap(rows.first);
  }

  /// 查某宝宝某一天的所有餐次，按时间升序
  Future<List<Meal>> getMealsByDate(DateTime date, int babyId) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'meals',
      where: 'babyId = ? AND date >= ? AND date < ?',
      whereArgs: [babyId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return rows.map(Meal.fromMap).toList();
  }

  /// 查某宝宝某段时间 [start, end) 的所有餐次
  Future<List<Meal>> getMealsInRange(DateTime start, DateTime end, int babyId) async {
    final db = await database;
    final rows = await db.query(
      'meals',
      where: 'babyId = ? AND date >= ? AND date < ?',
      whereArgs: [babyId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return rows.map(Meal.fromMap).toList();
  }

  // ——— 成长记录 ———

  Future<int> insertGrowth(GrowthRecord r) async {
    final db = await database;
    return db.insert('growth_records', r.toMap());
  }

  Future<int> deleteGrowth(int id) async {
    final db = await database;
    return db.delete('growth_records', where: 'id = ?', whereArgs: [id]);
  }

  /// 某宝宝的成长记录，按日期升序
  Future<List<GrowthRecord>> getGrowthRecords(int babyId) async {
    final db = await database;
    final rows = await db.query(
      'growth_records',
      where: 'babyId = ?',
      whereArgs: [babyId],
      orderBy: 'date ASC',
    );
    return rows.map(GrowthRecord.fromMap).toList();
  }

  // ——— 常用组合 ———

  Future<int> insertCombo(FavoriteCombo c) async {
    final db = await database;
    return db.insert('favorite_combos', c.toMap());
  }

  Future<int> deleteCombo(int id) async {
    final db = await database;
    return db.delete('favorite_combos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FavoriteCombo>> getCombos(int babyId) async {
    final db = await database;
    final rows = await db.query(
      'favorite_combos',
      where: 'babyId = ?',
      whereArgs: [babyId],
      orderBy: 'id ASC',
    );
    return rows.map(FavoriteCombo.fromMap).toList();
  }

  // ——— 提醒配置 ———

  Future<List<Map<String, Object?>>> getReminders() async {
    final db = await database;
    return db.query('reminders', orderBy: 'mealType ASC');
  }

  Future<int> saveReminder(String mealType, bool enabled, int hour, int minute) async {
    final db = await database;
    return db.update(
      'reminders',
      {'enabled': enabled ? 1 : 0, 'hour': hour, 'minute': minute},
      where: 'mealType = ?',
      whereArgs: [mealType],
    );
  }
}
