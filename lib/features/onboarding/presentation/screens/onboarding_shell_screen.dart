import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/firebase_providers.dart';

class OnboardingShellScreen extends ConsumerStatefulWidget {
  const OnboardingShellScreen({super.key});

  @override
  ConsumerState<OnboardingShellScreen> createState() => _OnboardingShellScreenState();
}

class _OnboardingShellScreenState extends ConsumerState<OnboardingShellScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  // Step 1 – Rich Life (selección múltiple estructurada)
  final List<String> _richLifeCategories = [];
  // Step 2 – Ingresos
  final _incomeCtrl = TextEditingController();
  String _currency = 'COP';
  // Step 3 – Percentages (usa defaults)
  double _fixedPct = AppConstants.defaultFixedCostsPct;
  double _savPct = AppConstants.defaultSavingsPct;
  double _invPct = AppConstants.defaultInvestmentsPct;
  double _freePct = AppConstants.defaultGuiltFreePct;

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 3) {
      _controller.nextPage(
        duration: AppConstants.animMedium,
        curve: Curves.easeInOut,
      );
      setState(() => _page++);
    }
  }

  Future<void> _finish() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final income = double.tryParse(
            _incomeCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ?? 0;

      // Usar batch para escribir todo atómicamente
      final batch = firestore.batch();

      // 1. Guardar el plan consciente
      final planRef = firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .collection(AppConstants.colConsciousPlan)
          .doc('current');

      batch.set(planRef, {
        'userId': uid,
        'monthlyNetIncome': income,
        'fixedCostsPct': _fixedPct,
        'savingsPct': _savPct,
        'investmentsPct': _invPct,
        'guiltFreePct': _freePct,
        'fixedCostsBudget': income * _fixedPct / 100,
        'savingsBudget': income * _savPct / 100,
        'investmentsBudget': income * _invPct / 100,
        'guiltFreeBudget': income * _freePct / 100,
        'automationsConfigured': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Perfil del usuario: onboarding + Rich Life categorías
      final userRef = firestore.collection(AppConstants.colUsers).doc(uid);
      batch.set(userRef, {
        'onboardingCompleted': true,
        'richLifeCategories': _richLifeCategories,
        // descripción legible generada desde las categorías seleccionadas
        'richLifeDescription': _richLifeCategories
            .map((id) => _RichLifeOption.labelFor(id))
            .join(', '),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();

      if (mounted) context.go(AppRoutes.dashboard);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_page + 1) / 4,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: _next),
                  _RichLifePage(
                    selected: _richLifeCategories,
                    onChanged: (cats) => setState(() {
                      _richLifeCategories
                        ..clear()
                        ..addAll(cats);
                    }),
                    onNext: _next,
                  ),
                  _IncomePage(
                    controller: _incomeCtrl,
                    currency: _currency,
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onNext: _next,
                  ),
                  _BucketPage(
                    fixedPct: _fixedPct,
                    savPct: _savPct,
                    invPct: _invPct,
                    freePct: _freePct,
                    onChanged: (f, s, i, g) => setState(() {
                      _fixedPct = f; _savPct = s; _invPct = i; _freePct = g;
                    }),
                    loading: _loading,
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pages ─────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 80))
              .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const Gap(24),
          Text(
            'Bienvenido a ElenaCash',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const Gap(12),
          Text(
            'En los próximos 3 minutos vas a configurar un sistema financiero '
            'que trabaja por ti — automáticamente, sin culpa, sin stress.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ).animate().fadeIn(delay: 500.ms),
          const Gap(40),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Empezar 🚀'),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }
}

// ── Rich Life — selección múltiple estructurada ───────────────────

class _RichLifeOption {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final _RichLifeProfile profile; // para diagnóstico

  const _RichLifeOption({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.profile,
  });

  static String labelFor(String id) =>
      _all.firstWhere((o) => o.id == id, orElse: () => _RichLifeOption(
        id: id, emoji: '', title: id, description: '', profile: _RichLifeProfile.builder,
      )).title;

  // 12 categorías basadas en Sethi + DeMarco + contexto LATAM
  static const _all = [
    _RichLifeOption(
      id: 'tiempo_libre',
      emoji: '⏰',
      title: 'Tiempo libre',
      description: 'Trabajar menos horas, más días libres, horario flexible',
      profile: _RichLifeProfile.freedom,
    ),
    _RichLifeOption(
      id: 'viajes',
      emoji: '✈️',
      title: 'Viajes y aventuras',
      description: 'Explorar el mundo sin mirar el precio de los tiquetes',
      profile: _RichLifeProfile.freedom,
    ),
    _RichLifeOption(
      id: 'familia',
      emoji: '👨‍👩‍👧',
      title: 'Familia y educación',
      description: 'Pagar el mejor colegio, vivir cerca, darles lo mejor',
      profile: _RichLifeProfile.provider,
    ),
    _RichLifeOption(
      id: 'hogar',
      emoji: '🏠',
      title: 'Casa propia',
      description: 'Tu espacio ideal, sin pagar arriendo toda la vida',
      profile: _RichLifeProfile.provider,
    ),
    _RichLifeOption(
      id: 'negocio',
      emoji: '🚀',
      title: 'Negocio propio',
      description: 'Construir algo tuyo, ser tu propio jefe, escalar',
      profile: _RichLifeProfile.builder,
    ),
    _RichLifeOption(
      id: 'independencia',
      emoji: '🔑',
      title: 'Independencia financiera',
      description: 'Que trabajar sea una opción, no una obligación',
      profile: _RichLifeProfile.investor,
    ),
    _RichLifeOption(
      id: 'salud',
      emoji: '💪',
      title: 'Salud y bienestar',
      description: 'Gym, nutrición, salud mental sin restricciones de precio',
      profile: _RichLifeProfile.lifestyle,
    ),
    _RichLifeOption(
      id: 'educacion',
      emoji: '📚',
      title: 'Educación y crecimiento',
      description: 'Cursos, libros, maestrías — aprender sin límites',
      profile: _RichLifeProfile.builder,
    ),
    _RichLifeOption(
      id: 'experiencias',
      emoji: '🎭',
      title: 'Experiencias y cultura',
      description: 'Conciertos, restaurantes, arte, momentos que no se olvidan',
      profile: _RichLifeProfile.lifestyle,
    ),
    _RichLifeOption(
      id: 'remoto',
      emoji: '💻',
      title: 'Trabajo desde donde quiera',
      description: 'Nomadismo digital, no estar atado a una oficina',
      profile: _RichLifeProfile.freedom,
    ),
    _RichLifeOption(
      id: 'lujo_cotidiano',
      emoji: '✨',
      title: 'Calidad sin culpa',
      description: 'Buena ropa, buen carro, vuelos en business — sin remordimiento',
      profile: _RichLifeProfile.lifestyle,
    ),
    _RichLifeOption(
      id: 'impacto',
      emoji: '🌱',
      title: 'Impacto y legado',
      description: 'Dejar algo al mundo, apoyar causas, generar cambio real',
      profile: _RichLifeProfile.investor,
    ),
  ];
}

/// Perfil de diagnóstico del usuario según sus selecciones.
/// Usado para personalizar recomendaciones futuras.
enum _RichLifeProfile { freedom, provider, builder, investor, lifestyle }

class _RichLifePage extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onNext;

  const _RichLifePage({
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  @override
  State<_RichLifePage> createState() => _RichLifePageState();
}

class _RichLifePageState extends State<_RichLifePage> {
  late final List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(List.from(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canContinue = _selected.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding, 24, AppConstants.defaultPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌟', style: const TextStyle(fontSize: 40))
                  .animate().fadeIn(),
              const Gap(12),
              Text('¿Qué es una vida rica para ti?',
                      style: theme.textTheme.headlineSmall)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(6),
              Text(
                'Selecciona todo lo que resuene contigo. '
                'Esto nos ayuda a personalizar tu plan.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ).animate().fadeIn(delay: 150.ms),
              const Gap(4),
              if (_selected.isNotEmpty)
                Text(
                  '${_selected.length} seleccionada${_selected.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding),
            itemCount: _RichLifeOption._all.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (ctx, i) {
              final opt = _RichLifeOption._all[i];
              final isSelected = _selected.contains(opt.id);
              return _RichLifeCard(
                option: opt,
                selected: isSelected,
                onTap: () => _toggle(opt.id),
              ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.04);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: canContinue ? widget.onNext : null,
              child: Text(canContinue
                  ? 'Siguiente →'
                  : 'Elige al menos una opción'),
            ),
          ),
        ),
      ],
    );
  }
}

class _RichLifeCard extends StatelessWidget {
  final _RichLifeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RichLifeCard({
    required this.option,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            Text(option.emoji, style: const TextStyle(fontSize: 22)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    option.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            AnimatedSwitcher(
              duration: AppConstants.animFast,
              child: selected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20, key: ValueKey(true))
                  : Icon(Icons.radio_button_unchecked_rounded,
                      color: theme.dividerColor, size: 20, key: ValueKey(false)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomePage extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onNext;
  const _IncomePage({
    required this.controller,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(32),
          Text('💰', style: const TextStyle(fontSize: 48)).animate().fadeIn(),
          const Gap(16),
          Text('¿Cuánto ganas al mes?', style: theme.textTheme.headlineSmall)
              .animate().fadeIn(delay: 100.ms),
          const Gap(8),
          Text(
            'Solo el ingreso neto que llega a tu cuenta. '
            'Si te pagan quincenal, multiplica por 2.',
            style: theme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms),
          const Gap(24),
          Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'COP', label: Text('COP')),
                  ButtonSegment(value: 'USD', label: Text('USD')),
                ],
                selected: {currency},
                onSelectionChanged: (s) => onCurrencyChanged(s.first),
              ),
            ],
          ).animate().fadeIn(delay: 250.ms),
          const Gap(12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: currency == 'COP' ? '\$ ' : 'USD ',
              hintText: currency == 'COP' ? '3,000,000' : '2,000',
            ),
          ).animate().fadeIn(delay: 300.ms),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) onNext();
              },
              child: const Text('Siguiente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketPage extends StatelessWidget {
  final double fixedPct, savPct, invPct, freePct;
  final void Function(double, double, double, double) onChanged;
  final bool loading;
  final VoidCallback onFinish;

  const _BucketPage({
    required this.fixedPct,
    required this.savPct,
    required this.invPct,
    required this.freePct,
    required this.onChanged,
    required this.loading,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = fixedPct + savPct + invPct + freePct;
    final isValid = total <= 100;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(24),
          Text('⚡', style: const TextStyle(fontSize: 48)).animate().fadeIn(),
          const Gap(12),
          Text('Configura tus 4 cubos', style: theme.textTheme.headlineSmall),
          const Gap(4),
          Text(
            'Estos son los valores por defecto (basados en el Conscious Spending Plan de Ramit Sethi). '
            'Puedes ajustarlos después.',
            style: theme.textTheme.bodySmall,
          ),
          const Gap(20),
          _BucketSlider(
            label: '🏠 Gastos Fijos',
            value: fixedPct,
            color: AppColors.bucketFixed,
            onChanged: (v) => onChanged(v, savPct, invPct, freePct),
          ),
          _BucketSlider(
            label: '🏦 Ahorro',
            value: savPct,
            color: AppColors.bucketSavings,
            onChanged: (v) => onChanged(fixedPct, v, invPct, freePct),
          ),
          _BucketSlider(
            label: '📈 Inversiones',
            value: invPct,
            color: AppColors.bucketInvestments,
            onChanged: (v) => onChanged(fixedPct, savPct, v, freePct),
          ),
          _BucketSlider(
            label: '🎉 Gasto Libre',
            value: freePct,
            color: AppColors.bucketFree,
            onChanged: (v) => onChanged(fixedPct, savPct, invPct, v),
          ),
          const Gap(8),
          Text(
            'Total: ${total.toStringAsFixed(0)}% ${isValid ? '✅' : '⚠️ Excede 100%'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isValid ? AppColors.primary : AppColors.error,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (isValid && !loading) ? onFinish : null,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('¡Activar mi sistema!'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BucketSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _BucketSlider({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13)),
              ),
              Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 80,
              divisions: 16,
              activeColor: color,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
