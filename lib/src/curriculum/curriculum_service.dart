import 'package:flutter/widgets.dart';

import 'curriculum_data.dart';
import 'curriculum_models.dart';

class CurriculumService {
  const CurriculumService();

  List<CurriculumLevel> levels() => kCurriculumLevels;

  CurriculumLevel? levelById(String levelId) {
    for (final CurriculumLevel level in kCurriculumLevels) {
      if (level.id == levelId) return level;
    }
    return null;
  }

  List<CurriculumTopic> topicsByLevel(String levelId) {
    return levelById(levelId)?.topics ?? <CurriculumTopic>[];
  }

  String languageCode(Locale locale) {
    final String code = locale.languageCode.toLowerCase();
    if (code == 'es' || code == 'pt' || code == 'en') {
      return code;
    }
    return 'en';
  }

  String localizeName(Map<String, String> names, Locale locale) {
    final String code = languageCode(locale);
    return names[code] ?? names['en'] ?? names.values.first;
  }
}

