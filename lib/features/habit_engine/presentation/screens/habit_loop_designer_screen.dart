import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/habit_engine_provider.dart';

class HabitLoopDesignerScreen extends ConsumerStatefulWidget {
  const HabitLoopDesignerScreen({super.key});

  @override
  ConsumerState<HabitLoopDesignerScreen> createState() => _HabitLoopDesignerScreenState();
}

class _HabitLoopDesignerScreenState extends ConsumerState<HabitLoopDesignerScreen> {
  final _nameCtrl = TextEditingController();
  final _cueCtrl = TextEditingController();
  final _badCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cueCtrl.dispose();
    _badCtrl.dispose();
    _newCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _cueCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }
    setState(() => _saving = true);
    await ref.read(habitEngineProvider.notifier).addHabitLoop(
      name: _nameCtrl.text,
      cue: _cueCtrl.text,
      badRoutine: _badCtrl.text,
      newRoutine: _newCtrl.text,
      reward: _rewardCtrl.text,
    );
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Bucle creado — el cambio comienza ahora')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diseña tu Bucle'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explicación rápida
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Text(
                '💡 El secreto de Duhigg: no puedes eliminar un hábito — solo reemplazarlo. '
                'La señal y la recompensa son las mismas. Solo cambia la rutina del medio.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ).animate().fadeIn(),

            const Gap(24),

            // Nombre del bucle
            _Field(
              label: 'Nombre del bucle *',
              hint: 'Ej: Estrés post-trabajo',
              controller: _nameCtrl,
              emoji: '🔖',
            ).animate().fadeIn(delay: 50.ms),

            const Gap(20),

            // CUE
            _Field(
              label: 'Señal (Cue) *',
              hint: 'Ej: Llego a casa después del trabajo y me siento estresado',
              controller: _cueCtrl,
              emoji: '🚨',
              color: AppColors.info,
              description: '¿Qué dispara el hábito? Puede ser un lugar, hora, emoción, persona, o acción previa.',
            ).animate().fadeIn(delay: 100.ms),

            const Gap(20),

            // Rutina mala (opcional)
            _Field(
              label: 'Rutina actual (la que quieres cambiar)',
              hint: 'Ej: Abro delivery y pido comida cara',
              controller: _badCtrl,
              emoji: '❌',
              color: AppColors.error,
            ).animate().fadeIn(delay: 150.ms),

            const Gap(20),

            // Rutina nueva
            _Field(
              label: 'Rutina nueva *',
              hint: 'Ej: Abro ElenaCash, reviso mi cubo de Gasto Libre, decido conscientemente',
              controller: _newCtrl,
              emoji: '✅',
              color: AppColors.primary,
              description: '¿Qué acción específica vas a hacer en cambio?',
            ).animate().fadeIn(delay: 200.ms),

            const Gap(20),

            // Recompensa
            _Field(
              label: 'Recompensa',
              hint: 'Ej: Siento control, no culpa. Me felicito mentalmente.',
              controller: _rewardCtrl,
              emoji: '🎁',
              color: AppColors.gold,
              description: 'La recompensa debe ser la misma que la rutina vieja ofrecía — alivio, placer, conexión.',
            ).animate().fadeIn(delay: 250.ms),

            const Gap(32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Crear mi Bucle'),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final String emoji;
  final Color? color;
  final String? description;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.emoji,
    this.color,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const Gap(8),
          Text(label,
              style: theme.textTheme.titleSmall?.copyWith(color: color ?? AppColors.textPrimaryDark)),
        ]),
        if (description != null) ...[
          const Gap(4),
          Text(description!, style: theme.textTheme.bodySmall),
        ],
        const Gap(8),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
