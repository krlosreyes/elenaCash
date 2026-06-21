import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/fastlane_entity.dart';
import '../providers/fastlane_provider.dart';

class MoneyTreeScreen extends ConsumerStatefulWidget {
  const MoneyTreeScreen({super.key});

  @override
  ConsumerState<MoneyTreeScreen> createState() => _MoneyTreeScreenState();
}

class _MoneyTreeScreenState extends ConsumerState<MoneyTreeScreen> {
  bool _adding = false;
  BranchType _selectedType = BranchType.investment;
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final fastlaneAsync = ref.watch(fastLaneEngineProvider);
    final entity = fastlaneAsync.asData?.value;
    final branches = entity?.moneyTreeBranches.where((b) => b.isActive).toList() ?? [];
    final totalPassive = branches.fold<double>(0, (sum, b) => sum + b.monthlyAmount);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresos Pasivos'),
            Text(
              'Dinero que llega mientras duermes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_adding ? Icons.close_rounded : Icons.add_rounded),
            tooltip: _adding ? 'Cancelar' : 'Agregar fuente',
            onPressed: () => setState(() => _adding = !_adding),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // ── Banner conceptual ─────────────────────────
          _ConceptBannerCard().animate().fadeIn(),
          const Gap(16),

          // ── Visualización del Árbol ───────────────────
          _TreeVisualization(
            totalPassive: totalPassive,
            branches: branches,
            currency: currency,
          ).animate().fadeIn(),

          const Gap(24),

          // ── Formulario Agregar Rama ───────────────────
          if (_adding) ...[
            _AddBranchForm(
              selectedType: _selectedType,
              labelCtrl: _labelCtrl,
              amountCtrl: _amountCtrl,
              onTypeChanged: (t) => setState(() => _selectedType = t),
              onSave: () async {
                final amount = double.tryParse(
                    _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                if (_labelCtrl.text.isEmpty || amount <= 0) return;
                await ref.read(fastLaneProvider.notifier).addMoneyTreeBranch(
                  userId: user?.uid ?? '',
                  type: _selectedType,
                  label: _labelCtrl.text,
                  monthlyAmount: amount,
                );
                _labelCtrl.clear();
                _amountCtrl.clear();
                setState(() => _adding = false);

                // Recalcular score
                await ref.read(fastLaneProvider.notifier).updateScoreFromIncomes(
                  userId: user?.uid ?? '',
                  activeIncome: entity?.activeIncomeMonthly ?? 0,
                  passiveIncome: totalPassive + amount,
                );
              },
              currency: currency,
            ).animate().fadeIn(),
            const Gap(20),
          ],

          // ── Lista de ramas ─────────────────────────────
          if (branches.isEmpty)
            _EmptyTreeState()
          else ...[
            Text('Tus fuentes de ingreso pasivo',
                style: theme.textTheme.titleLarge).animate().fadeIn(delay: 100.ms),
            const Gap(12),
            ...branches.asMap().entries.map((entry) =>
              _BranchCard(
                branch: entry.value,
                currency: currency,
                userId: user?.uid ?? '',
              ).animate().fadeIn(delay: Duration(milliseconds: 150 + entry.key * 60)),
            ),
          ],

          const Gap(24),

          // ── Libertad Financiera ────────────────────────
          if (branches.isNotEmpty)
            _FreedomMetricCard(
              totalPassive: totalPassive,
              entity: entity,
              currency: currency,
            ).animate().fadeIn(delay: 260.ms),
          const Gap(16),

          // ── Concepto DeMarco ───────────────────────────
          _DeMarcoCard().animate().fadeIn(delay: 300.ms),
          const Gap(24),
        ],
      ),
    );
  }
}

// ── Concept Banner ────────────────────────────────────────────────

