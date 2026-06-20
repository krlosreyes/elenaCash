import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../providers/education_provider.dart';
import '../../domain/entities/lesson_entity.dart';

class EducationHomeScreen extends ConsumerWidget {
  const EducationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(educationProgressProvider);
    final progress = progressAsync.asData?.value;
    final weeklyLessonAsync = ref.watch(weeklyLessonProvider);
    final allLessonsAsync = ref.watch(availableLessonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aprende')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(availableLessonsProvider);
          ref.invalidate(educationProgressProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // ── Stats racha ────────────────────────────
            _StreakCard(
              streakDays: progress?.dailyStreakDays ?? 0,
              totalXP: progress?.totalXP ?? 0,
              completedCount: progress?.completedLessons.length ?? 0,
            ).animate().fadeIn(),
            const Gap(20),

            // ── Lección de la semana ───────────────────
            Text('Lección de la semana', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 100.ms),
            const Gap(12),
            weeklyLessonAsync.when(
              data: (lesson) => lesson == null
                  ? const SizedBox()
                  : _FeaturedLessonCard(
                      lesson: lesson,
                      isCompleted: progress?.completedLessons.contains(lesson.id) ?? false,
                    ).animate().fadeIn(delay: 150.ms),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),

            const Gap(24),

            // ── Todas las lecciones ─────────────────────
            Text('Todas las lecciones', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 200.ms),
            const Gap(12),

            allLessonsAsync.when(
              data: (lessons) => Column(
                children: lessons.asMap().entries.map((e) {
                  final lesson = e.value;
                  final done = progress?.completedLessons.contains(lesson.id) ?? false;
                  return _LessonRow(
                    lesson: lesson,
                    isCompleted: done,
                    onTap: () => context.push('${AppRoutes.education}/${lesson.id}'),
                  ).animate().fadeIn(delay: Duration(milliseconds: 220 + e.key * 40));
                }).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streakDays, totalXP, completedCount;
  const _StreakCard({required this.streakDays, required this.totalXP, required this.completedCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySurface, Color(0xFF003320)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: '$streakDays', label: 'días de racha', emoji: '🔥'),
          _Stat(value: '$totalXP XP', label: 'puntos ganados', emoji: '⭐'),
          _Stat(value: '$completedCount', label: 'lecciones', emoji: '📚'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label, emoji;
  const _Stat({required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const Gap(4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
      ],
    );
  }
}

class _FeaturedLessonCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isCompleted;
  const _FeaturedLessonCard({required this.lesson, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.education}/${lesson.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary.withOpacity(0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: isCompleted ? AppColors.primary.withOpacity(0.4) : AppColors.primary.withOpacity(0.2),
            width: isCompleted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(lesson.source.sourceEmoji, style: const TextStyle(fontSize: 24)),
                const Gap(8),
                Text(lesson.source.sourceLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                const Spacer(),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                if (lesson.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('PRO', style: TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const Gap(8),
            Text(lesson.title, style: theme.textTheme.titleLarge),
            if (lesson.keyTakeaway != null) ...[
              const Gap(6),
              Text(lesson.keyTakeaway!, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const Gap(12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondaryDark),
                const Gap(4),
                Text('~${(lesson.readingSeconds / 60).ceil()} min',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(isCompleted ? '✅ Completada' : 'Leer →',
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted ? AppColors.primary : AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final LessonEntity lesson;
  final bool isCompleted;
  final VoidCallback onTap;
  const _LessonRow({required this.lesson, required this.isCompleted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary.withOpacity(0.15) : theme.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted ? AppColors.primary : theme.dividerColor,
          ),
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
              : Text(lesson.source.sourceEmoji),
        ),
      ),
      title: Text(lesson.title, style: theme.textTheme.bodyMedium?.copyWith(
        color: isCompleted ? AppColors.textSecondaryDark : null,
        decoration: isCompleted ? TextDecoration.none : null,
      )),
      subtitle: Text('${lesson.source.sourceLabel} · ~${(lesson.readingSeconds / 60).ceil()} min',
          style: theme.textTheme.bodySmall),
      trailing: lesson.isPremium
          ? const Text('PRO', style: TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w700))
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
