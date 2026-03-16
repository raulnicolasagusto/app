import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'exercise_item.dart';
import 'exercise_store.dart';

class ExerciseDatabase implements ExerciseStore {
  ExerciseDatabase();

  static const String _dbName = 'mathink.db';
  static const int _dbVersion = 1;
  static const String _seedAssetPath = 'assets/seed_exercises.json';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) {
      return _db!;
    }
    final String base = await getDatabasesPath();
    final String path = p.join(base, _dbName);
    debugPrint('EXERCISE_DB_PATH: $path');
    final Database db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
CREATE TABLE exercises (
  id TEXT PRIMARY KEY,
  level_id TEXT NOT NULL,
  topic_id TEXT NOT NULL,
  prompt TEXT NOT NULL,
  expected_final TEXT NOT NULL,
  context_hint TEXT,
  difficulty INTEGER NOT NULL DEFAULT 1,
  used INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL DEFAULT 'seed',
  created_at INTEGER NOT NULL
)
''');
        await db.execute(
          'CREATE INDEX idx_exercises_topic_used ON exercises(topic_id, used)',
        );
        await db.execute(
          'CREATE INDEX idx_exercises_level_topic ON exercises(level_id, topic_id)',
        );
      },
    );
    _db = db;
    await _seedIfEmpty(db);
    return db;
  }

  Future<void> _seedIfEmpty(Database db) async {
    final int count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM exercises'),
        ) ??
        0;
    if (count > 0) {
      return;
    }
    debugPrint('EXERCISE_DB_SEED: inserting seed exercises...');
    final String raw = await rootBundle.loadString(_seedAssetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> rawExercises =
        decoded['exercises'] as List<dynamic>? ?? <dynamic>[];
    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<ExerciseItem> items = rawExercises
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) => ExerciseItem.fromJson(
              <String, dynamic>{
                ...json,
                'source': 'seed',
                'created_at': now,
              },
            ))
        .where((ExerciseItem e) =>
            e.id.trim().isNotEmpty &&
            e.levelId.trim().isNotEmpty &&
            e.topicId.trim().isNotEmpty &&
            e.prompt.trim().isNotEmpty &&
            e.expectedFinal.trim().isNotEmpty)
        .toList(growable: false);

    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final ExerciseItem item in items) {
        batch.insert(
          'exercises',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
    debugPrint('EXERCISE_DB_SEED: done (${items.length} items).');
  }

  Future<void> importTopicFromAsset({
    required String assetPath,
    required String topicId,
    required String levelId,
  }) async {
    final Database db = await _open();
    debugPrint('EXERCISE_IMPORT_ASSET: $assetPath topic=$topicId level=$levelId');
    final String raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>? ?? <String, dynamic>{};
    final List<dynamic> rawExercises =
        decoded['exercises'] as List<dynamic>? ?? <dynamic>[];

    final int now = DateTime.now().millisecondsSinceEpoch;
    final List<ExerciseItem> items = rawExercises
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> json) => ExerciseItem.fromJson(json))
        .where((ExerciseItem e) =>
            e.id.trim().isNotEmpty &&
            e.levelId.trim() == levelId &&
            e.topicId.trim() == topicId &&
            e.prompt.trim().isNotEmpty &&
            e.expectedFinal.trim().isNotEmpty)
        .toList(growable: false);

    await db.transaction((Transaction txn) async {
      for (int i = 0; i < items.length; i++) {
        final ExerciseItem item = items[i];
        final int createdAt = now + i;
        final Map<String, Object?> data = <String, Object?>{
          ...item.toMap(),
          'source': 'asset:$assetPath',
          'created_at': createdAt,
        };

        final List<Map<String, Object?>> existing = await txn.query(
          'exercises',
          columns: <String>['id', 'used'],
          where: 'id = ?',
          whereArgs: <Object?>[item.id],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert(
            'exercises',
            <String, Object?>{
              ...data,
              'used': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          continue;
        }
        final int used = (existing.first['used'] as num?)?.toInt() ?? 0;
        await txn.update(
          'exercises',
          <String, Object?>{
            ...data,
            'used': used,
          },
          where: 'id = ?',
          whereArgs: <Object?>[item.id],
        );
      }
    });
    debugPrint('EXERCISE_IMPORT_ASSET: done (${items.length} items).');
  }

  @override
  Future<List<ExerciseItem>> getUnusedByTopic(
    String topicId, {
    int limit = 5,
  }) async {
    final Database db = await _open();
    final List<Map<String, Object?>> rows = await db.query(
      'exercises',
      where: 'topic_id = ? AND used = 0',
      whereArgs: <Object?>[topicId],
      orderBy: 'created_at ASC, id ASC',
      limit: limit,
    );
    return rows.map(ExerciseItem.fromMap).toList(growable: false);
  }

  Future<void> insertBatch(List<ExerciseItem> exercises) async {
    if (exercises.isEmpty) return;
    final Database db = await _open();
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final ExerciseItem item in exercises) {
        batch.insert(
          'exercises',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> markAsUsed(String id) async {
    final Database db = await _open();
    await db.update(
      'exercises',
      <String, Object?>{'used': 1},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<Map<String, int>> countUnusedByTopicIds(List<String> topicIds) async {
    if (topicIds.isEmpty) {
      return <String, int>{};
    }
    final Database db = await _open();
    final String placeholders = List<String>.filled(topicIds.length, '?').join(',');
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
SELECT topic_id, COUNT(*) AS cnt
FROM exercises
WHERE used = 0 AND topic_id IN ($placeholders)
GROUP BY topic_id
''',
      topicIds,
    );
    final Map<String, int> result = <String, int>{};
    for (final Map<String, Object?> row in rows) {
      final String key = (row['topic_id'] ?? '').toString();
      final int cnt = (row['cnt'] as num?)?.toInt() ?? 0;
      if (key.isNotEmpty) {
        result[key] = cnt;
      }
    }
    return result;
  }

  @override
  Future<void> resetUsedByTopic(String topicId) async {
    final Database db = await _open();
    await db.update(
      'exercises',
      <String, Object?>{'used': 0},
      where: 'topic_id = ?',
      whereArgs: <Object?>[topicId],
    );
  }

  Future<void> dispose() async {
    final Database? db = _db;
    _db = null;
    if (db != null) {
      await db.close();
    }
  }
}
