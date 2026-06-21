import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/quizzes_seed.dart';
import '../../domain/entities/quiz_entity.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late QuizEntity _quiz;
  int _current = 0;
  int? _selected;
  bool _answered = false;
  int _correctCount = 0;
  bool _finished = false;
  QuizAttemptEntity? _result;

  @override
  void initState() {
    super.initState();
    _quiz = seedQuizzes.firstWhere(
      (q) => q.id == widget.quizId,
      orElse: () => seedQuizzes.first,
    );
  }

  QuizQuestion get _question => _quiz.questions[_current];

  void _select(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      if (_question.isCorrect(idx)) _correctCount++;
    });
  }

  void _next() {
    if (_current < _quiz.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final notifier = ref.read(quizNotifierProvider.notifier);
    final attempt = await notifier.submitQuiz(
      quizId: _quiz.id,
      score: _correctCount,
      totalQuestions: _quiz.questions.length,
    );
    setState(() {
      _finished = true;
      _result = attempt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz.title),
        bottom: _finished
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: (_current + (_answered ? 1 : 0)) / _quiz.questions.length,
                  backgroundColor: AppColors.primarySurface,
                  color: AppColors.primary,
                ),
              ),
      ),
      body: _finished
          ? _ResultView(
              quiz: _quiz,
              correct: _correctCount,
              total: _quiz.questions.length,
              result: _result,
              onRetry: () => setState(() {
                _current = 0;
                _selected = null;
                _answered = false;
                _correctCount = 0;
                _finished = false;
                _result = null;
              }),
            )
          : _QuestionView(
              question: _question,
              questionNumber: _current + 1,
              totalQuestions: _quiz.questions.length,
              selected: _selected,
              answered: _answered,
              onSelect: _select,
              onNext: _next,
              isLast: _current == _quiz.questions.length - 1,
            ),
    );
  }
}

// ── Question View ─────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  final QuizQuestion question;
  final int questionNumber, totalQuestions;
  final int? selected;
  final bool answered;
  final void Function(int) onSelect;
  final VoidCallback onNext;
  final bool isLast;

  const _QuestionView({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.selected,
    required this.answered,
    required this.onSelect,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregunta número
            Text(
              'Pregunta $questionNumber de $totalQuestions',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
            const Gap(12),

            // Texto de la pregunta
            Text(
              question.question,
              style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
            ).animate().fadeIn(duration: 300.ms),
            const Gap(24),

            // Opciones
            ...question.options.asMap().entries.map((e) {
              final idx = e.key;
              final opt = e.value;
              return _OptionTile(
                text: opt,
                index: idx,
                selected: selected,
                answered: answered,
                correctIndex: question.correctIndex,
                onTap: () => onSelect(idx),
              )
                  .animate(key: ValueKey('opt_$idx'))
                  .fadeIn(delay: Duration(milliseconds: idx * 60))
                  .slideX(begin: 0.03, end: 0);
            }),

            // Explicación
            if (answered) ...[
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected == question.correctIndex
                      ? AppColors.primary.withOpacity(0.08)
                      : const Color(0xFFD85A30).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == question.correctIndex
                        ? AppColors.primary.withOpacity(0.3)
                        : const Color(0xFFD85A30).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected == question.correctIndex ? '✅ ¡Correcto!' : '❌ Incorrecto',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected == question.correctIndex
                            ? AppColors.primary
                            : const Color(0xFFD85A30),
                      ),
                    ),
                    const Gap(6),
                    Text(question.explanation,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            ],

            const Spacer(),

            if (answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: Text(isLast ? 'Ver resultado' : 'Siguiente →'),
                ).animate().fadeIn(delay: 200.ms),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final int index, correctIndex;
  final int? selected;
  final bool answered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.index,
    required this.correctIndex,
    required this.selected,
    required this.answered,
    required this.onTap,
  });

  Color _bg(BuildContext context) {
    if (!answered) return Theme.of(context).cardColor;
    if (index == correctIndex) return AppColors.primary.withOpacity(0.12);
    if (selected == index) return const Color(0xFFD85A30).withOpacity(0.12);
    return Theme.of(context).cardColor;
  }

  Color _border() {
    if (!answered) return Colors.transparent;
    if (index == correctIndex) return AppColors.primary;
    if (selected == index) return const Color(0xFFD85A30);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  ['A', 'B', 'C', 'D'][index],
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (answered && index == correctIndex)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            if (answered && selected == index && index != correctIndex)
              const Icon(Icons.cancel_rounded, color: Color(0xFFD85A30), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Result View ───────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final QuizEntity quiz;
  final int correct, total;
  final QuizAttemptEntity? result;
  final VoidCallback onRetry;

  const _ResultView({
    required this.quiz,
    required this.correct,
    required this.total,
    required this.result,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = total > 0 ? correct / total : 0.0;
    final passed = pct >= 0.6;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              passed ? '🏆' : '📚',
              style: const TextStyle(fontSize: 72),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const Gap(16),
            Text(
              result?.grade ?? (passed ? '✅ Aprobado' : '📚 Sigue estudiando'),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              '$correct de $total respuestas correctas (${(pct * 100).toStringAsFixed(0)}%)',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (result != null) ...[
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '+${result!.xpEarned} XP ganados',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const Gap(40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver a Academia'),
              ),
            ),
            const Gap(12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
