import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/habit_engine_provider.dart';

/// Pantalla del Hábito Bisagra — inspirada en Duhigg.
/// Explica el concepto y ayuda al usuario a identificar su keystone habit financiero.
class HabitBisagraScreen extends ConsumerStatefulWidget {
  const HabitBisagraScreen({super.key});

  @override
  ConsumerState<HabitBisagraScreen> createState() => _HabitBisagraScreenState();
}

class _HabitBisagraScreenState extends ConsumerState<HabitBisagraScreen> {
  String? _selectedProblem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Hábito Bisagra'),
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
            // Hero visual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('🔑', style: TextStyle(fontSize: 56)),
                  const Gap(16),
                  Text(
                    'El Hábito que lo\nCambia Todo',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    'Lisa cambió un solo hábito — dejar de fumar — y su cerebro '
                    'reorganizó su dieta, su ejercicio, sus ahorros y su carrera. '
                    'Solo por cambiar uno.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            const Gap(28),

            Text(
              'Tu hábito bisagra financiero',
              style: theme.textTheme.headlineSmall,
            ),
            const Gap(8),
            Text(
              'Después de analizar miles de usuarios, encontramos que hay UN solo hábito '
              'que, si se instala correctamente, arrastra todos los demás:',
              style: theme.textTheme.bodyMedium,
            ),

            const Gap(24),

            // El Ritual Quincenal
            _HabitCard(
              title: 'El Ritual Quincenal',
              emoji: '⚡',
              duration: '5 minutos',
              frequency: 'Cada quincena / pago',
              description: 'El día que recibes tu pago, abres ElenaCash y haces '
                  'el check de 5 minutos. Confirmas que los cubos están bien, '
                  'que las automatizaciones corrieron, y cierras la app.',
              why: 'Es la señal que le dice a tu cerebro: "Soy alguien que controla su dinero." '
                  'Una identidad instalada, no una meta perseguida.',
              color: AppColors.primary,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const Gap(16),

            // El Bucle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'El Bucle del Hábito',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Gap(16),
                  _BucleStep(
                    number: '1',
                    label: 'SEÑAL',
                    description: '"Llegó mi pago" — notificación de ElenaCash',
                    color: AppColors.info,
                  ),
                  _Arrow(),
                  _BucleStep(
                    number: '2',
                    label: 'RUTINA',
                    description: 'Abrir app → 5 minutos → check completo',
                    color: AppColors.primary,
                  ),
                  _Arrow(),
                  _BucleStep(
                    number: '3',
                    label: 'RECOMPENSA',
                    description: '🎉 Celebración + racha + avance de tu Rich Life',
                    color: AppColors.gold,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const Gap(28),

            Text(
              '¿Cuál es tu mayor problema financiero?',
              style: theme.textTheme.headlineSmall,
            ),
            const Gap(8),
            Text(
              'Selecciona el que más te identifica. Lo usaremos para personalizar tu plan.',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),

            ..._problems.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProblemChip(
                  problem: p,
                  selected: _selectedProblem == p.text,
                  onTap: () => setState(() => _selectedProblem = p.text),
                ),
              ),
            ).toList().animate(interval: 50.ms).fadeIn().slideX(begin: 0.05),

            const Gap(32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedProblem == null
                    ? null
                    : () async {
                        await ref
                            .read(habitEngineProvider.notifier)
                            .saveFinancialProblem(_selectedProblem!);
                        if (context.mounted) context.pop();
                      },
                child: const Text('Activar mi Hábito Bisagra'),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const Gap(24),
          ],
        ),
      ),
    );
  }

  static const _problems = [
    _Problem(emoji: '😰', text: 'No sé en qué se va mi dinero'),
    _Problem(emoji: '🛍️', text: 'Gasto impulsivamente y me arrepiento'),
    _Problem(emoji: '😓', text: 'Nunca llego a fin de mes bien'),
    _Problem(emoji: '🎯', text: 'Ahorro pero no invierto'),
    _Problem(emoji: '💳', text: 'Tengo deudas que no avanzo a pagar'),
    _Problem(emoji: '🌱', text: 'Quiero empezar desde cero con mis finanzas'),
  ];
}

class _Problem {
  final String emoji;
  final String text;
  const _Problem({required this.emoji, required this.text});
}

class _ProblemChip extends StatelessWidget {
  final _Problem problem;
  final bool selected;
  final VoidCallback onTap;

  const _ProblemChip({
    required this.problem,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          border: Border.all(
            color: selected ? AppColors.primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(problem.emoji, style: const TextStyle(fontSize: 20)),
            const Gap(12),
            Text(problem.text, style: theme.textTheme.bodyMedium),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String duration;
  final String frequency;
  final String description;
  final String why;
  final Color color;

  const _HabitCard({
    required this.title,
    required this.emoji,
    required this.duration,
    required this.frequency,
    required this.description,
    required this.why,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    Row(
                      children: [
                        _Badge(text: duration, color: color),
                        const Gap(8),
                        _Badge(text: frequency, color: AppColors.info),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(description, style: theme.textTheme.bodyMedium),
          const Gap(8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: color, size: 16),
                const Gap(8),
                Expanded(
                  child: Text(
                    why,
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _BucleStep extends StatelessWidget {
  final String number;
  final String label;
  final String description;
  final Color color;

  const _BucleStep({
    required this.number,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(number, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
      child: Icon(Icons.arrow_downward_rounded, size: 16, color: AppColors.textSecondaryDark),
    );
  }
}
