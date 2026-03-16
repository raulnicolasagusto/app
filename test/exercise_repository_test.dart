import 'package:app/src/exercises/exercise_item.dart';
import 'package:app/src/exercises/exercise_repository.dart';
import 'package:app/src/exercises/exercise_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements ExerciseStore {
  _FakeStore(this.items);

  final List<ExerciseItem> items;
  final Set<String> usedIds = <String>{};

  @override
  Future<List<ExerciseItem>> getUnusedByTopic(
    String topicId, {
    int limit = 5,
  }) async {
    final List<ExerciseItem> filtered = items
        .where((ExerciseItem e) => e.topicId == topicId && !usedIds.contains(e.id))
        .take(limit)
        .toList(growable: false);
    return filtered;
  }

  @override
  Future<void> markAsUsed(String id) async {
    usedIds.add(id);
  }

  @override
  Future<Map<String, int>> countUnusedByTopicIds(List<String> topicIds) async {
    final Map<String, int> result = <String, int>{};
    for (final String topicId in topicIds) {
      result[topicId] = items
          .where((ExerciseItem e) => e.topicId == topicId && !usedIds.contains(e.id))
          .length;
    }
    return result;
  }

  @override
  Future<void> resetUsedByTopic(String topicId) async {
    for (final ExerciseItem e in items) {
      if (e.topicId == topicId) {
        usedIds.remove(e.id);
      }
    }
  }
}

void main() {
  test('ExerciseRepository returns next and marks used', () async {
    final List<ExerciseItem> items = <ExerciseItem>[
      ExerciseItem(
        id: 'a',
        levelId: 'primary',
        topicId: 't1',
        prompt: '2x+5=17',
        expectedFinal: 'x=6',
        contextHint: null,
        difficulty: 1,
        used: false,
        source: 'seed',
        createdAt: 1,
      ),
      ExerciseItem(
        id: 'b',
        levelId: 'primary',
        topicId: 't1',
        prompt: '5x+3=28',
        expectedFinal: 'x=5',
        contextHint: null,
        difficulty: 1,
        used: false,
        source: 'seed',
        createdAt: 2,
      ),
    ];
    final _FakeStore store = _FakeStore(items);
    final ExerciseRepository repo = ExerciseRepository(database: store);

    final ExerciseItem first = await repo.getNextByTopic(topicId: 't1', levelId: 'primary');
    expect(first.id, 'a');
    expect(store.usedIds.contains('a'), isTrue);
  });

  test('ExerciseRepository resets used when exhausted', () async {
    final List<ExerciseItem> items = <ExerciseItem>[
      ExerciseItem(
        id: 'a',
        levelId: 'primary',
        topicId: 't1',
        prompt: '2x+5=17',
        expectedFinal: 'x=6',
        contextHint: null,
        difficulty: 1,
        used: false,
        source: 'seed',
        createdAt: 1,
      ),
    ];
    final _FakeStore store = _FakeStore(items);
    final ExerciseRepository repo = ExerciseRepository(database: store);

    await repo.getNextByTopic(topicId: 't1', levelId: 'primary');
    expect(store.usedIds.contains('a'), isTrue);

    final ExerciseItem again = await repo.getNextByTopic(topicId: 't1', levelId: 'primary');
    expect(again.id, 'a');
  });
}
