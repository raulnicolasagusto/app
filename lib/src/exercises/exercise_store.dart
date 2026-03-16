import 'exercise_item.dart';

abstract class ExerciseStore {
  Future<List<ExerciseItem>> getUnusedByTopic(
    String topicId, {
    int limit,
  });

  Future<void> markAsUsed(String id);

  Future<Map<String, int>> countUnusedByTopicIds(List<String> topicIds);

  Future<void> resetUsedByTopic(String topicId);
}

