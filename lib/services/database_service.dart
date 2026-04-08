import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../providers/settings_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pattern_mind.db');

    print('Initializing database at: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE game_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mode TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        patterns_correct INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        total_score INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertSession({
    required String mode,
    required String difficulty,
    required int patternsCorrect,
    required double accuracy,
    required int totalScore,
  }) async {
    final db = await database;
    return await db.insert('game_stats', {
      'mode': mode,
      'difficulty': difficulty,
      'patterns_correct': patternsCorrect,
      'accuracy': accuracy,
      'total_score': totalScore,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, int>> getHighScores() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT mode, difficulty, MAX(total_score) as max_score 
      FROM game_stats 
      GROUP BY mode, difficulty
    ''');

    final Map<String, int> scores = {};
    for (var row in maps) {
      final key = '${row['mode']}_${row['difficulty']}';
      scores[key] = row['max_score'] as int;
    }
    return scores;
  }

  Future<Map<String, int>> getTotalPatterns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT mode, difficulty, SUM(patterns_correct) as total_patterns 
      FROM game_stats 
      GROUP BY mode, difficulty
    ''');

    final Map<String, int> patterns = {};
    for (var row in maps) {
      final key = '${row['mode']}_${row['difficulty']}';
      patterns[key] = row['total_patterns'] as int;
    }
    return patterns;
  }
}
