import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ingredient_analysis.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ingredient_detective.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE analysis_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        foodName TEXT,
        healthScore REAL,
        overallAssessment TEXT,
        recommendations TEXT,
        standardUsed TEXT,
        analysisTime TEXT,
        ingredients TEXT
      )
    ''');
  }

  Future<int> insertAnalysisResult(FoodAnalysisResult result) async {
    final db = await database;
    return await db.insert('analysis_history', {
      'foodName': result.foodName,
      'healthScore': result.healthScore,
      'overallAssessment': result.overallAssessment,
      'recommendations': result.recommendations,
      'standardUsed': result.standardUsed,
      'analysisTime': result.analysisTime.toIso8601String(),
      'ingredients': result.ingredients.map((ingredient) => ingredient.toMap()).toList().toString(),
    });
  }

  Future<List<FoodAnalysisResult>> getAnalysisHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('analysis_history', orderBy: 'analysisTime DESC');
    
    return List.generate(maps.length, (i) {
      return FoodAnalysisResult(
        foodName: maps[i]['foodName'],
        ingredients: [], // 简化处理，实际应用中需要解析JSON字符串
        healthScore: maps[i]['healthScore'],
        overallAssessment: maps[i]['overallAssessment'],
        recommendations: maps[i]['recommendations'],
        standardUsed: maps[i]['standardUsed'],
        analysisTime: DateTime.parse(maps[i]['analysisTime']),
      );
    });
  }

  Future<int> deleteAnalysisResult(int id) async {
    final db = await database;
    return await db.delete('analysis_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}