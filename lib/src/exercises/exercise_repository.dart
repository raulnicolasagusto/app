import 'package:flutter/foundation.dart';

import 'exercise_database.dart';
import 'exercise_item.dart';
import 'exercise_store.dart';

class NoExercisesForTopicException implements Exception {
  const NoExercisesForTopicException(this.topicId);

  final String topicId;

  @override
  String toString() => 'No exercises found for topic=$topicId';
}

class ExerciseRepository {
  ExerciseRepository({ExerciseStore? database}) : _db = database ?? ExerciseDatabase();

  final ExerciseStore _db;
  ExerciseDatabase? get _dbAsDatabase => _db is ExerciseDatabase ? _db : null;

  Future<void> importTopicFromAsset({
    required String assetPath,
    required String topicId,
    required String levelId,
  }) async {
    final ExerciseDatabase? db = _dbAsDatabase;
    if (db == null) {
      return;
    }
    await db.importTopicFromAsset(
      assetPath: assetPath,
      topicId: topicId,
      levelId: levelId,
    );
  }

  Future<ExerciseItem> getNextByTopic({
    required String topicId,
    required String levelId,
  }) async {
    debugPrint('EXERCISE_NEXT: topic=$topicId level=$levelId');
    List<ExerciseItem> cached = await _db.getUnusedByTopic(topicId, limit: 1);
    if (cached.isEmpty) {
      await _db.resetUsedByTopic(topicId);
      cached = await _db.getUnusedByTopic(topicId, limit: 1);
    }
    if (cached.isEmpty) {
      throw NoExercisesForTopicException(topicId);
    }
    final ExerciseItem picked = cached.first;
    await _db.markAsUsed(picked.id);
    return picked;
  }

  Future<Map<String, int>> countUnusedByTopicIds(List<String> topicIds) {
    return _db.countUnusedByTopicIds(topicIds);
  }
}
