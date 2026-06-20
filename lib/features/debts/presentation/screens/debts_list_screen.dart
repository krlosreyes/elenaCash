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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/debt_entity.dart';
import '../providers/debts_provider.dart';

class DebtsListScreen extends ConsumerStatefulWidget {
  const DebtsListScreen({super.key});

  @override
  ConsumerState<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends ConsumerState<DebtsListScreen> {
  bool _showAddForm = false;
  DebtStrategy _strategy = DebtStrategy.avalanche;

  // Form fields
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _minPayCtrl = TextEditingController();
  DebtType _debtType = DebtType.creditCard;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _rateCtrl.dispose();
    _minPayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final debtsAsync = ref.watch(debtsWatchProvider);
    final totalBalance = ref.watch(totalDebtBalanceProvider);
    final totalInterest = ref.watch(totalMonthlyInterestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Deudas'),
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close_rounded : Icons.add_rounded),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
          ),
        ],
      ),
      body: debtsAsync.when(
        data: (debts) => ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // ── Resumen Total ──────────────────────────
            if (debts.isNotEmpty) ...[
              _DebtSummaryCard(
                totalBalance: totalBalance,
                totalInterest: totalInterest,
                currency: currency,
                debtCount: debts.length,
              ).animate().fadeIn(),
              const Gap(16),

              // ── Estrategia ─────────────────────────
              _StrategyToggle(
                selected: _strategy,
                onChanged: (s) => setState(() => _strategy = s),
              ).animate().fadeIn(delay: 100.ms),
              const Gap(16),
            ],

            // ── Form agregar deuda ─────────────────
            if (_showAddForm) ...[
              _AddDebtForm(
                nameCtrl: _nameCtrl,
                balanceCtrl: _balanceCtrl,
                rateCtrl: _rateCtrl,
                minPayCtrl: _minPayCtrl,
                debtType: _debtType,
                currency: currency,
                onTypeChanged: (t) => setState(() => _debtType = t),
                onSave: () async {
                  final balance = double.tryParse(_balanceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  final rate = double.tryParse(_rateCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  final minPay = double.tryParse(_minPayCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  if (_nameCtrl.text.isEmpty || balance <= 0 || rate <= 0) return;

                  await ref.read(debtsProvider.notifier).addDebt(
                    userId: user?.uid ?? '',
                    name: _nameCtrl.text,
                    type: _debtType,
                    totalAmount: balance,
                    currentBalance: balance,
                    interestRate: rate,
                    minimumPayment: minPay,
                    paymentDay: 1,
                  );

                  _nameCtrl.clear(); _balanceCtrl.clear();
                  _rateCtrl.clear(); _minPayCtrl.clear();
                  setState(() => _showAddForm = false);
                },
              ).animate().fadeIn(),
              const Gap(16),
            ],

            // ── Lista de deudas ────────────────────
            if (debts.isEmpty && !_showAddForm)
              _EmptyDebtsState()
            else ...[
              Text(
                _strategy == DebtStrategy.avalanche
                    ? '📊 Estrategia Avalancha: primero las de mayor interés'
                    : '❄️ Estrategia Bola de Nieve: primero las más pequeñas',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
              ).animate().fadeIn(delay: 150.ms),
              const Gap(12),
              ...debts.asMap().entries.map((e) => _DebtCard(
                debt: e.value,
                currency: currency,
                userId: user?.uid ?? '',
              ).animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 60))),
            ],

            const Gap(24),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final double totalBalance, totalInterest;
  final String currency;
  final int debtCount;

  const _DebtSummaryCard({
    required this.totalBalance,
    required this.totalInterest,
    required this.currency,
    required this.debtCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A0A), Color(0xFF2A0A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deuda total', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
                Text(
                  CurrencyFormatter.format(totalBalance, currency),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700,
                  ),
                ),
                Text('$debtCount deuda${debtCount != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Interés mensual', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
              Text(
                CurrencyFormatter.formatCompact(totalInterest, currency),
                style: theme.textTheme.titleLarge?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrategyToggle extends StatelessWidget {
  final DebtStrategy selected;
  final ValueChanged<DebtStrategy> onChanged;
  const _StrategyToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DebtStrategy>(
      segments: const [
        ButtonSegment(value: DebtStrategy.avalanche, label: Text('Avalancha 📊'), icon: Icon(Icons.trending_down_rounded)),
        ButtonSegment(value: DebtStrategy.snowball, label: Text('Bola de Nieve ❄️'), icon: Icon(Icons.ac_unit_rounded)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _AddDebtForm extends StatelessWidget {
  final TextEditingController nameCtrl, balanceCtrl, rateCtrl, minPayCtrl;
  final DebtType debtType;
  final String currency;
  final ValueChanged<DebtType> onTypeChanged;
  final VoidCallback onSave;

  const _AddDebtForm({
    required this.nameCtrl,
    required this.balanceCtrl,
    required this.rateCtrl,
    required this.minPayCtrl,
    required this.debtType,
    required this.currency,
    required this.onTypeChanged,
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
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar deuda', style: theme.textTheme.titleMedium),
          const Gap(16),
          DropdownButtonFormField<DebtType>(
            value: debtType,
            decoration: const InputDecoration(labelText: 'Tipo de deuda'),
            items: DebtType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.label),
            )).toList(),
            onChanged: (v) => onTypeChanged(v!),
          ),
          const Gap(12),
          TextField(controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Nombre (Ej: Tarjeta Bancolombia)')),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Saldo actual',
                    prefixText: currency == 'COP' ? '\$ ' : 'USD ',
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Tasa E.A. (%)', suffixText: '%'),
                ),
              ),
            ],
          ),
          const Gap(12),
          TextField(
            controller: minPayCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Pago mínimo mensual',
              prefixText: currency == 'COP' ? '\$ ' : 'USD ',
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onSave, child: const Text('Agregar deuda')),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtEntity debt;
  final String currency, userId;
  const _DebtCard({required this.debt, required this.currency, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(debt.type.emoji, style: const TextStyle(fontSize: 24)),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name, style: theme.textTheme.titleMedium),
                    Text(
                      '${debt.interestRate.toStringAsFixed(1)}% E.A. · ${CurrencyFormatter.format(debt.monthlyInterestAmount, currency)}/mes en intereses',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(debt.currentBalance, currency),
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.error),
                  ),
                  Text('${debt.progressPct.toStringAsFixed(0)}% pagado',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const Gap(12),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: (debt.progressPct / 100).clamp(0, 1),
            backgroundColor: AppColors.error.withOpacity(0.15),
            progressColor: AppColors.primary,
            barRadius: const Radius.circular(3),
            padding: EdgeInsets.zero,
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pagado: ${CurrencyFormatter.formatCompact(debt.paidAmount, currency)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${debt.monthsToPayoff(debt.minimumPayment)} meses al mínimo',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDebtsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const Gap(16),
            Text('¡Sin deudas registradas!', style: theme.textTheme.headlineSmall),
            const Gap(8),
            Text(
              'Si tienes deudas, agrégalas aquí para trackear tu progreso con la estrategia Avalancha.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
