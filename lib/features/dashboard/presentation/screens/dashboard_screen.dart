import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../conscious_plan/domain/entities/conscious_plan_entity.dart';
import '../../../conscious_plan/presentation/providers/conscious_plan_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../fastlane_engine/domain/entities/fastlane_entity.dart';
import '../../../fastlane_engine/presentation/providers/fastlane_provider.dart';
import '../../../market_data/presentation/widgets/trm_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final planAsync = ref.watch(consciousPlanWatchProvider);
    final AsyncValue<FastLaneEntity?> fastlaneAsync = ref.watch(fastLaneEngineProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(consciousPlanWatchProvider);
            ref.invalidate(fastLaneEngineProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── App Bar ───────────────────────────────────────
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: theme.scaffoldBackgroundColor,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.park_rounded, color: Colors.black, size: 20),
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user?.displayName.split(' ').first ?? 'Tú'} 👋',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          DateHelpers.formatMonth(DateTime.now()),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),

              // ── Content ───────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                sliver: planAsync.when(
                  data: (plan) => plan == null
                      ? _EmptyPlanSliver(user: user)
                      : _DashboardContent(plan: plan, user: user, fastlaneAsync: fastlaneAsync),
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Content ─────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final ConsciousPlanEntity plan;
  final dynamic user;
  final AsyncValue<FastLaneEntity?> fastlaneAsync;

  const _DashboardContent({required this.plan, this.user, required this.fastlaneAsync});

  @override
  Widget build(BuildContext context) {
    final currency = user?.currency ?? 'COP';

    final buckets = [
      BucketInfo(
        id: 'fixedCosts',
        label: 'Gastos Fijos',
        emoji: '🏠',
        description: 'Renta, servicios, deudas',
        budget: plan.fixedCostsBudget,
        actual: plan.fixedCostsActual,
        percentage: plan.fixedCostsPct,
        status: plan.fixedCostsStatus,
      ),
      BucketInfo(
        id: 'savings',
        label: 'Ahorro',
        emoji: '🏦',
        description: 'Fondo emergencia, metas',
        budget: plan.savingsBudget,
        actual: plan.savingsActual,
        percentage: plan.savingsPct,
        status: plan.savingsStatus,
      ),
      BucketInfo(
        id: 'investments',
        label: 'Inversiones',
        emoji: '📈',
        description: 'Retiro, largo plazo',
        budget: plan.investmentsBudget,
        actual: plan.investmentsActual,
        percentage: plan.investmentsPct,
        status: plan.investmentsStatus,
      ),
      BucketInfo(
        id: 'guiltFree',
        label: 'Gasto Libre',
        emoji: '🎉',
        description: 'Lo que quieras, sin culpa',
        budget: plan.guiltFreeBudget,
        actual: plan.guiltFreeActual,
        percentage: plan.guiltFreePct,
        status: plan.guiltFreeStatus,
      ),
    ];

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Ingreso Card ─────────────────────────────────
        _IncomeCard(plan: plan, currency: currency)
            .animate()
            .fadeIn(duration: AppConstants.animMedium),
        const Gap(16),

        // ── TRM / Mercados ────────────────────────────────
        TRMWidget(currency: currency)
            .animate()
            .fadeIn(delay: 80.ms),
        const Gap(20),

        // ── Cubos ────────────────────────────────────────
        Text('Tu Plan Consciente', style: Theme.of(context).textTheme.titleLarge)
            .animate()
            .fadeIn(delay: 100.ms),
        const Gap(4),
        Text(
          '4 cubos. Automatizados. Sin culpa.',
          style: Theme.of(context).textTheme.bodySmall,
        ).animate().fadeIn(delay: 150.ms),
        const Gap(16),

        ...buckets.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _BucketCard(bucket: entry.value, currency: currency)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 200 + entry.key * 80))
                .slideX(begin: 0.05, end: 0),
          );
        }),

        const Gap(8),

        // ── Próximo movimiento ─────────────────────────
        _NextMovementCard(plan: plan, currency: currency)
            .animate()
            .fadeIn(delay: 480.ms),
        const Gap(16),

        // ── Revisión Mensual CTA ───────────────────────
        _MonthlyReviewCard()
            .animate()
            .fadeIn(delay: 540.ms),
        const Gap(16),

        // ── Nudge Árbol del Dinero ─────────────────────
        _FastlaneNudgeCard(fastlaneAsync: fastlaneAsync)
            .animate()
            .fadeIn(delay: 620.ms),
        const Gap(20),
      ]),
    );
  }
}

// ── Next Movement Card ────────────────────────────────────────────

class _NextMovementCard extends StatelessWidget {
  final ConsciousPlanEntity plan;
  final String currency;
  const _NextMovementCard({required this.plan, required this.currency});

