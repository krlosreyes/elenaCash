import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ElenaCash Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // ── Hero ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1500), Color(0xFF2A2200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 56)),
                  const Gap(12),
                  Text(
                    'ElenaCash Premium',
                    style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.gold),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'La Vía Rápida hacia tu libertad financiera',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const Gap(28),

            if (isPremium) ...[
              _ActiveBadge().animate().fadeIn(delay: 100.ms),
            ] else ...[
              // ── Planes ─────────────────────────────────
              Text('Elige tu plan', style: theme.textTheme.titleLarge)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(16),

              _PlanCard(
                name: 'Premium',
                priceUSD: '\$4.99/mes',
                priceCOP: '\$17,100 COP/mes',
                highlight: true,
                features: [
                  'FastLane Score y Árbol del Dinero',
                  'Todas las lecciones (incluyendo PRO)',
                  'Análisis de deudas avanzado',
                  'Revisión mensual completa',
                  'Exportar datos a CSV',
                  'Soporte prioritario',
                ],
                onSubscribe: () => _subscribe(context, 'premium'),
              ).animate().fadeIn(delay: 150.ms),

              const Gap(12),

              _PlanCard(
                name: 'Familiar',
                priceUSD: '\$7.99/mes',
                priceCOP: '\$27,390 COP/mes',
                highlight: false,
                features: [
                  'Todo de Premium',
                  'Hasta 5 cuentas familiares',
                  'Dashboard familiar compartido',
                  'Metas familiares compartidas',
                ],
                onSubscribe: () => _subscribe(context, 'family'),
              ).animate().fadeIn(delay: 200.ms),

              const Gap(20),

              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Continuar con la versión gratis'),
              ).animate().fadeIn(delay: 250.ms),
            ],

            const Gap(24),

            // ── Comparación features ──────────────────
            _FeatureComparisonTable().animate().fadeIn(delay: 300.ms),

            const Gap(24),

            Text(
              'Cancela en cualquier momento. Sin contratos. '
              'La cancelación es efectiva al final del período de facturación.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  void _subscribe(BuildContext context, String plan) {
    // TODO: RevenueCat purchase flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando compra de plan $plan...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 32)),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium activo', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
                Text('Gracias por apoyar ElenaCash.',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name, priceUSD, priceCOP;
  final bool highlight;
  final List<String> features;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.name,
    required this.priceUSD,
    required this.priceCOP,
    required this.highlight,
    required this.features,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = highlight ? AppColors.gold : theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? AppColors.gold.withOpacity(0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: borderColor, width: highlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Más popular', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700)),
            ),
          if (highlight) const Gap(8),
          Text(name, style: theme.textTheme.headlineSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(priceUSD, style: theme.textTheme.titleLarge?.copyWith(
                color: highlight ? AppColors.gold : AppColors.primary,
              )),
              const Gap(8),
              Text(priceCOP, style: theme.textTheme.bodySmall),
            ],
          ),
          const Gap(16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: highlight ? AppColors.gold : AppColors.primary, size: 16),
                const Gap(8),
                Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
              ],
            ),
          )),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: highlight
                  ? ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black)
                  : null,
              child: Text('Suscribirme a $name'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureComparisonTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      ('Plan Consciente de 4 cubos', true, true),
      ('Dashboard y seguimiento', true, true),
      ('Deudas y metas (3 máx.)', true, true),
      ('5 lecciones base', true, true),
      ('FastLane Score y Árbol', false, true),
      ('Lecciones PRO ilimitadas', false, true),
      ('Deudas y metas ilimitadas', false, true),
      ('Revisión mensual completa', false, true),
      ('Exportar datos CSV', false, true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                Text('Free', style: theme.textTheme.titleSmall),
                const SizedBox(width: 48),
                Text('Pro', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.gold)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(r.$1, style: theme.textTheme.bodySmall)),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Icon(
                      r.$2 ? Icons.check_rounded : Icons.remove_rounded,
                      size: 16,
                      color: r.$2 ? AppColors.primary : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Center(
                    child: Icon(
                      r.$3 ? Icons.check_rounded : Icons.remove_rounded,
                      size: 16,
                      color: r.$3 ? AppColors.gold : AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const Gap(8),
        ],
      ),
    );
  }
}
