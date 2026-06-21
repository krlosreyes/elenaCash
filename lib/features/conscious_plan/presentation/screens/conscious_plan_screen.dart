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
              _AutomationsCard(plan: plan, userId: user?.uid ?? '')
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

class _AutomationsCard extends ConsumerStatefulWidget {
  final ConsciousPlanEntity plan;
  final String userId;
  const _AutomationsCard({required this.plan, required this.userId});

  @override
  ConsumerState<_AutomationsCard> createState() => _AutomationsCardState();
}

class _AutomationsCardState extends ConsumerState<_AutomationsCard> {
  bool _savingsConfigured = false;
  bool _investConfigured = false;

  @override
  void initState() {
    super.initState();
    _savingsConfigured = widget.plan.automationsConfigured;
    _investConfigured = widget.plan.automationsConfigured;
  }

  String _fmt(double v) {
    final currency = 'COP';
    if (currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  void _onToggle() async {
    final allDone = _savingsConfigured && _investConfigured;
    if (allDone && !widget.plan.automationsConfigured) {
      await ref.read(consciousPlanProvider.notifier).markAutomationsConfigured(
        userId: widget.userId,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savBudget = widget.plan.savingsBudget;
    final invBudget = widget.plan.investmentsBudget;
    final allDone = _savingsConfigured && _investConfigured;

    if (allDone && widget.plan.automationsConfigured) {
      // Compact "sistema activo" badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sistema de automatización activo',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  Text('El dinero trabaja solo. Tú decides el resto.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
              const Gap(8),
              Text('Activa tu sistema automático',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700)),
            ],
          ),
          const Gap(4),
          Text(
            'Configura estas 2 transferencias y el sistema funciona solo.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondaryDark),
          ),
          const Gap(14),

          // Step 1 — Savings
          _AutoStep2(
            done: _savingsConfigured,
            emoji: '🏦',
            title: 'Ahorro automático',
            detail: savBudget > 0
                ? 'Transfiere ${_fmt(savBudget)} el día de tu pago a una cuenta separada.'
                : 'Transfiere tu presupuesto de ahorro a una cuenta separada.',
            onToggle: (v) {
              _savingsConfigured = v;
              _onToggle();
            },
          ),
          const Gap(10),

          // Step 2 — Investments
          _AutoStep2(
            done: _investConfigured,
            emoji: '📈',
            title: 'Inversión automática',
            detail: invBudget > 0
                ? 'Programa ${_fmt(invBudget)}/mes en tu fondo o CDT (Rappi Invest, Tyba, Bancolombia).'
                : 'Configura débito automático a tu fondo de inversión.',
            onToggle: (v) {
              _investConfigured = v;
              _onToggle();
            },
          ),

          if (allDone) ...[
            const Gap(14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Marcar sistema como activo'),
                onPressed: () async {
                  await ref.read(consciousPlanProvider.notifier)
                      .markAutomationsConfigured(userId: widget.userId);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoStep2 extends StatelessWidget {
  final bool done;
  final String emoji, title, detail;
  final ValueChanged<bool> onToggle;

  const _AutoStep2({
    required this.done,
    required this.emoji,
    required this.title,
    required this.detail,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppConstants.animFast,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withOpacity(0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? AppColors.primary.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600,
                            color: done ? AppColors.primary : null)),
                const Gap(2),
                Text(detail, style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark, height: 1.3)),
              ],
            ),
          ),
          const Gap(8),
          Switch.adaptive(
            value: done,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
