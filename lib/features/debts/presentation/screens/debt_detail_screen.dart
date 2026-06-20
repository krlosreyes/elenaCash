import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/debts_provider.dart';
import '../../domain/entities/debt_entity.dart';

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final debtsAsync = ref.watch(debtsWatchProvider);
    final debt = debtsAsync.asData?.value.where((d) => d.id == debtId).firstOrNull;

    if (debt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deuda')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final paymentScenarios = [
      debt.minimumPayment,
      debt.minimumPayment * 1.5,
      debt.minimumPayment * 2,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.error,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Eliminar deuda?'),
                  content: const Text('Esta acción no se puede deshacer.'),
                  actions: [
                    TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () => ctx.pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(debtsProvider.notifier).deleteDebt(
                  userId: user?.uid ?? '',
                  debtId: debt.id,
                );
                context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // ── Header ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(debt.type.emoji, style: const TextStyle(fontSize: 48)),
                const Gap(8),
                Text(debt.name, style: theme.textTheme.headlineSmall),
                Text(debt.type.label, style: theme.textTheme.bodySmall),
                const Gap(16),
                Text(
                  CurrencyFormatter.format(debt.currentBalance, currency),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w800,
                  ),
                ),
                Text('saldo actual', style: theme.textTheme.bodySmall),
              ],
            ),
          ),

          const Gap(20),

          // ── Stats ─────────────────────────────────────
          _StatsRow(items: [
            _StatItem('Tasa E.A.', '${debt.interestRate.toStringAsFixed(1)}%', AppColors.error),
            _StatItem('Interés/mes', CurrencyFormatter.formatCompact(debt.monthlyInterestAmount, currency), AppColors.error),
            _StatItem('Pagado', '${debt.progressPct.toStringAsFixed(0)}%', AppColors.primary),
          ]),

          const Gap(20),

          // ── Escenarios de pago ────────────────────────
          Text('Proyección de pago', style: theme.textTheme.titleLarge),
          const Gap(12),
          ...paymentScenarios.asMap().entries.map((e) {
            final pay = e.value;
            final months = debt.monthsToPayoff(pay);
            final totalInterest = debt.totalInterestWith(pay);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                border: Border.all(
                  color: e.key == 0 ? theme.dividerColor : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key == 0 ? 'Pago mínimo' : e.key == 1 ? '+50% extra' : '+100% extra',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: e.key > 0 ? AppColors.primary : null,
                          ),
                        ),
                        Text(CurrencyFormatter.format(pay, currency), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$months meses', style: theme.textTheme.titleMedium),
                      Text(
                        'Intereses: ${CurrencyFormatter.formatCompact(totalInterest, currency)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const Gap(24),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(item.value,
                  style: TextStyle(fontWeight: FontWeight.w700, color: item.color, fontSize: 16)),
              Text(item.label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}