class _ConceptBannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌳', style: TextStyle(fontSize: 28)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué es el Árbol del Dinero?',
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary),
                ),
                const Gap(4),
                Text(
                  'Son tus fuentes de ingreso pasivo — dinero que entra sin que '
                  'intercambies tu tiempo por él: inversiones, arriendos, regalías, '
                  'negocios digitales. Cada rama que agregues crece con el tiempo.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tree Visualization ────────────────────────────────────────────

class _TreeVisualization extends StatelessWidget {
  final double totalPassive;
  final List<MoneyTreeBranch> branches;
  final String currency;
  const _TreeVisualization({required this.totalPassive, required this.branches, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1A0A), Color(0xFF001A00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Árbol visual
          Text(
            branches.isEmpty ? '🌱' : branches.length <= 2 ? '🌿' : branches.length <= 4 ? '🌳' : '🌲',
            style: const TextStyle(fontSize: 72),
          ),
          const Gap(8),
          Text(
            CurrencyFormatter.format(totalPassive, currency),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'ingreso pasivo mensual',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
          ),
          if (branches.isNotEmpty) ...[
            const Gap(16),
            Wrap(
              spacing: 8,
              children: branches.map((b) => Chip(
                avatar: Text(b.typeEmoji),
                label: Text(b.label, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddBranchForm extends StatelessWidget {
  final BranchType selectedType;
  final TextEditingController labelCtrl, amountCtrl;
  final ValueChanged<BranchType> onTypeChanged;
  final VoidCallback onSave;
  final String currency;

  const _AddBranchForm({
    required this.selectedType,
    required this.labelCtrl,
    required this.amountCtrl,
    required this.onTypeChanged,
    required this.onSave,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agregar una rama', style: theme.textTheme.titleMedium),
          const Gap(16),
          // Tipo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BranchType.values.map((t) => ChoiceChip(
              avatar: Text(t.typeEmoji),
              label: Text(t.typeName, style: const TextStyle(fontSize: 12)),
              selected: selectedType == t,
              onSelected: (_) => onTypeChanged(t),
            )).toList(),
          ),
          const Gap(12),
          TextField(
            controller: labelCtrl,
            decoration: const InputDecoration(hintText: 'Describe la fuente (Ej: CDT Bancolombia)'),
          ),
          const Gap(12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingreso mensual estimado',
              prefixText: currency == 'COP' ? '\$ ' : 'USD ',
            ),
          ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Agregar rama'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends ConsumerWidget {
  final MoneyTreeBranch branch;
  final String currency, userId;
  const _BranchCard({required this.branch, required this.currency, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Text(branch.typeEmoji, style: const TextStyle(fontSize: 28)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.label, style: theme.textTheme.titleSmall),
                Text(branch.typeName, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatCompact(branch.monthlyAmount, currency),
            style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
          const Gap(8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.error,
            onPressed: () => ref.read(fastLaneProvider.notifier)
                .removeBranch(userId: userId, branch: branch),
          ),
        ],
      ),
    );
  }
}

class _EmptyTreeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const Gap(16),
          Text(
            'Tu árbol está esperando',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            'Agrega tu primera fuente de ingreso pasivo tocando el + arriba.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(20),
          // Ejemplos de ramas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _ExampleChip(emoji: '🏦', label: 'CDT'),
              _ExampleChip(emoji: '🏠', label: 'Arriendo'),
              _ExampleChip(emoji: '📊', label: 'Dividendos'),
              _ExampleChip(emoji: '💻', label: 'App / SaaS'),
              _ExampleChip(emoji: '📝', label: 'Regalías'),
              _ExampleChip(emoji: '🤝', label: 'Franquicia'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _ExampleChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const Gap(6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Freedom Metric Card ───────────────────────────────────────────

class _FreedomMetricCard extends StatelessWidget {
  final double totalPassive;
  final FastLaneEntity? entity;
  final String currency;

  const _FreedomMetricCard({
    required this.totalPassive,
    required this.entity,
    required this.currency,
  });

  String _fmt(double v) {
    if (currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = entity?.activeIncomeMonthly ?? 0;
    // Use stored totalMonthlyExpenses if available, else estimate from active income
    final monthlyNeeds = expenses > 0 ? expenses * 0.55 : 0.0; // ~55% fixed costs estimate

    // Freedom ratio: how much of monthly needs is covered by passive income
    final coveragePct = monthlyNeeds > 0
        ? (totalPassive / monthlyNeeds).clamp(0.0, 1.0)
        : 0.0;

    // Years to freedom at current growth (simplified: if passive < needs)
    final remaining = (monthlyNeeds - totalPassive).clamp(0.0, double.infinity);

    String freedomText;
    if (totalPassive >= monthlyNeeds && monthlyNeeds > 0) {
      freedomText = '¡Tu árbol ya cubre tus gastos fijos! 🎉';
    } else if (monthlyNeeds <= 0) {
      freedomText = 'Agrega tus gastos en el onboarding para ver tu camino.';
    } else {
      freedomText = 'Faltan ${_fmt(remaining)}/mes para cubrir tus gastos fijos con ingreso pasivo.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏁', style: TextStyle(fontSize: 20)),
              const Gap(8),
              Text('Libertad Financiera',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const Gap(12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: coveragePct,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Text(
                '${(coveragePct * 100).toStringAsFixed(0)}% del camino',
                style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const Spacer(),
              Text(
                '${_fmt(totalPassive)} / ${_fmt(monthlyNeeds)}/mes',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ),
            ],
          ),
          const Gap(8),
          Text(freedomText,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _DeMarcoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🚀', style: TextStyle(fontSize: 20)),
            const Gap(8),
            Text('DeMarco dice:', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.gold)),
          ]),
          const Gap(8),
          Text(
            '"La riqueza real no se mide en dinero — se mide en tiempo libre. '
            'El Árbol del Dinero es lo que separa a quienes trabajan para vivir '
            'de quienes viven mientras trabajan."',
            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

