import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/monthly_review_provider.dart';
import '../../domain/entities/monthly_review_entity.dart';

class MonthlyReviewScreen extends ConsumerStatefulWidget {
  const MonthlyReviewScreen({super.key});

  @override
  ConsumerState<MonthlyReviewScreen> createState() => _MonthlyReviewScreenState();
}

class _MonthlyReviewScreenState extends ConsumerState<MonthlyReviewScreen> {
  final _noteCtrl = TextEditingController();
  final _winCtrl = TextEditingController();
  final _improveCtrl = TextEditingController();
  List<String> _wins = [];
  List<String> _improvements = [];
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _winCtrl.dispose();
    _improveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final monthKey = DateHelpers.currentMonthKey();
    final reviewAsync = ref.watch(currentMonthReviewProvider);
    final review = reviewAsync.asData?.value;
    final historyAsync = ref.watch(monthlyReviewHistoryProvider);
    final history = historyAsync.asData?.value ?? [];
    // Previous month = first completed snapshot that isn't the current month
    final prev = history.where((r) => r.monthKey != monthKey && r.isCompleted).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('Revisión ${DateHelpers.formatMonth(DateTime.now())}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score de salud ─────────────────────────
            if (review != null) ...[
              _HealthScoreCard(review: review, currency: currency)
                  .animate().fadeIn(),
              const Gap(20),

              // ── Insights automáticos ───────────────
              _AutoInsightsCard(current: review, previous: prev)
                  .animate().fadeIn(delay: 80.ms),
              const Gap(16),

              // ── Cubos del mes ──────────────────────
              Text('Cómo quedaron tus cubos', style: theme.textTheme.titleLarge)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(12),
              _BucketResultRow(
                label: '🏠 Gastos Fijos',
                actual: review.fixedCostsActual,
                budget: review.fixedCostsBudget,
                prevActual: prev?.fixedCostsActual,
                currency: currency,
                lowerIsBetter: true,
              ).animate().fadeIn(delay: 150.ms),
              _BucketResultRow(
                label: '🏦 Ahorro',
                actual: review.savingsActual,
                budget: review.savingsBudget,
                prevActual: prev?.savingsActual,
                currency: currency,
                lowerIsBetter: false,
              ).animate().fadeIn(delay: 175.ms),
              _BucketResultRow(
                label: '📈 Inversiones',
                actual: review.investmentsActual,
                budget: review.investmentsBudget,
                prevActual: prev?.investmentsActual,
                currency: currency,
                lowerIsBetter: false,
              ).animate().fadeIn(delay: 200.ms),
              _BucketResultRow(
                label: '🎉 Gasto Libre',
                actual: review.guiltFreeActual,
                budget: review.guiltFreeBudget,
                prevActual: prev?.guiltFreeActual,
                currency: currency,
                lowerIsBetter: false,
              ).animate().fadeIn(delay: 225.ms),

              const Gap(20),
            ] else ...[
              // Sin snapshot — mes en curso vacío
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: Column(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 48)),
                    const Gap(8),
                    Text('El snapshot del mes se genera automáticamente.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium),
                    const Gap(12),
                    Text(
                      'Mientras tanto, registra tus gastos reales en cada cubo del Plan Consciente.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ).animate().fadeIn(),
              const Gap(20),
            ],

            // ── Logros del mes ──────────────────────────
            Text('🏆 ¿Qué salió bien este mes?', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 250.ms),
            const Gap(8),
            ..._wins.map((w) => _TagChip(text: w, onRemove: () => setState(() => _wins.remove(w))))
                .toList().animate(interval: 30.ms).fadeIn(),
            const Gap(8),
            _AddItemRow(
              controller: _winCtrl,
              hint: 'Ej: Ahorré más de lo planeado',
              onAdd: () {
                if (_winCtrl.text.isNotEmpty) {
                  setState(() { _wins.add(_winCtrl.text); _winCtrl.clear(); });
                }
              },
              color: AppColors.primary,
            ).animate().fadeIn(delay: 280.ms),

            const Gap(20),

            // ── Áreas de mejora ──────────────────────────
            Text('🎯 ¿Qué mejorarás el próximo mes?', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 300.ms),
            const Gap(8),
            ..._improvements.map((i) => _TagChip(text: i, onRemove: () => setState(() => _improvements.remove(i)), color: AppColors.warning))
                .toList().animate(interval: 30.ms).fadeIn(),
            const Gap(8),
            _AddItemRow(
              controller: _improveCtrl,
              hint: 'Ej: Reducir gastos en delivery',
              onAdd: () {
                if (_improveCtrl.text.isNotEmpty) {
                  setState(() { _improvements.add(_improveCtrl.text); _improveCtrl.clear(); });
                }
              },
              color: AppColors.warning,
            ).animate().fadeIn(delay: 330.ms),

            const Gap(20),

            // ── Nota libre ────────────────────────────────
            Text('📝 Nota para tu yo futuro', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 360.ms),
            const Gap(8),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escríbete algo que recuerdes el próximo mes...',
              ),
            ).animate().fadeIn(delay: 380.ms),

            const Gap(24),

