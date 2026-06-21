import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart'; // currentUserProvider
import '../../../subscription/providers/subscription_provider.dart';

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
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: AppColors.gold),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'La Vía Rápida hacia tu libertad financiera',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondaryDark),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const Gap(28),

            if (isPremium) ...[
              _ActiveBadge().animate().fadeIn(delay: 100.ms),
              const Gap(16),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
              ),
            ] else ...[
              // ── Planes ─────────────────────────────────
              Text('Elige tu plan', style: theme.textTheme.titleLarge)
                  .animate()
                  .fadeIn(delay: 100.ms),
              const Gap(16),

              // Planes con precios reales de RevenueCat (mobile) o fallback (web)
              if (kIsWeb)
                _WebSubscribeCard(theme: theme)
              else
                _MobilePackagesView(),

              const Gap(12),

              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Continuar con la versión gratis'),
              ).animate().fadeIn(delay: 250.ms),

              const Gap(8),

              // Restaurar compras
              TextButton.icon(
                onPressed: kIsWeb
                    ? null
                    : () => _restore(context, ref),
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Restaurar compras anteriores'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondaryDark,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ).animate().fadeIn(delay: 280.ms),
            ],

            const Gap(24),

            // ── Comparación features ──────────────────
            _FeatureComparisonTable().animate().fadeIn(delay: 300.ms),

            const Gap(24),

            Text(
              'Cancela en cualquier momento. Sin contratos. '
              'La cancelación es efectiva al final del período de facturación.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 350.ms),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final restored =
        await ref.read(subscriptionNotifierProvider.notifier).restore();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(restored
            ? '✅ Suscripción restaurada correctamente.'
            : 'No se encontraron compras anteriores para restaurar.'),
        backgroundColor: restored ? AppColors.primary : null,
      ),
    );
  }
}

// ── Paquetes reales (móvil) ───────────────────────────────────────

class _MobilePackagesView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringsAsync = ref.watch(purchaseOfferingsProvider);
    final subState = ref.watch(subscriptionNotifierProvider);
    final isLoading = subState is AsyncLoading;

    return offeringsAsync.when(
      data: (offerings) {
        if (offerings == null || offerings.current == null) {
          // No hay paquetes configurados en RevenueCat — mostrar fallback
          return _FallbackPlansView();
        }

        final packages = offerings.current!.availablePackages;
        if (packages.isEmpty) return _FallbackPlansView();

        return Column(
          children: packages.map((pkg) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PackageCard(
                package: pkg,
                isLoading: isLoading,
                onSubscribe: () => _purchase(context, ref, pkg),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => _FallbackPlansView(),
    );
  }

  Future<void> _purchase(
      BuildContext context, WidgetRef ref, Package package) async {
    final success =
        await ref.read(subscriptionNotifierProvider.notifier).purchase(package);
    if (!context.mounted) return;

    final subState = ref.read(subscriptionNotifierProvider);
    if (subState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al procesar la compra. Intenta de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Bienvenido a Premium!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      }
    }
  }
}

class _PackageCard extends StatelessWidget {
  final Package package;
  final bool isLoading;
  final VoidCallback onSubscribe;

  const _PackageCard({
    required this.package,
    required this.isLoading,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;
    final isMonthly = package.packageType == PackageType.monthly;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAnnual ? AppColors.gold.withOpacity(0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: isAnnual ? AppColors.gold : theme.dividerColor,
          width: isAnnual ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnnual) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mejor valor · 2 meses gratis',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const Gap(8),
          ],
          Text(
            isAnnual ? 'Premium Anual' : isMonthly ? 'Premium Mensual' : product.title,
            style: theme.textTheme.headlineSmall,
          ),
          const Gap(4),
          Text(
            product.priceString,
            style: theme.textTheme.titleLarge?.copyWith(
              color: isAnnual ? AppColors.gold : AppColors.primary,
            ),
          ),
          if (product.description.isNotEmpty) ...[
            const Gap(4),
            Text(product.description, style: theme.textTheme.bodySmall),
          ],
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubscribe,
              style: isAnnual
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black)
                  : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Suscribirme'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback cuando RevenueCat no tiene paquetes configurados ──────

class _FallbackPlansView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StaticPlanCard(
          name: 'Premium',
          priceUSD: '\$4.99/mes',
          priceCOP: '~\$17,100 COP',
          highlight: true,
          features: [
            'FastLane Score y Árbol del Dinero',
            'Todas las lecciones (incluyendo PRO)',
            'Análisis de deudas avanzado',
            'Revisión mensual completa',
            'Exportar datos a CSV',
            'Soporte prioritario',
          ],
        ),
        const Gap(12),
        _StaticPlanCard(
          name: 'Familiar',
          priceUSD: '\$7.99/mes',
          priceCOP: '~\$27,390 COP',
          highlight: false,
          features: [
            'Todo de Premium',
            'Hasta 5 cuentas familiares',
            'Dashboard familiar compartido',
            'Metas familiares compartidas',
          ],
        ),
        const Gap(12),
        const Text(
          'Disponible pronto en App Store y Google Play',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Web fallback ──────────────────────────────────────────────────

class _WebSubscribeCard extends StatelessWidget {
  final ThemeData theme;
  const _WebSubscribeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Text('📱', style: TextStyle(fontSize: 40)),
          const Gap(12),
          Text(
            'Suscríbete desde la app móvil',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            'Las suscripciones se gestionan desde iOS o Android. '
            'Si ya tienes Premium activo en tu dispositivo, '
            'se reflejará automáticamente aquí.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://elenacash.app');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Ver más info'),
          ),
        ],
      ),
    );
  }
}

// ── Active Badge ──────────────────────────────────────────────────

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
                Text(
                  'Premium activo',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.primary),
                ),
                Text(
                  'Gracias por apoyar ElenaCash.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Static Plan Card (fallback) ───────────────────────────────────

class _StaticPlanCard extends StatelessWidget {
  final String name, priceUSD, priceCOP;
  final bool highlight;
  final List<String> features;

  const _StaticPlanCard({
    required this.name,
    required this.priceUSD,
    required this.priceCOP,
    required this.highlight,
    required this.features,
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
          if (highlight) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Más popular',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700)),
            ),
            const Gap(8),
          ],
          Text(name, style: theme.textTheme.headlineSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                priceUSD,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: highlight ? AppColors.gold : AppColors.primary,
                ),
              ),
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
                        color: highlight ? AppColors.gold : AppColors.primary,
                        size: 16),
                    const Gap(8),
                    Expanded(
                        child: Text(f, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
          const Gap(16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: (highlight ? AppColors.gold : AppColors.primary)
                  .withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Próximamente en App Store y Play Store',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highlight ? AppColors.gold : AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Comparison Table ──────────────────────────────────────

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
                Text('Pro',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.gold)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows.map((r) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(r.$1, style: theme.textTheme.bodySmall)),
                    SizedBox(
                      width: 48,
                      child: Center(
                        child: Icon(
                          r.$2 ? Icons.check_rounded : Icons.remove_rounded,
                          size: 16,
                          color: r.$2
                              ? AppColors.primary
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Center(
                        child: Icon(
                          r.$3 ? Icons.check_rounded : Icons.remove_rounded,
                          size: 16,
                          color: r.$3
                              ? AppColors.gold
                              : AppColors.textSecondaryDark,
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
