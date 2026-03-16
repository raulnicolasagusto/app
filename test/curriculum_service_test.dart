import 'package:app/src/curriculum/curriculum_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CurriculumService languageCode falls back to en', () {
    const CurriculumService service = CurriculumService();
    expect(service.languageCode(const Locale('es', 'AR')), 'es');
    expect(service.languageCode(const Locale('pt', 'BR')), 'pt');
    expect(service.languageCode(const Locale('en', 'US')), 'en');
    expect(service.languageCode(const Locale('fr', 'FR')), 'en');
  });

  test('CurriculumService localizeName uses en fallback', () {
    const CurriculumService service = CurriculumService();
    const Map<String, String> names = <String, String>{'en': 'High School', 'es': 'Secundaria'};
    expect(service.localizeName(names, const Locale('es')), 'Secundaria');
    expect(service.localizeName(names, const Locale('pt')), 'High School');
  });
}