            // ── Guardar ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  await ref.read(monthlyReviewProvider.notifier).completeReview(
                    userId: user?.uid ?? '',
                    monthKey: monthKey,
                    wins: _wins,
                    improvements: _improvements,
                    userNote: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                  );
                  if (mounted) {
                    setState(() => _saving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Revisión completada — ¡gran trabajo!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Completar Revisión del Mes'),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final MonthlyReviewEntity review;
  final String currency;
  const _HealthScoreCard({required this.review, required this.currency});

  Color get _color {
    if (review.healthScore >= 80) return AppColors.primary;
    if (review.healthScore >= 60) return AppColors.info;
    if (review.healthScore >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color.withOpacity(0.12), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Salud financiera del mes', style: theme.textTheme.bodySmall?.copyWith(color: _color)),
              Text(
                '${review.healthScore.toStringAsFixed(0)}/100',
                style: theme.textTheme.displaySmall?.copyWith(color: _color, fontWeight: FontWeight.w800),
              ),
              Text(review.healthLabel, style: theme.textTheme.titleMedium),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Check(label: 'Gastos fijos OK', ok: review.stayedInFixedBudget),
              _Check(label: 'Meta de ahorro', ok: review.hitSavingsGoal),
              _Check(label: 'Meta inversión', ok: review.hitInvestmentsGoal),
              _Check(label: 'Racha de hábito', ok: review.habitStreakAtClose > 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final String label;
  final bool ok;
  const _Check({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: ok ? AppColors.primary : AppColors.error),
          const Gap(4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _AutoInsightsCard extends StatelessWidget {
  final MonthlyReviewEntity current;
  final MonthlyReviewEntity? previous;
  const _AutoInsightsCard({required this.current, this.previous});

  List<({String emoji, String text, bool positive})> get _insights {
    final list = <({String emoji, String text, bool positive})>[];
    final prev = previous;

    if (prev != null) {
      // Fixed costs delta
      final fixedDelta = current.fixedCostsActual - prev.fixedCostsActual;
      if (fixedDelta.abs() > 0.01) {
        final pct = prev.fixedCostsActual > 0
            ? (fixedDelta.abs() / prev.fixedCostsActual * 100).toStringAsFixed(0)
            : '0';
        list.add(fixedDelta < 0
            ? (emoji: '✅', text: 'Gastos fijos bajaron $pct% vs. el mes anterior.', positive: true)
            : (emoji: '⚠️', text: 'Gastos fijos subieron $pct% vs. el mes anterior.', positive: false));
      }

      // Savings delta
      final savDelta = current.savingsActual - prev.savingsActual;
      if (savDelta.abs() > 0.01) {
        final pct = prev.savingsActual > 0
            ? (savDelta.abs() / prev.savingsActual * 100).toStringAsFixed(0)
            : '0';
        list.add(savDelta > 0
            ? (emoji: '🏦', text: 'Ahorraste $pct% más que el mes pasado. Vas bien.', positive: true)
            : (emoji: '🔻', text: 'Ahorraste $pct% menos que el mes pasado.', positive: false));
      }

      // Health score delta
      final scoreDelta = current.healthScore - prev.healthScore;
      if (scoreDelta.abs() >= 10) {
        list.add(scoreDelta > 0
            ? (emoji: '📈', text: 'Tu salud financiera mejoró ${scoreDelta.toStringAsFixed(0)} puntos este mes.', positive: true)
            : (emoji: '📉', text: 'Tu salud financiera bajó ${scoreDelta.abs().toStringAsFixed(0)} puntos. Revisa qué salió diferente.', positive: false));
      }
    }

    // Current month standalone insights
    if (current.hitSavingsGoal) {
      list.add((emoji: '🎯', text: 'Alcanzaste tu meta de ahorro este mes.', positive: true));
    }
    if (current.hitInvestmentsGoal) {
      list.add((emoji: '📈', text: 'Completaste tu meta de inversión.', positive: true));
    }
    if (!current.stayedInFixedBudget) {
      list.add((emoji: '🚨', text: 'Tus gastos fijos excedieron el presupuesto.', positive: false));
    }

    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _insights;
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Insights del mes',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const Gap(10),
          ...insights.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.emoji, style: const TextStyle(fontSize: 14)),
                    const Gap(8),
                    Expanded(
                      child: Text(i.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: i.positive ? null : AppColors.error,
                            height: 1.3,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _BucketResultRow extends StatelessWidget {
  final String label, currency;
  final double actual, budget;
  final double? prevActual;
  final bool lowerIsBetter;

  const _BucketResultRow({
    required this.label,
    required this.actual,
    required this.budget,
    this.prevActual,
    required this.currency,
    required this.lowerIsBetter,
  });

  bool get _isGood => lowerIsBetter ? actual <= budget : actual >= budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prev = prevActual;
    final hasDelta = prev != null && prev > 0;
    final delta = hasDelta ? actual - prev! : 0.0;
    final deltaIsGood = lowerIsBetter ? delta <= 0 : delta >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          if (hasDelta) ...[
            Icon(
              delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13,
              color: deltaIsGood ? AppColors.primary : AppColors.error,
            ),
            Text(
              '${delta.abs() > 0 ? CurrencyFormatter.formatCompact(delta.abs(), currency) : '='}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: deltaIsGood ? AppColors.primary : AppColors.error,
              ),
            ),
            const Gap(6),
          ],
          Text(
            CurrencyFormatter.formatCompact(actual, currency),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _isGood ? AppColors.primary : AppColors.error,
            ),
          ),
          const Gap(4),
          Icon(
            _isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: _isGood ? AppColors.primary : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final VoidCallback onRemove;
  final Color color;
  const _TagChip({required this.text, required this.onRemove, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Chip(
        label: Text(text, style: TextStyle(color: color, fontSize: 13)),
        deleteIcon: Icon(Icons.close_rounded, size: 16, color: color),
        onDeleted: onRemove,
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}

class _AddItemRow extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onAdd;
  final Color color;

  const _AddItemRow({required this.controller, required this.hint, required this.onAdd, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint, isDense: true),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const Gap(8),
        IconButton(
          icon: Icon(Icons.add_circle_rounded, color: color),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
