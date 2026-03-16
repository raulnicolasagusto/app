class ExerciseItem {
  const ExerciseItem({
    required this.id,
    required this.levelId,
    required this.topicId,
    required this.prompt,
    required this.expectedFinal,
    required this.contextHint,
    required this.difficulty,
    required this.used,
    required this.source,
    required this.createdAt,
  });

  factory ExerciseItem.fromMap(Map<String, Object?> map) {
    return ExerciseItem(
      id: (map['id'] ?? '').toString(),
      levelId: (map['level_id'] ?? '').toString(),
      topicId: (map['topic_id'] ?? '').toString(),
      prompt: (map['prompt'] ?? '').toString(),
      expectedFinal: (map['expected_final'] ?? '').toString(),
      contextHint: map['context_hint']?.toString(),
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      used: ((map['used'] as num?)?.toInt() ?? 0) == 1,
      source: (map['source'] ?? 'seed').toString(),
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: (json['id'] ?? '').toString(),
      levelId: (json['level_id'] ?? '').toString(),
      topicId: (json['topic_id'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      expectedFinal: (json['expected_final'] ?? '').toString(),
      contextHint: json['context_hint']?.toString(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      used: json['used'] == true,
      source: (json['source'] ?? 'seed').toString(),
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String levelId;
  final String topicId;
  final String prompt;
  final String expectedFinal;
  final String? contextHint;
  final int difficulty;
  final bool used;
  final String source;
  final int createdAt;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'level_id': levelId,
      'topic_id': topicId,
      'prompt': prompt,
      'expected_final': expectedFinal,
      'context_hint': contextHint,
      'difficulty': difficulty,
      'used': used ? 1 : 0,
      'source': source,
      'created_at': createdAt,
    };
  }
}

