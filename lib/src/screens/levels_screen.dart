import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../curriculum/curriculum_models.dart';
import '../curriculum/curriculum_service.dart';
import 'topics_screen.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CurriculumService curriculum = const CurriculumService();
    final Locale locale = Localizations.localeOf(context);
    final List<CurriculumLevel> levels = curriculum.levels();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Curriculum'),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundLight.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: levels.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final CurriculumLevel level = levels[index];
          final String title = curriculum.localizeName(level.names, locale);
          final _LevelStyle style = _levelStyle(level.id);
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TopicsScreen(levelId: level.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[style.a, style.b],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(level.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${level.topics.length} topics',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textMuted,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelStyle {
  const _LevelStyle(this.a, this.b);

  final Color a;
  final Color b;
}

_LevelStyle _levelStyle(String levelId) {
  switch (levelId) {
    case 'primary':
      return const _LevelStyle(AppTheme.neonBlue, Color(0xFF22D3EE));
    case 'secondary':
      return const _LevelStyle(AppTheme.neonPurple, AppTheme.neonBlue);
    case 'university':
      return const _LevelStyle(Color(0xFF111827), Color(0xFF334155));
  }
  return const _LevelStyle(AppTheme.neonBlue, AppTheme.neonPurple);
}
