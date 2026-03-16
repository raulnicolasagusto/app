import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../curriculum/curriculum_models.dart';
import '../curriculum/curriculum_service.dart';
import '../exercises/exercise_repository.dart';
import '../math_canvas_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({
    super.key,
    required this.levelId,
  });

  final String levelId;

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final CurriculumService _curriculum = const CurriculumService();
  final ExerciseRepository _repo = ExerciseRepository();

  Map<String, int> _unusedCounts = <String, int>{};
  bool _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _ensureTopicSeedsThenLoadCounts();
  }

  Future<void> _ensureTopicSeedsThenLoadCounts() async {
    final List<CurriculumTopic> topics = _curriculum.topicsByLevel(widget.levelId);
    for (final CurriculumTopic topic in topics) {
      final String? asset = topic.seedAssetPath;
      if (asset == null || asset.trim().isEmpty) {
        continue;
      }
      try {
        await _repo.importTopicFromAsset(
          assetPath: asset,
          topicId: topic.id,
          levelId: topic.levelId,
        );
      } catch (_) {
        // Ignore seed failures and still show UI; counts may remain 0.
      }
    }
    await _loadCounts();
  }

  Future<void> _loadCounts() async {
    final List<CurriculumTopic> topics = _curriculum.topicsByLevel(widget.levelId);
    final List<String> topicIds = topics.map((CurriculumTopic t) => t.id).toList(growable: false);
    try {
      final Map<String, int> counts = await _repo.countUnusedByTopicIds(topicIds);
      if (!mounted) return;
      setState(() {
        _unusedCounts = counts;
        _loadingCounts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unusedCounts = <String, int>{};
        _loadingCounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final CurriculumLevel? level = _curriculum.levelById(widget.levelId);
    final String title = level == null ? 'Topics' : _curriculum.localizeName(level.names, locale);
    final List<CurriculumTopic> topics = _curriculum.topicsByLevel(widget.levelId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundLight.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.black12),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _loadingCounts ? null : _ensureTopicSeedsThenLoadCounts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final CurriculumTopic topic = topics[index];
          final String name = _curriculum.localizeName(topic.names, locale);
          final int unused = _unusedCounts[topic.id] ?? 0;
          final bool enabled = !_loadingCounts && unused > 0;

          return Opacity(
            opacity: enabled ? 1 : 0.6,
            child: InkWell(
              onTap: enabled
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MathCanvasScreen(
                            levelId: topic.levelId,
                            topicId: topic.id,
                            topicDisplayName: name,
                            seedAssetPath: topic.seedAssetPath,
                          ),
                        ),
                      );
                    }
                  : null,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: enabled ? const Color(0xFF22C55E) : Colors.black26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              enabled ? '$unused exercises available' : 'Coming soon',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            _DifficultyDots(value: topic.difficulty),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final int v = value.clamp(1, 5);
    return Row(
      children: List<Widget>.generate(5, (int index) {
        final bool on = index < v;
        return Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
          decoration: BoxDecoration(
            color: on ? AppTheme.neonPurple : Colors.black12,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
