import 'dart:convert';
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
      version: 2, // 增加版本号以触发数据库升级
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
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
        analysisTime TEXT,
        ingredients TEXT,
        compliance TEXT,
        processing TEXT,
        claims TEXT
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从版本1升级到版本2，添加缺失的列
      await db.execute('ALTER TABLE analysis_history ADD COLUMN compliance TEXT');
      await db.execute('ALTER TABLE analysis_history ADD COLUMN processing TEXT');
      await db.execute('ALTER TABLE analysis_history ADD COLUMN claims TEXT');
    }
  }

  Future<int> insertAnalysisResult(FoodAnalysisResult result) async {
    final db = await database;
    try {
      // 简化配料数据存储，只存储配料名称列表
      final ingredientsList = result.ingredients.map((ingredient) => ingredient.ingredientName).toList();
      
      return await db.insert('analysis_history', {
        'foodName': result.foodName,
        'healthScore': result.healthScore,
        'overallAssessment': result.overallAssessment,
        'recommendations': result.recommendations,
        'analysisTime': result.analysisTime.toIso8601String(),
        'ingredients': jsonEncode(ingredientsList),
        'compliance': jsonEncode(result.compliance.toMap()),
        'processing': jsonEncode(result.processing.toMap()),
        'claims': jsonEncode(result.claims.toMap()),
      });
    } catch (e) {
      print('数据库插入错误: $e');
      rethrow;
    }
  }

  Future<List<FoodAnalysisResult>> getAnalysisHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('analysis_history', orderBy: 'analysisTime DESC');
    
    return List.generate(maps.length, (i) {
      // 解析配料数据
      List<IngredientAnalysis> ingredients = [];
      try {
        final ingredientsString = maps[i]['ingredients'];
        if (ingredientsString != null && ingredientsString.isNotEmpty) {
          // 解析存储的JSON格式配料名称列表
          final List<dynamic> ingredientNamesDynamic = jsonDecode(ingredientsString);
          
          // 安全地将dynamic转换为String
          final List<String> ingredientNames = ingredientNamesDynamic.map((name) => name.toString()).toList();
          
          // 为每个配料名称创建IngredientAnalysis对象
          for (var ingredientName in ingredientNames) {
            ingredients.add(IngredientAnalysis(
              ingredientName: ingredientName,
              function: '功能信息',
              nutritionalValue: '营养价值信息',
              complianceStatus: '合规',
              processingLevel: '加工度',
              remarks: '备注信息',
            ));
          }
        }
      } catch (e) {
        print('配料数据解析错误: $e');
        // 解析失败时使用默认数据
        ingredients = [IngredientAnalysis(
          ingredientName: '配料数据',
          function: '功能',
          nutritionalValue: '营养价值',
          complianceStatus: '合规',
          processingLevel: '加工度',
          remarks: '分析结果数据',
        )];
      }
      
      // 解析存储的结构化分析数据
      ComplianceAnalysis compliance;
      ProcessingAnalysis processing;
      ClaimsAnalysis claims;
      
      try {
        // 解析合规性数据
        final complianceString = maps[i]['compliance'];
        if (complianceString != null && complianceString.isNotEmpty) {
          // 解析存储的JSON字符串
          final complianceMap = jsonDecode(complianceString);
          compliance = ComplianceAnalysis.fromMap(complianceMap);
        } else {
          compliance = ComplianceAnalysis(
            status: '待确认',
            description: '需要进一步评估合规性',
            issues: [],
          );
        }
        
        // 解析加工度数据
        final processingString = maps[i]['processing'];
        if (processingString != null && processingString.isNotEmpty) {
          // 解析存储的JSON字符串
          final processingMap = jsonDecode(processingString);
          processing = ProcessingAnalysis.fromMap(processingMap);
        } else {
          processing = ProcessingAnalysis(
            level: '中度加工',
            description: '包含多种加工成分',
            score: 3.0,
          );
        }
        
        // 解析特定宣称数据
        final claimsString = maps[i]['claims'];
        if (claimsString != null && claimsString.isNotEmpty) {
          // 解析存储的JSON字符串
          final claimsMap = jsonDecode(claimsString);
          claims = ClaimsAnalysis.fromMap(claimsMap);
        } else {
          claims = ClaimsAnalysis(
            detectedClaims: [],
            supportedClaims: [],
            questionableClaims: [],
            assessment: '未检测到特定宣称',
          );
        }
      } catch (e) {
        print('结构化数据解析错误: $e');
        // 使用默认数据
        compliance = ComplianceAnalysis(
          status: '待确认',
          description: '需要进一步评估合规性',
          issues: [],
        );
        processing = ProcessingAnalysis(
          level: '中度加工',
          description: '包含多种加工成分',
          score: 3.0,
        );
        claims = ClaimsAnalysis(
          detectedClaims: [],
          supportedClaims: [],
          questionableClaims: [],
          assessment: '未检测到特定宣称',
        );
      }
      
      return FoodAnalysisResult(
        foodName: maps[i]['foodName'],
        ingredients: ingredients,
        healthScore: maps[i]['healthScore'],
        overallAssessment: maps[i]['overallAssessment'],
        recommendations: maps[i]['recommendations'],
        analysisTime: DateTime.parse(maps[i]['analysisTime']),
        compliance: compliance,
        processing: processing,
        claims: claims,
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