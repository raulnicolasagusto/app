import 'package:flutter/material.dart';

class CurriculumLevel {
  const CurriculumLevel({
    required this.id,
    required this.names,
    required this.icon,
    required this.topics,
  });

  final String id;
  final Map<String, String> names;
  final IconData icon;
  final List<CurriculumTopic> topics;
}

class CurriculumTopic {
  const CurriculumTopic({
    required this.id,
    required this.levelId,
    required this.names,
    required this.difficulty,
    required this.promptHint,
    this.seedAssetPath,
  });

  final String id;
  final String levelId;
  final Map<String, String> names;
  final int difficulty;
  final String promptHint;
  final String? seedAssetPath;
}
