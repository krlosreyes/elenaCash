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

  // Step 1 – Rich Life
  final _richLifeCtrl = TextEditingController();
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
    _richLifeCtrl.dispose();
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

      // 2. Marcar onboarding como completado en el perfil del usuario
      final userRef = firestore.collection(AppConstants.colUsers).doc(uid);
      batch.set(userRef, {
        'onboardingCompleted': true,
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
                  _RichLifePage(controller: _richLifeCtrl, onNext: _next),
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

class _RichLifePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;
  const _RichLifePage({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(32),
          Text('💭', style: const TextStyle(fontSize: 48)).animate().fadeIn(),
          const Gap(16),
          Text('¿Qué es una vida rica para ti?', style: theme.textTheme.headlineSmall)
              .animate().fadeIn(delay: 100.ms),
          const Gap(8),
          Text(
            'No te estamos preguntando cuánto dinero quieres. '
            'Te preguntamos cómo sería un martes ordinario de tu vida si el dinero no fuera un problema.',
            style: theme.textTheme.bodyMedium,
          ).animate().fadeIn(delay: 200.ms),
          const Gap(24),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ej: Trabajar desde casa, viajar 3 meses al año, pagar el colegio de mis hijos sin preocupaciones...',
            ),
          ).animate().fadeIn(delay: 300.ms),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('Siguiente'),
            ),
          ),
        ],
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
