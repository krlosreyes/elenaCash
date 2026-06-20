import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/fastlane_entity.dart';
import '../providers/fastlane_provider.dart';

class FastlaneScoreScreen extends ConsumerStatefulWidget {
  const FastlaneScoreScreen({super.key});

  @override
  ConsumerState<FastlaneScoreScreen> createState() => _FastlaneScoreScreenState();
}

class _FastlaneScoreScreenState extends ConsumerState<FastlaneScoreScreen> {
  final _activeCtrl = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _activeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final currency = user?.currency ?? 'COP';
    final fastlaneAsync = ref.watch(fastLaneEngineProvider);
    final entity = fastlaneAsync.asData?.value;
    final score = (entity?.fastLaneScore ?? 0).toDouble();
    final roadmap = entity?.roadmap ?? FastLaneRoadmap.arcen;
    final passiveTotal = entity?.passiveIncomeMonthly ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('FastLane Score')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // ── Score Principal ───────────────────────────
            _ScoreHero(score: score, roadmap: roadmap, currency: currency, entity: entity)
                .animate().fadeIn(),

            const Gap(24),

            // ── Roadmap visual ─────────────────────────
            _RoadmapLevels(current: roadmap).animate().fadeIn(delay: 150.ms),

            const Gap(24),

            // ── Próximo Hito ──────────────────────────
            if (entity != null) ...[
              _NextMilestone(entity: entity, currency: currency)
                  .animate().fadeIn(delay: 200.ms),
              const Gap(24),
            ],

            // ── Actualizar ingreso activo ─────────────
            if (_editing || entity == null)
              _UpdateIncomeCard(
                activeCtrl: _activeCtrl,
                currency: currency,
                passiveIncome: passiveTotal,
                onSave: () async {
                  final active = double.tryParse(
                      _activeCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                  await ref.read(fastLaneProvider.notifier).updateScoreFromIncomes(
                    userId: user?.uid ?? '',
                    activeIncome: active,
                    passiveIncome: passiveTotal,
                  );
                  setState(() => _editing = false);
                },
              ).animate().fadeIn(delay: 250.ms)
            else
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Actualizar ingreso activo'),
                onPressed: () {
                  _activeCtrl.text = entity.activeIncomeMonthly.toStringAsFixed(0);
                  setState(() => _editing = true);
                },
              ).animate().fadeIn(delay: 250.ms),

            const Gap(24),

            // ── Concepto DeMarco ──────────────────────
            _DeMarcoExplainer().animate().fadeIn(delay: 300.ms),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  final double score;
  final FastLaneRoadmap roadmap;
  final String currency;
  final FastLaneEntity? entity;

  const _ScoreHero({required this.score, required this.roadmap, required this.currency, this.entity});

  Color get _color => switch (roadmap) {
    FastLaneRoadmap.arcen => AppColors.fastLaneSidewalk,
    FastLaneRoadmap.viaLenta => AppColors.fastLaneSlow,
    FastLaneRoadmap.viaRapida => AppColors.fastLaneFast,
    FastLaneRoadmap.elite => AppColors.gold,
  };

  String get _emoji => switch (roadmap) {
    FastLaneRoadmap.arcen => '🚶',
    FastLaneRoadmap.viaLenta => '🚗',
    FastLaneRoadmap.viaRapida => '🚀',
    FastLaneRoadmap.elite => '💎',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color.withOpacity(0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 64)),
          const Gap(8),
          Text(
            '${score.toStringAsFixed(0)}/100',
            style: theme.textTheme.displayMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(roadmap.label, style: theme.textTheme.titleLarge?.copyWith(color: _color)),
          const Gap(20),
          CircularPercentIndicator(
            radius: 70,
            lineWidth: 12,
            percent: score / 100,
            progressColor: _color,
            backgroundColor: _color.withOpacity(0.15),
            circularStrokeCap: CircularStrokeCap.round,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (entity != null) ...[
                  Text(
                    '${entity!.passiveRatioPct.toStringAsFixed(0)}%',
                    style: theme.textTheme.titleLarge?.copyWith(color: _color),
                  ),
                  Text('pasivo', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (entity != null) ...[
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _IncomeChip(label: 'Activo', amount: entity!.activeIncomeMonthly, color: AppColors.info, currency: currency),
                _IncomeChip(label: 'Pasivo', amount: entity!.passiveIncomeMonthly, color: _color, currency: currency),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IncomeChip extends StatelessWidget {
  final String label, currency;
  final double amount;
  final Color color;
  const _IncomeChip({required this.label, required this.amount, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
        Text(
          CurrencyFormatter.formatCompact(amount, currency),
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _RoadmapLevels extends StatelessWidget {
  final FastLaneRoadmap current;
  const _RoadmapLevels({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levels = [
      (FastLaneRoadmap.arcen, '🚶', 'Arcén', '0–24', AppColors.fastLaneSidewalk),
      (FastLaneRoadmap.viaLenta, '🚗', 'Vía Lenta', '25–59', AppColors.fastLaneSlow),
      (FastLaneRoadmap.viaRapida, '🚀', 'Vía Rápida', '60–84', AppColors.fastLaneFast),
      (FastLaneRoadmap.elite, '💎', 'Élite', '85–100', AppColors.gold),
    ];

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
          Text('Niveles de libertad financiera', style: theme.textTheme.titleMedium),
          const Gap(16),
          ...levels.map((l) {
            final isCurrent = l.$1 == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(l.$2, style: const TextStyle(fontSize: 22)),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.$3,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isCurrent ? l.$5 : null,
                              fontWeight: isCurrent ? FontWeight.w700 : null,
                            )),
                        Text('Score ${l.$4}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: l.$5.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Aquí', style: TextStyle(fontSize: 11, color: l.$5, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NextMilestone extends StatelessWidget {
  final FastLaneEntity entity;
  final String currency;
  const _NextMilestone({required this.entity, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 28)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Próximo hito', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.gold)),
                Text(entity.nextMilestone, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateIncomeCard extends StatelessWidget {
  final TextEditingController activeCtrl;
  final String currency;
  final double passiveIncome;
  final VoidCallback onSave;

  const _UpdateIncomeCard({
    required this.activeCtrl,
    required this.currency,
    required this.passiveIncome,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actualiza tu ingreso activo mensual', style: theme.textTheme.titleSmall),
          const Gap(4),
          Text('El ingreso pasivo se calcula automáticamente desde tu Árbol del Dinero.',
              style: theme.textTheme.bodySmall),
          const Gap(12),
          TextField(
            controller: activeCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingreso activo (salario, honorarios)',
              prefixText: currency == 'COP' ? '\$ ' : 'USD ',
            ),
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Calcular mi Score'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeMarcoExplainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo se calcula el FastLane Score?', style: theme.textTheme.titleSmall),
          const Gap(8),
          Text(
            '70% — Ratio de ingreso pasivo vs total\n'
            '+10 — Si tu ingreso pasivo supera \$500,000 COP/mes\n'
            '+10 — Si supera \$2,000,000 COP/mes\n'
            '+10 — Si supera \$5,000,000 COP/mes\n\n'
            'Basado en el concepto de Vía Rápida de MJ DeMarco: '
            'la libertad financiera real = ingreso que no depende de tu tiempo.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
