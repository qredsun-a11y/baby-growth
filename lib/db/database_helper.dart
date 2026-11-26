import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/baby.dart';
import '../models/meal.dart';

/// 本地数据库封装（sqflite）。
/// 所有数据存在 App 私有目录，不联网、不上传。
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  static const _dbName = 'baby_nutrition.db';
  static const _dbVersion = 1;

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 宝宝档案表：V1 只用一行（id=1）
    await db.execute('''
      CREATE TABLE baby (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        birthDate TEXT NOT NULL,
        heightCm REAL NOT NULL,
        weightKg REAL NOT NULL,
        allergies TEXT NOT NULL DEFAULT '',
        sizeStatus TEXT NOT NULL DEFAULT 'normal',
        ironRisk INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // 每餐记录表
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealType TEXT NOT NULL,
        date TEXT NOT NULL,
        foodsJson TEXT NOT NULL,
        photoPath TEXT,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    // 提醒配置表：每个餐次一行（早/午/晚），含开关和时间
    await db.execute('''
      CREATE TABLE reminders (
        mealType TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL DEFAULT 0,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL
      )
    ''');
    // 预置三条默认提醒时间（默认关闭，用户到设置页开启）
    await db.insert('reminders', {'mealType': Meal.typeBreakfast, 'enabled': 0, 'hour': 8, 'minute': 0});
    await db.insert('reminders', {'mealType': Meal.typeLunch, 'enabled': 0, 'hour': 12, 'minute': 0});
    await db.insert('reminders', {'mealType': Meal.typeDinner, 'enabled': 0, 'hour': 18, 'minute': 0});
  }

  // ——— 宝宝档案 ———

  Future<Baby?> getBaby() async {
    final db = await database;
    final rows = await db.query('baby', where: 'id = 1');
    if (rows.isEmpty) return null;
    return Baby.fromMap(rows.first);
  }

  Future<int> saveBaby(Baby baby) async {
    final db = await database;
    final map = baby.toMap();
    map['id'] = 1;
    return db.insert('baby', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ——— 每餐记录 ———

  Future<int> insertMeal(Meal meal) async {
    final db = await database;
    return db.insert('meals', meal.toMap());
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await database;
    return db.update('meals', meal.toMap(),
        where: 'id = ?', whereArgs: [meal.id]);
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

  /// 查某一天的所有餐次，按时间升序
  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await db.query(
      'meals',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return rows.map(Meal.fromMap).toList();
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
