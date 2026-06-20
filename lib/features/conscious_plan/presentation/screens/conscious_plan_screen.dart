import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/conscious_plan_provider.dart';
import '../../domain/entities/conscious_plan_entity.dart';

class ConsciousPlanScreen extends ConsumerWidget {
  const ConsciousPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final planAsync = ref.watch(consciousPlanWatchProvider);
    final currency = user?.currency ?? 'COP';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Consciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.onboarding),
          ),
        ],
      ),
      body: planAsync.when(
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📊', style: TextStyle(fontSize: 64)),
                  const Gap(16),
                  Text('Aún no tienes un plan', style: theme.textTheme.headlineSmall),
                  const Gap(8),
                  Text('Configúralo en 3 minutos', style: theme.textTheme.bodyMedium),
                  const Gap(24),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.onboarding),
                    child: const Text('Crear mi plan'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // ── Resumen de ingreso ─────────────────────────
              _SummaryCard(plan: plan, currency: currency)
                  .animate().fadeIn(),
              const Gap(20),

              Text('Distribución de tus cubos',
                  style: theme.textTheme.titleLarge).animate().fadeIn(delay: 100.ms),
              const Gap(12),

              // ── Cubo 1: Gastos Fijos ─────────────────────
              _BucketDetailCard(
                emoji: '🏠',
                label: 'Gastos Fijos',
                description: 'Renta, servicios, transporte, mercado, deudas mínimas',
                budget: plan.fixedCostsBudget,
                actual: plan.fixedCostsActual,
                pct: plan.fixedCostsPct,
                status: plan.fixedCostsStatus,
                color: AppColors.bucketFixed,
                currency: currency,
                userId: user?.uid ?? '',
                bucketId: 'fixedCosts',
              ).animate().fadeIn(delay: 150.ms),
              const Gap(12),

              _BucketDetailCard(
                emoji: '🏦',
                label: 'Ahorro',
                description: 'Fondo de emergencia, metas de corto y mediano plazo',
                budget: plan.savingsBudget,
                actual: plan.savingsActual,
                pct: plan.savingsPct,
                status: plan.savingsStatus,
                color: AppColors.bucketSavings,
                currency: currency,
                userId: user?.uid ?? '',
                bucketId: 'savings',
              ).animate().fadeIn(delay: 200.ms),
              const Gap(12),

              _BucketDetailCard(
                emoji: '📈',
                label: 'Inversiones',
                description: 'Fondos voluntarios de pensión, CDTs, acciones, crypto (largo plazo)',
                budget: plan.investmentsBudget,
                actual: plan.investmentsActual,
                pct: plan.investmentsPct,
                status: plan.investmentsStatus,
                color: AppColors.bucketInvestments,
                currency: currency,
                userId: user?.uid ?? '',
                bucketId: 'investments',
              ).animate().fadeIn(delay: 250.ms),
              const Gap(12),

              _BucketDetailCard(
                emoji: '🎉',
                label: 'Gasto Libre',
                description: 'Restaurantes, ropa, entretenimiento — sin culpa',
                budget: plan.guiltFreeBudget,
                actual: plan.guiltFreeActual,
                pct: plan.guiltFreePct,
                status: plan.guiltFreeStatus,
                color: AppColors.bucketFree,
                currency: currency,
                userId: user?.uid ?? '',
                bucketId: 'guiltFree',
              ).animate().fadeIn(delay: 300.ms),

              const Gap(24),

              // ── Automatizaciones ──────────────────────────
              if (!plan.automationsConfigured)
                _AutomationsCard(userId: user?.uid ?? '')
                    .animate().fadeIn(delay: 400.ms),

              const Gap(24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ConsciousPlanEntity plan;
  final String currency;
  const _SummaryCard({required this.plan, required this.currency});

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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ingreso mensual neto',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                Text(
                  CurrencyFormatter.format(plan.monthlyNetIncome, currency),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Disponible',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark)),
              Text(
                CurrencyFormatter.format(plan.remainingBudget, currency),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: plan.remainingBudget >= 0 ? AppColors.primary : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BucketDetailCard extends ConsumerStatefulWidget {
  final String emoji, label, description, userId, bucketId;
  final double budget, actual, pct;
  final BucketStatus status;
  final Color color;
  final String currency;

  const _BucketDetailCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.budget,
    required this.actual,
    required this.pct,
    required this.status,
    required this.color,
    required this.currency,
    required this.userId,
    required this.bucketId,
  });

  @override
  ConsumerState<_BucketDetailCard> createState() => _BucketDetailCardState();
}

class _BucketDetailCardState extends ConsumerState<_BucketDetailCard> {
  bool _expanded = false;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (actual / budget).clamp(0.0, 1.5);
    final isOver = actual > budget;

    return AnimatedContainer(
      duration: AppConstants.animFast,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isOver ? AppColors.error.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 22))),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.label, style: theme.textTheme.titleMedium),
                            Text(widget.description, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.pct.toStringAsFixed(0)}%',
                        style: theme.textTheme.titleMedium?.copyWith(color: widget.color),
                      ),
                    ],
                  ),
                  const Gap(12),
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: progress.clamp(0.0, 1.0),
                    backgroundColor: widget.color.withOpacity(0.12),
                    progressColor: isOver ? AppColors.error : widget.color,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(widget.actual, widget.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isOver ? AppColors.error : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'meta: ${CurrencyFormatter.format(widget.budget, widget.currency)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded: actualizar monto real ──────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Monto real gastado',
                        prefixText: widget.currency == 'COP' ? '\$ ' : 'USD ',
                        isDense: true,
                      ),
                    ),
                  ),
                  const Gap(12),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                          _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                      await ref.read(consciousPlanProvider.notifier)
                          .updateBucketActual(
                            userId: widget.userId,
                            bucket: widget.bucketId,
                            amount: amount,
                          );
                      if (mounted) setState(() => _expanded = false);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double get actual => widget.actual;
  double get budget => widget.budget;
}

class _AutomationsCard extends StatelessWidget {
  final String userId;
  const _AutomationsCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 20),
            const Gap(8),
            Text('Configura tus automatizaciones',
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.warning)),
          ]),
          const Gap(8),
          Text(
            'Para que el sistema funcione solo, programa transferencias automáticas '
            'el día de tu pago: ahorro → cuenta separada, inversiones → fondo.',
            style: theme.textTheme.bodySmall,
          ),
          const Gap(12),
          const _AutoStep(step: '1', text: 'Crea una cuenta de ahorros separada para tu fondo de emergencia'),
          const _AutoStep(step: '2', text: 'Programa transferencia automática el día 15 y el último día del mes'),
          const _AutoStep(step: '3', text: 'Configura débito automático para tu fondo de inversión (ej: Rappi Invest, Tyba)'),
        ],
      ),
    );
  }
}

class _AutoStep extends StatelessWidget {
  final String step, text;
  const _AutoStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
            child: Center(
              child: Text(step, style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
          const Gap(10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
