import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/market_rates_entity.dart';
import '../providers/market_data_provider.dart';

/// Widget de TRM que muestra USD/COP y EUR/COP en tiempo real.
/// Fuente: Frankfurter API (BCE) — sin key, actualiza cada día hábil.
class TRMWidget extends ConsumerWidget {
  final String currency;
  const TRMWidget({super.key, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(marketRatesProvider);

    return ratesAsync.when(
      data: (rates) => rates == null
          ? const SizedBox.shrink()
          : _TRMCard(rates: rates, currency: currency)
              .animate()
              .fadeIn(duration: 400.ms),
      loading: () => _TRMCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TRMCard extends StatelessWidget {
  final MarketRatesEntity rates;
  final String currency;
  const _TRMCard({required this.rates, required this.currency});

  String _fmt(double v) {
    if (v >= 1000) {
      return '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changePct = rates.usdChangePct;
    final isUp = changePct >= 0;
    final changeColor = isUp ? const Color(0xFFD85A30) : AppColors.primary;
    final changeIcon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final changeStr =
        '${isUp ? '+' : ''}${changePct.toStringAsFixed(2)}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.currency_exchange_rounded,
                    size: 15, color: AppColors.primary),
              ),
              const Gap(8),
              Text('Mercados',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                'BCE · ${_timeLabel(rates.updatedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10, color: AppColors.textSecondaryDark),
              ),
            ],
          ),
          const Gap(12),

          // Rates row
          Row(
            children: [
              // USD/COP
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('USD / COP',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondaryDark, fontSize: 11)),
                    const Gap(2),
                    Text(
                      _fmt(rates.usdToCop),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
                    ),
                    const Gap(3),
                    Row(
                      children: [
                        Icon(changeIcon, size: 13, color: changeColor),
                        const Gap(3),
                        Text(changeStr,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: changeColor)),
                        Text(' vs ayer',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                  width: 0.5,
                  height: 44,
                  color: AppColors.primary.withOpacity(0.2)),
              const Gap(12),

              // EUR/COP
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EUR / COP',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondaryDark, fontSize: 11)),
                    const Gap(2),
                    Text(
                      _fmt(rates.eurToCop),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),

              // Impacto contextual
              if (currency == 'COP') ...[
                Container(
                    width: 0.5,
                    height: 44,
                    color: AppColors.primary.withOpacity(0.2)),
                const Gap(12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Netflix hoy',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryDark, fontSize: 11)),
                      const Gap(2),
                      Text(
                        '\$${(rates.copCost(17) / 1000).toStringAsFixed(0)}K',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text('(USD 17)',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Contexto si el dólar subió mucho
          if (changePct.abs() >= 1.0) ...[
            const Gap(10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isUp
                        ? const Color(0xFFD85A30)
                        : AppColors.primary)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isUp
                    ? 'El dólar subió ${changePct.toStringAsFixed(1)}% hoy. Tus deudas o suscripciones en USD cuestan más.'
                    : 'El dólar bajó ${changePct.abs().toStringAsFixed(1)}% hoy. Buen momento para pagar obligaciones en USD.',
                style: TextStyle(
                    fontSize: 11,
                    color: isUp
                        ? const Color(0xFF993C1D)
                        : AppColors.primary,
                    height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return 'hoy';
    return '${dt.day}/${dt.month}';
  }
}

class _TRMCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    ).animate().shimmer(duration: 1200.ms);
  }
}
