import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../providers/education_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/certificate_widget.dart';
import '../../domain/entities/lesson_entity.dart';
import '../../domain/entities/quiz_entity.dart';

class EducationHomeScreen extends ConsumerWidget {
  const EducationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(educationProgressProvider);
    final progress = progressAsync.asData?.value;
    final weeklyLessonAsync = ref.watch(weeklyLessonProvider);
    final allLessonsAsync = ref.watch(availableLessonsProvider);
    final quizzesAsync = ref.watch(availableQuizzesProvider);
    final attemptsAsync = ref.watch(quizAttemptsProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

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
            const Gap(32),

            // ── Quizzes ─────────────────────────────────────
            Text('Pon a prueba tu conocimiento', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 300.ms),
            const Gap(4),
            Text(
              'Responde correctamente y gana XP extra.',
              style: theme.textTheme.bodySmall,
            ).animate().fadeIn(delay: 340.ms),
            const Gap(12),

            quizzesAsync.when(
              data: (quizzes) {
                final attempts = attemptsAsync.asData?.value ?? [];
                return Column(
                  children: quizzes.asMap().entries.map((e) {
                    final quiz = e.value;
                    final lastAttempt = attempts
                        .where((a) => a.quizId == quiz.id)
                        .firstOrNull;
                    return _QuizCard(
                      quiz: quiz,
                      lastAttempt: lastAttempt,
                      onTap: () => context.push('${AppRoutes.education}/quiz/${quiz.id}'),
                    ).animate().fadeIn(delay: Duration(milliseconds: (360 + e.key * 60).toInt()));
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const Gap(32),

            // ── Leaderboard ──────────────────────────────────────────
            Text('🏆 Top 10 de XP', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 400.ms),
            const Gap(4),
            Text(
              'Usuarios anónimos ordenados por puntos totales.',
              style: theme.textTheme.bodySmall,
            ).animate().fadeIn(delay: 420.ms),
            const Gap(12),

            leaderboardAsync.when(
              data: (entries) => entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        '¡Sé el primero en el ranking!',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: entries.asMap().entries.map((e) {
                        return _LeaderboardRow(
                          rank: e.key + 1,
                          entry: e.value,
                          isCurrentUser: e.value.userId == currentUserId,
                        ).animate().fadeIn(
                            delay: Duration(milliseconds: 440 + e.key * 40));
                      }).toList(),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const Gap(32),

            // ── Certificado ──────────────────────────────────────────
            quizzesAsync.when(
              data: (quizzes) {
                final attempts = attemptsAsync.asData?.value ?? [];
                return CertificateSection(
                  quizzes: quizzes,
                  attempts: attempts,
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
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

class _QuizCard extends StatelessWidget {
  final QuizEntity quiz;
  final QuizAttemptEntity? lastAttempt;
  final VoidCallback onTap;
  const _QuizCard({required this.quiz, this.lastAttempt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempted = lastAttempt != null;
    final passed = lastAttempt?.passed ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: passed
                ? AppColors.primary.withOpacity(0.4)
                : theme.dividerColor,
            width: passed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(quiz.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(quiz.topic.label,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.primary, fontSize: 11)),
                      if (attempted) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: passed
                                ? AppColors.primary.withOpacity(0.1)
                                : const Color(0xFFD85A30).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${lastAttempt!.score}/${lastAttempt!.totalQuestions}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: passed ? AppColors.primary : const Color(0xFFD85A30),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(2),
                  Text(quiz.title, style: theme.textTheme.titleMedium),
                  Text(quiz.description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${quiz.xpReward} XP',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Icon(
                  passed ? Icons.replay_rounded : Icons.play_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
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

// ── Leaderboard Row ───────────────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  /// Emoji determinístico basado en userId — anónimo pero consistente.
  String _avatar(String userId) {
    const emojis = [
      '🦊', '🐼', '🦁', '🐸', '🦉', '🐬', '🦋', '🐧',
      '🦚', '🦜', '🐙', '🦄', '🐺', '🦝', '🦔', '🐻',
    ];
    final code = userId.codeUnits.fold(0, (a, b) => a + b);
    return emojis[code % emojis.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = rank <= 3;
    final rankEmojis = ['🥇', '🥈', '🥉'];
    final rankLabel = isTop3 ? rankEmojis[rank - 1] : '#$rank';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.4)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Posición
          SizedBox(
            width: 36,
            child: Text(
              rankLabel,
              style: TextStyle(
                fontSize: isTop3 ? 20 : 14,
                fontWeight: FontWeight.w700,
                color: isTop3 ? null : AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Gap(10),
          // Avatar emoji
          Text(_avatar(entry.userId), style: const TextStyle(fontSize: 24)),
          const Gap(10),
          // Nombre
          Expanded(
            child: Text(
              isCurrentUser ? 'Tú' : 'Usuario anónimo',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w400,
                color: isCurrentUser ? AppColors.primary : null,
              ),
            ),
          ),
          // XP
          Text(
            '${entry.totalXP} XP',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