  String _fmt(double v) {
    if (currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  List<({String emoji, String text, Color color})> get _actions {
    final list = <({String emoji, String text, Color color})>[];

    // Fixed costs over budget
    if (plan.fixedCostsActual > plan.fixedCostsBudget) {
      final over = plan.fixedCostsActual - plan.fixedCostsBudget;
      list.add((
        emoji: '🚨',
        text: 'Gastos fijos excedidos por ${_fmt(over)}. Revisa qué recortar para cerrar el mes en verde.',
        color: AppColors.error,
      ));
    }

    // Savings not hit yet
    if (plan.savingsActual < plan.savingsBudget && plan.savingsBudget > 0) {
      final missing = plan.savingsBudget - plan.savingsActual;
      list.add((
        emoji: '🏦',
        text: 'Faltan ${_fmt(missing)} para tu meta de ahorro este mes. Transfiérelos antes del cierre.',
        color: AppColors.bucketSavings,
      ));
    }

    // Investments not done
    if (plan.investmentsActual == 0 && plan.investmentsBudget > 0) {
      list.add((
        emoji: '📈',
        text: 'Aún no has invertido este mes. Mueve ${_fmt(plan.investmentsBudget)} a tu fondo.',
        color: AppColors.bucketInvestments,
      ));
    }

    // Everything on track + surplus
    if (list.isEmpty && plan.remainingBudget > 0) {
      list.add((
        emoji: '✅',
        text: 'Vas muy bien. Tienes ${_fmt(plan.remainingBudget)} disponibles — asígnalos o plántalos en el árbol.',
        color: AppColors.primary,
      ));
    }

    return list.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const Gap(8),
              Text('Tu próximo movimiento',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const Gap(12),
          ...actions.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 16)),
                    const Gap(8),
                    Expanded(
                      child: Text(a.text,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Income Card ───────────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  final ConsciousPlanEntity plan;
  final String currency;

  const _IncomeCard({required this.plan, required this.currency});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingreso mensual neto',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
          const Gap(4),
          Text(
            CurrencyFormatter.format(plan.monthlyNetIncome, currency),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              _AutomationBadge(configured: plan.automationsConfigured),
              const Spacer(),
              Text(
                'Disponible: ${CurrencyFormatter.formatCompact(plan.remainingBudget, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutomationBadge extends StatelessWidget {
  final bool configured;
  const _AutomationBadge({required this.configured});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: configured
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: configured ? AppColors.primary : AppColors.warning,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            configured ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 12,
            color: configured ? AppColors.primary : AppColors.warning,
          ),
          const Gap(4),
          Text(
            configured ? 'Sistema activo' : 'Configura automatizaciones',
            style: TextStyle(
              fontSize: 11,
              color: configured ? AppColors.primary : AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bucket Card ───────────────────────────────────────────────────

class _BucketCard extends StatelessWidget {
  final BucketInfo bucket;
  final String currency;

  const _BucketCard({required this.bucket, required this.currency});

  Color get _bucketColor => switch (bucket.id) {
        'fixedCosts' => AppColors.bucketFixed,
        'savings' => AppColors.bucketSavings,
        'investments' => AppColors.bucketInvestments,
        'guiltFree' => AppColors.bucketFree,
        _ => AppColors.primary,
      };

  Color get _bucketSurface => switch (bucket.id) {
        'fixedCosts' => AppColors.bucketFixedSurface,
        'savings' => AppColors.bucketSavingsSurface,
        'investments' => AppColors.bucketInvestmentsSurface,
        'guiltFree' => AppColors.bucketFreeSurface,
        _ => AppColors.primarySurface,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = bucket.progress.clamp(0.0, 1.0);
    final isOver = bucket.progress > 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isOver ? AppColors.error.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji e ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _bucketSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(bucket.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const Gap(12),

              // Nombre y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bucket.label, style: theme.textTheme.titleMedium),
                    Text(bucket.description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),

              // Porcentaje
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bucket.percentage.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(color: _bucketColor),
                  ),
                  if (isOver)
                    Text(
                      'Excedido',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                ],
              ),
            ],
          ),
          const Gap(12),

          // Barra de progreso
          LinearPercentIndicator(
            lineHeight: 8,
            percent: progress,
            backgroundColor: _bucketSurface,
            progressColor: isOver ? AppColors.error : _bucketColor,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
          const Gap(8),

          // Montos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatCompact(bucket.actual, currency),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOver ? AppColors.error : null,
                ),
              ),
              Text(
                'de ${CurrencyFormatter.formatCompact(bucket.budget, currency)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Monthly Review CTA ────────────────────────────────────────────

class _MonthlyReviewCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.monthlyReview),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1500), Color(0xFF2A2200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checklist_rounded, color: AppColors.gold, size: 26),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revisión Mensual',
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textPrimaryDark),
                  ),
                  Text(
                    '10 minutos. Una vez al mes. Cambia todo.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

// ── Fastlane Nudge Card ───────────────────────────────────────────

class _FastlaneNudgeCard extends StatelessWidget {
  final AsyncValue<FastLaneEntity?> fastlaneAsync;
  const _FastlaneNudgeCard({required this.fastlaneAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entity = fastlaneAsync.asData?.value;
    final branches = entity?.moneyTreeBranches
            .where((b) => b.isActive)
            .toList() ??
        [];

    if (branches.isNotEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push(AppRoutes.moneyTree),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🌱', style: TextStyle(fontSize: 24))),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planta tu primer ingreso pasivo',
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
                  ),
                  const Gap(2),
                  Text(
                    'Un CDT, arriendo, dividendo — cualquier dinero que entre sin tu tiempo.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Gap(8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Empty Plan State ──────────────────────────────────────────────

class _EmptyPlanSliver extends StatelessWidget {
  final dynamic user;
  const _EmptyPlanSliver({this.user});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 64)),
            const Gap(16),
            Text(
              'Configura tu Plan Consciente',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              '5 minutos. Una sola vez.\nLuego el sistema trabaja por ti.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.onboarding),
              child: const Text('Empezar ahora'),
            ),
          ],
        ),
      ),
    );
  }
}
