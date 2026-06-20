import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/goal_entity.dart';
import '../providers/goals_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _showForm = false;

  // form
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  GoalCategory _category = GoalCategory.emergency;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas de Ahorro'),
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) => ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // ── Form ──────────────────────────────────
            if (_showForm) ...[
              _AddGoalForm(
                nameCtrl: _nameCtrl,
                targetCtrl: _targetCtrl,
                currentCtrl: _currentCtrl,
                monthlyCtrl: _monthlyCtrl,
                category: _category,
                currency: currency,
                onCategoryChanged: (c) => setState(() => _category = c),
                onSave: () async {
                  final target = double.tryParse(_targetCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  final current = double.tryParse(_currentCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  final monthly = double.tryParse(_monthlyCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  if (_nameCtrl.text.isEmpty || target <= 0) return;

                  await ref.read(goalsProvider.notifier).addGoal(
                    userId: user?.uid ?? '',
                    name: _nameCtrl.text,
                    emoji: '🎯',
                    category: _category,
                    targetAmount: target,
                    monthlyContribution: monthly,
                  );
                  _nameCtrl.clear(); _targetCtrl.clear();
                  _currentCtrl.clear(); _monthlyCtrl.clear();
                  setState(() => _showForm = false);
                },
              ).animate().fadeIn(),
              const Gap(16),
            ],

            // ── Metas activas ──────────────────────────
            if (goals.isEmpty && !_showForm)
              _EmptyGoalsState()
            else
              ...goals.asMap().entries.map((e) => _GoalCard(
                goal: e.value,
                currency: currency,
                userId: user?.uid ?? '',
              ).animate().fadeIn(delay: Duration(milliseconds: 100 + e.key * 60))),

            const Gap(24),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AddGoalForm extends StatelessWidget {
  final TextEditingController nameCtrl, targetCtrl, currentCtrl, monthlyCtrl;
  final GoalCategory category;
  final String currency;
  final ValueChanged<GoalCategory> onCategoryChanged;
  final VoidCallback onSave;

  const _AddGoalForm({
    required this.nameCtrl,
    required this.targetCtrl,
    required this.currentCtrl,
    required this.monthlyCtrl,
    required this.category,
    required this.currency,
    required this.onCategoryChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.bucketSavings.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nueva meta', style: theme.textTheme.titleMedium),
          const Gap(16),
          // Categorías
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GoalCategory.values.map((c) => ChoiceChip(
              avatar: Text(c.emoji),
              label: Text(c.label, style: const TextStyle(fontSize: 12)),
              selected: category == c,
              onSelected: (_) => onCategoryChanged(c),
            )).toList(),
          ),
          const Gap(12),
          TextField(controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Nombre de la meta')),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Meta total',
                    prefixText: currency == 'COP' ? '\$ ' : 'USD ',
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ya tengo',
                    prefixText: currency == 'COP' ? '\$ ' : 'USD ',
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          TextField(
            controller: monthlyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Contribución mensual',
              prefixText: currency == 'COP' ? '\$ ' : 'USD ',
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onSave, child: const Text('Crear meta')),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerStatefulWidget {
  final GoalEntity goal;
  final String currency, userId;
  const _GoalCard({required this.goal, required this.currency, required this.userId});

  @override
  ConsumerState<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<_GoalCard> {
  bool _contributing = false;
  final _contribCtrl = TextEditingController();

  @override
  void dispose() {
    _contribCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = widget.goal;
    final progress = goal.progressPct.clamp(0.0, 1.0);
    final isComplete = goal.progressPct >= 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isComplete ? AppColors.primary.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(goal.category.emoji, style: const TextStyle(fontSize: 28)),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.name, style: theme.textTheme.titleMedium),
                          if (goal.estimatedCompletionDate != null)
                            Text(
                              goal.isOnTrack ? '✅ En camino' : '⚠️ Detrás del plan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: goal.isOnTrack ? AppColors.primary : AppColors.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(goal.progressPct * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.titleLarge?.copyWith(color: AppColors.bucketSavings),
                        ),
                        if (isComplete)
                          const Text('🎉', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                const Gap(12),
                LinearPercentIndicator(
                  lineHeight: 10,
                  percent: progress,
                  backgroundColor: AppColors.bucketSavings.withOpacity(0.15),
                  progressColor: isComplete ? AppColors.primary : AppColors.bucketSavings,
                  barRadius: const Radius.circular(5),
                  padding: EdgeInsets.zero,
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      CurrencyFormatter.format(goal.currentAmount, widget.currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.bucketSavings, fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'de ${CurrencyFormatter.format(goal.targetAmount, widget.currency)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (goal.monthsRemaining > 0) ...[
                  const Gap(4),
                  Text(
                    '${goal.monthsRemaining} meses restantes · '
                    '${CurrencyFormatter.formatCompact(goal.remaining, widget.currency)} por ahorrar',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          // ── Contribuir ─────────────────────────────
          if (!isComplete) ...[
            const Divider(height: 1),
            if (_contributing)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contribCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Monto a agregar',
                          isDense: true,
                          prefixText: widget.currency == 'COP' ? '\$ ' : 'USD ',
                        ),
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(
                            _contribCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                        if (amount <= 0) return;
                        await ref.read(goalsProvider.notifier).addContribution(
                          userId: widget.userId,
                          goalId: goal.id,
                          amount: amount,
                        );
                        _contribCtrl.clear();
                        setState(() => _contributing = false);
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                      child: const Text('✓'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _contributing = false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              )
            else
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Agregar contribución'),
                onPressed: () => setState(() => _contributing = true),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () => ref.read(goalsProvider.notifier)
                    .markCompleted(userId: widget.userId, goalId: goal.id),
                child: const Text('🎉 Marcar como completada'),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const Gap(16),
            Text('Crea tu primera meta', style: theme.textTheme.headlineSmall),
            const Gap(8),
            Text(
              'Un fondo de emergencia, un viaje, o tu primera inversión. '
              'Cada meta tiene un progreso visible y una fecha estimada.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
