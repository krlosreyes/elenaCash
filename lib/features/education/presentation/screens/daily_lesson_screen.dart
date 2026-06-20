import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/education_provider.dart';
import '../../data/lessons_seed.dart';
import '../../domain/entities/lesson_entity.dart';

class DailyLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const DailyLessonScreen({super.key, required this.lessonId});

  @override
  ConsumerState<DailyLessonScreen> createState() => _DailyLessonScreenState();
}

class _DailyLessonScreenState extends ConsumerState<DailyLessonScreen> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final progress = ref.watch(educationProgressProvider).asData?.value;
    final allAsync = ref.watch(availableLessonsProvider);

    // Buscar lección — primero en async, si falla usar seed
    final lesson = allAsync.asData?.value.where((l) => l.id == widget.lessonId).firstOrNull
        ?? seedLessons.where((l) => l.id == widget.lessonId).firstOrNull;

    final isAlreadyDone = progress?.completedLessons.contains(widget.lessonId) ?? false;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lección')),
        body: const Center(child: Text('Lección no encontrada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.source.sourceLabel),
        actions: [
          if (isAlreadyDone || _completed)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Source badge ───────────────────────
                  Row(
                    children: [
                      Text(lesson.source.sourceEmoji, style: const TextStyle(fontSize: 20)),
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(lesson.source.sourceLabel,
                            style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                      const Spacer(),
                      Row(children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondaryDark),
                        const Gap(4),
                        Text('~${(lesson.readingSeconds / 60).ceil()} min',
                            style: theme.textTheme.bodySmall),
                      ]),
                    ],
                  ).animate().fadeIn(),
                  const Gap(16),

                  // ── Título ─────────────────────────────
                  Text(lesson.title, style: theme.textTheme.headlineMedium)
                      .animate().fadeIn(delay: 50.ms),
                  const Gap(8),

                  // ── Takeaway ───────────────────────────
                  if (lesson.keyTakeaway != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 18),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              lesson.keyTakeaway!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const Gap(20),
                  ],

                  // ── Contenido (markdown simple) ────────
                  _MarkdownText(content: lesson.content).animate().fadeIn(delay: 150.ms),

                  const Gap(32),
                ],
              ),
            ),
          ),

          // ── Botón completar ──────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: isAlreadyDone || _completed
                    ? ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Completada +10 XP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.8),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          await ref.read(educationProvider.notifier)
                              .completeLesson(widget.lessonId);
                          setState(() => _completed = true);
                        },
                        child: const Text('Marcar como leída ✅ +10 XP'),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renderizador de Markdown simplificado (sin dependencia externa)
class _MarkdownText extends StatelessWidget {
  final String content;
  const _MarkdownText({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3),
              style: theme.textTheme.titleLarge?.copyWith(color: AppColors.textPrimaryDark),
            ),
          );
        } else if (line.startsWith('**') && line.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.replaceAll('**', ''),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          );
        } else if (line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppColors.primary)),
                Expanded(child: Text(line.substring(2), style: theme.textTheme.bodyMedium)),
              ],
            ),
          );
        } else if (line.startsWith('```')) {
          return const SizedBox(height: 8);
        } else if (line.isEmpty) {
          return const Gap(8);
        } else {
          // Procesar **negrita** inline
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _RichLine(line: line, style: theme.textTheme.bodyLarge!),
          );
        }
      }).toList(),
    );
  }
}

class _RichLine extends StatelessWidget {
  final String line;
  final TextStyle style;
  const _RichLine({required this.line, required this.style});

  @override
  Widget build(BuildContext context) {
    // Parsea **texto** como negrita
    final parts = line.split('**');
    if (parts.length == 1) {
      return Text(line, style: style);
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? style.copyWith(fontWeight: FontWeight.w700) : style,
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
