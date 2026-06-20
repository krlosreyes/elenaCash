import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/habit_engine_entity.dart';
import '../providers/habit_engine_provider.dart';

class CravingPauseScreen extends ConsumerStatefulWidget {
  const CravingPauseScreen({super.key});

  @override
  ConsumerState<CravingPauseScreen> createState() => _CravingPauseScreenState();
}

class _CravingPauseScreenState extends ConsumerState<CravingPauseScreen> {
  final _itemCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _currency = 'COP';
  bool _saving = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pauseCraving() async {
    if (_itemCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    await ref.read(habitEngineProvider.notifier).pauseCraving(
      item: _itemCtrl.text,
      amount: amount,
      currency: _currency,
    );
    if (mounted) {
      _itemCtrl.clear();
      _amountCtrl.clear();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏸️ Antojo pausado — te preguntamos en 24 horas'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitAsync = ref.watch(habitEngineWatchProvider);
    final pendingCravings = habitAsync.asData?.value?.pausedCravings
            .where((c) => c.isPending && !c.isExpired)
            .toList() ?? [];
    final expiredCravings = habitAsync.asData?.value?.pausedCravings
            .where((c) => c.isExpired)
            .toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Pausa 24h'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('⏸️', style: TextStyle(fontSize: 56)),
                  const Gap(12),
                  Text(
                    '¿Quieres comprar algo ahora mismo?',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    'Páusalo 24 horas. El 80% de los antojos impulsivos desaparece en ese tiempo. '
                    'Si mañana todavía lo quieres, cómpralo sin culpa.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const Gap(24),

            Text('Pausar un antojo', style: theme.textTheme.titleLarge)
                .animate().fadeIn(delay: 100.ms),
            const Gap(16),

            TextField(
              controller: _itemCtrl,
              decoration: const InputDecoration(
                hintText: '¿Qué quieres comprar? (Ej: Zapatos Nike, Suscripción Disney)',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ).animate().fadeIn(delay: 150.ms),
            const Gap(12),

            Row(
              children: [
                DropdownButton<String>(
                  value: _currency,
                  items: ['COP', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
                const Gap(12),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '¿Cuánto cuesta?'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),
            const Gap(20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _pauseCraving,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Pausar 24 horas ⏸️'),
              ),
            ).animate().fadeIn(delay: 250.ms),

            // ── Antojos pendientes ─────────────────────────
            if (expiredCravings.isNotEmpty) ...[
              const Gap(32),
              Text('⏰ Tiempo cumplido — ¿lo sigues queriendo?',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.gold))
                  .animate().fadeIn(delay: 300.ms),
              const Gap(12),
              ...expiredCravings.map((c) => _CravingDecisionCard(craving: c))
                  .toList().animate(interval: 50.ms).fadeIn(),
            ],

            if (pendingCravings.isNotEmpty) ...[
              const Gap(24),
              Text('En espera', style: theme.textTheme.titleMedium)
                  .animate().fadeIn(delay: 350.ms),
              const Gap(12),
              ...pendingCravings.map((c) => _PendingCravingCard(craving: c))
                  .toList().animate(interval: 50.ms).fadeIn(),
            ],

            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _CravingDecisionCard extends ConsumerWidget {
  final PausedCraving craving;
  const _CravingDecisionCard({required this.craving});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habitAsync = ref.watch(habitEngineWatchProvider);
    final allCravings = habitAsync.asData?.value?.pausedCravings ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(craving.item, style: theme.textTheme.titleMedium),
          Text(
            CurrencyFormatter.format(craving.amount, craving.currency),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.gold),
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(habitEngineProvider.notifier).decideCraving(
                    cravingId: craving.id,
                    decision: CravingDecision.skipped,
                    allCravings: allCravings,
                  ),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                  child: const Text('Pasé 💪'),
                ),
              ),
              const Gap(8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(habitEngineProvider.notifier).decideCraving(
                    cravingId: craving.id,
                    decision: CravingDecision.bought,
                    allCravings: allCravings,
                  ),
                  child: const Text('Lo compré'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCravingCard extends StatelessWidget {
  final PausedCraving craving;
  const _PendingCravingCard({required this.craving});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = craving.timeRemaining;
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const Text('⏸️', style: TextStyle(fontSize: 20)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(craving.item, style: theme.textTheme.bodyMedium),
                if (craving.amount > 0)
                  Text(
                    CurrencyFormatter.formatCompact(craving.amount, craving.currency),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Text(
            '${hours}h ${minutes}m',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}
