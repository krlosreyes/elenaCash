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
  double _netMonthlyIncome = 0;
  Map<String, dynamic> _incomeBreakdown = {};
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
      final income = _netMonthlyIncome;

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

      // 2. Perfil del usuario: onboarding + Rich Life + desglose de ingresos
      final userRef = firestore.collection(AppConstants.colUsers).doc(uid);
      batch.set(userRef, {
        'onboardingCompleted': true,
        'monthlyNetIncome': income,
        'richLifeCategories': _richLifeCategories,
        'richLifeDescription': _richLifeCategories
            .map((id) => _RichLifeOption.labelFor(id))
            .join(', '),
        'incomeBreakdown': _incomeBreakdown,
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
                    currency: _currency,
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onIncomeChanged: (v) => setState(() => _netMonthlyIncome = v),
                    onBreakdownChanged: (v) => setState(() => _incomeBreakdown = v),
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

// ── Income types ──────────────────────────────────────────────────

enum _IncomeType { employee, freelance, mixed }

class _IncomePage extends StatefulWidget {
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<double> onIncomeChanged;
  final ValueChanged<Map<String, dynamic>> onBreakdownChanged;
  final VoidCallback onNext;

  const _IncomePage({
    required this.currency,
    required this.onCurrencyChanged,
    required this.onIncomeChanged,
    required this.onBreakdownChanged,
    required this.onNext,
  });

  @override
  State<_IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<_IncomePage> {
  int _subStep = 0;
  _IncomeType? _type;

  // Employee fields
  final _salaryCtrl = TextEditingController();
  final _prestComCtrl = TextEditingController();
  final _nonPrestComCtrl = TextEditingController();
  bool _hasCommissions = false;

  // Freelance fields
  String _freelanceActivity = 'services';
  final _grossCtrl = TextEditingController();
  final _expensesCtrl = TextEditingController();
  final _socialSecCtrl = TextEditingController();
  bool _hasSocialSecurity = false;

  // Mixed fields
  final _empNetCtrl = TextEditingController();
  final _freNetCtrl = TextEditingController();

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _prestComCtrl.dispose();
    _nonPrestComCtrl.dispose();
    _grossCtrl.dispose();
    _expensesCtrl.dispose();
    _socialSecCtrl.dispose();
    _empNetCtrl.dispose();
    _freNetCtrl.dispose();
    super.dispose();
  }

  double _parse(String v) =>
      double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  double get _computedNet {
    switch (_type) {
      case _IncomeType.employee:
        final salary = _parse(_salaryCtrl.text);
        final prestCom = _hasCommissions ? _parse(_prestComCtrl.text) : 0.0;
        final nonPrestCom = _hasCommissions ? _parse(_nonPrestComCtrl.text) : 0.0;
        // 4% salud + 4% pensión sobre base prestacional
        final prestBase = salary + prestCom;
        return prestBase * 0.92 + nonPrestCom;
      case _IncomeType.freelance:
        final gross = _parse(_grossCtrl.text);
        final expenses = _parse(_expensesCtrl.text);
        final social = _hasSocialSecurity ? _parse(_socialSecCtrl.text) : 0.0;
        return gross - expenses - social;
      case _IncomeType.mixed:
        return _parse(_empNetCtrl.text) + _parse(_freNetCtrl.text);
      default:
        return 0;
    }
  }

  Map<String, dynamic> get _breakdown {
    switch (_type) {
      case _IncomeType.employee:
        return {
          'type': 'employee',
          'salarioBaseBruto': _parse(_salaryCtrl.text),
          if (_hasCommissions) 'comisionesPrestacionales': _parse(_prestComCtrl.text),
          if (_hasCommissions) 'comisionesNoPrestacionales': _parse(_nonPrestComCtrl.text),
          'deduccionesEstimadas': (_parse(_salaryCtrl.text) + (_hasCommissions ? _parse(_prestComCtrl.text) : 0)) * 0.08,
          'netoEstimado': _computedNet,
        };
      case _IncomeType.freelance:
        return {
          'type': 'freelance',
          'actividad': _freelanceActivity,
          'ingresosBrutos': _parse(_grossCtrl.text),
          'gastosOperacionales': _parse(_expensesCtrl.text),
          if (_hasSocialSecurity) 'seguridadSocial': _parse(_socialSecCtrl.text),
          'netoEstimado': _computedNet,
        };
      case _IncomeType.mixed:
        return {
          'type': 'mixed',
          'netoEmpleado': _parse(_empNetCtrl.text),
          'netoIndependiente': _parse(_freNetCtrl.text),
          'netoEstimado': _computedNet,
        };
      default:
        return {};
    }
  }

  bool get _canContinue {
    switch (_type) {
      case _IncomeType.employee:
        return _parse(_salaryCtrl.text) > 0;
      case _IncomeType.freelance:
        return _parse(_grossCtrl.text) > 0;
      case _IncomeType.mixed:
        return _parse(_empNetCtrl.text) + _parse(_freNetCtrl.text) > 0;
      default:
        return false;
    }
  }

  void _selectType(_IncomeType type) {
    setState(() {
      _type = type;
      _subStep = 1;
    });
  }

  void _handleNext() {
    widget.onIncomeChanged(_computedNet);
    widget.onBreakdownChanged(_breakdown);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_subStep == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextButton.icon(
              onPressed: () => setState(() { _subStep = 0; _type = null; }),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Tipo de ingreso'),
            ),
          ),
        if (_subStep == 0)
          _buildTypeSelection()
        else
          Expanded(child: _buildIncomeForm()),
      ],
    );
  }

  Widget _buildTypeSelection() {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(16),
            Text('💰', style: const TextStyle(fontSize: 48)).animate().fadeIn(),
            const Gap(12),
            Text('¿Cómo generas tus ingresos?', style: theme.textTheme.headlineSmall)
                .animate().fadeIn(delay: 100.ms),
            const Gap(6),
            Text(
              'Elige la opción que mejor te describe. '
              'Así calculamos tu ingreso disponible real.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
            ).animate().fadeIn(delay: 150.ms),
            const Gap(28),
            _IncomeTypeCard(
              emoji: '🏢',
              title: 'Empleado',
              description: 'Recibo salario fijo de un empleador',
              onTap: () => _selectType(_IncomeType.employee),
            ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.05),
            const Gap(12),
            _IncomeTypeCard(
              emoji: '💼',
              title: 'Independiente / Freelancer',
              description: 'Trabajo por honorarios, ventas o negocios propios',
              onTap: () => _selectType(_IncomeType.freelance),
            ).animate(delay: 280.ms).fadeIn().slideX(begin: 0.05),
            const Gap(12),
            _IncomeTypeCard(
              emoji: '⚡',
              title: 'Mixto',
              description: 'Soy empleado y también tengo ingresos independientes',
              onTap: () => _selectType(_IncomeType.mixed),
            ).animate(delay: 360.ms).fadeIn().slideX(begin: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeForm() {
    return switch (_type) {
      _IncomeType.employee => _buildEmployeeForm(),
      _IncomeType.freelance => _buildFreelanceForm(),
      _IncomeType.mixed => _buildMixedForm(),
      null => const SizedBox(),
    };
  }

  Widget _buildEmployeeForm() {
    final theme = Theme.of(context);
    final salary = _parse(_salaryCtrl.text);
    final prestCom = _hasCommissions ? _parse(_prestComCtrl.text) : 0.0;
    final nonPrestCom = _hasCommissions ? _parse(_nonPrestComCtrl.text) : 0.0;
    final prestBase = salary + prestCom;
    final deductions = prestBase * 0.08;
    final net = _computedNet;
    final hasData = salary > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            children: [
              const Gap(8),
              Text('🏢 Ingreso como empleado',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Gap(4),
              Text('Ingresa valores brutos — calculamos el neto automáticamente.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              _CurrencySelector(currency: widget.currency, onChanged: widget.onCurrencyChanged),
              const Gap(18),
              _IncomeField(
                label: 'Salario base mensual bruto',
                hint: widget.currency == 'COP' ? '3,000,000' : '2,000',
                prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                controller: _salaryCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(4),
              Text('Tu salario antes de descuentos de nómina.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: Text('¿Recibes comisiones o bonos?',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Switch.adaptive(
                    value: _hasCommissions,
                    onChanged: (v) => setState(() => _hasCommissions = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              if (_hasCommissions) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ℹ️ Tipos de comisiones',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.primary, fontWeight: FontWeight.w700)),
                      const Gap(6),
                      Text(
                        '• Prestacionales: base para prima, cesantías y vacaciones. '
                        'Se les descuenta salud y pensión (8%).',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Gap(4),
                      Text(
                        '• No prestacionales: bonos o pagos extra que NO entran en la '
                        'liquidación de prestaciones sociales.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                _IncomeField(
                  label: 'Comisiones prestacionales',
                  hint: '0',
                  prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                  controller: _prestComCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(4),
                Text('Se incluyen en la base de prima, cesantías y vacaciones.',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
                const Gap(14),
                _IncomeField(
                  label: 'Comisiones no prestacionales',
                  hint: '0',
                  prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                  controller: _nonPrestComCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(4),
                Text('Bonos o pagos extra sin efecto en prestaciones sociales.',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              ],
              const Gap(24),
              if (hasData)
                _NetCalculatorCard(
                  currency: widget.currency,
                  rows: [
                    _CalcRow('Salario base bruto', salary, isDeduction: false),
                    if (_hasCommissions && prestCom > 0)
                      _CalcRow('+ Comisiones prestacionales', prestCom, isDeduction: false),
                    _CalcRow('- Salud (4%) + Pensión (4%)', deductions, isDeduction: true),
                    if (_hasCommissions && nonPrestCom > 0)
                      _CalcRow('+ Comisiones no prestacionales', nonPrestCom, isDeduction: false),
                  ],
                  net: net,
                  note: 'La retención en la fuente varía según tu nivel salarial y no está incluida.',
                ),
              const Gap(24),
            ],
          ),
        ),
        _NextButton(enabled: _canContinue, onTap: _handleNext),
      ],
    );
  }

  Widget _buildFreelanceForm() {
    final theme = Theme.of(context);
    final gross = _parse(_grossCtrl.text);
    final expenses = _parse(_expensesCtrl.text);
    final social = _hasSocialSecurity ? _parse(_socialSecCtrl.text) : 0.0;
    final net = _computedNet;
    final hasData = gross > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            children: [
              const Gap(8),
              Text('💼 Ingreso independiente',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Gap(4),
              Text('Calculamos lo que realmente queda disponible.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              _CurrencySelector(currency: widget.currency, onChanged: widget.onCurrencyChanged),
              const Gap(18),
              Text('Tipo de actividad:',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _ActivityChip(
                      label: '👨‍💻 Servicios / Honorarios',
                      value: 'services',
                      selected: _freelanceActivity,
                      onTap: (v) => setState(() => _freelanceActivity = v)),
                  _ActivityChip(
                      label: '🛒 Ventas / Comercio',
                      value: 'sales',
                      selected: _freelanceActivity,
                      onTap: (v) => setState(() => _freelanceActivity = v)),
                  _ActivityChip(
                      label: '🏘️ Arriendos',
                      value: 'rental',
                      selected: _freelanceActivity,
                      onTap: (v) => setState(() => _freelanceActivity = v)),
                  _ActivityChip(
                      label: '🔀 Mixto',
                      value: 'mixed_act',
                      selected: _freelanceActivity,
                      onTap: (v) => setState(() => _freelanceActivity = v)),
                ],
              ),
              const Gap(20),
              _IncomeField(
                label: 'Ingresos brutos promedio mensual',
                hint: widget.currency == 'COP' ? '5,000,000' : '3,000',
                prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                controller: _grossCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(4),
              Text('Total que recibes de clientes o ventas antes de cualquier descuento.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              _IncomeField(
                label: 'Gastos del negocio mensuales (opcional)',
                hint: '0',
                prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                controller: _expensesCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(4),
              Text('Software, arriendo, transporte, insumos, etc.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿Cotizas seguridad social?',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        Text('Salud + pensión como independiente',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondaryDark)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _hasSocialSecurity,
                    onChanged: (v) => setState(() => _hasSocialSecurity = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              if (_hasSocialSecurity) ...[
                const Gap(12),
                _IncomeField(
                  label: 'Aporte mensual a seguridad social',
                  hint: '0',
                  prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                  controller: _socialSecCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const Gap(4),
                Text(
                  'Como independiente aportas aprox. 28.5% sobre el 40% de tus ingresos brutos.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark),
                ),
              ],
              const Gap(24),
              if (hasData)
                _NetCalculatorCard(
                  currency: widget.currency,
                  rows: [
                    _CalcRow('Ingresos brutos', gross, isDeduction: false),
                    if (expenses > 0)
                      _CalcRow('- Gastos operacionales', expenses, isDeduction: true),
                    if (_hasSocialSecurity && social > 0)
                      _CalcRow('- Seguridad social', social, isDeduction: true),
                  ],
                  net: net,
                  note: 'No incluye retención en la fuente (varía según tipo de servicio y cliente).',
                ),
              const Gap(24),
            ],
          ),
        ),
        _NextButton(enabled: _canContinue, onTap: _handleNext),
      ],
    );
  }

  Widget _buildMixedForm() {
    final theme = Theme.of(context);
    final empNet = _parse(_empNetCtrl.text);
    final freNet = _parse(_freNetCtrl.text);
    final net = _computedNet;
    final hasData = net > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            children: [
              const Gap(8),
              Text('⚡ Ingresos mixtos',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Gap(4),
              Text('Ingresa el neto de cada fuente por separado.',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(20),
              _CurrencySelector(currency: widget.currency, onChanged: widget.onCurrencyChanged),
              const Gap(20),
              Text('Como empleado:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
              const Gap(8),
              _IncomeField(
                label: 'Neto mensual como empleado',
                hint: '0',
                prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                controller: _empNetCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(4),
              Text('Lo que llega a tu cuenta después de salud, pensión y retenciones.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(24),
              Text('Como independiente:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
              const Gap(8),
              _IncomeField(
                label: 'Neto mensual independiente',
                hint: '0',
                prefix: widget.currency == 'COP' ? '\$ ' : 'USD ',
                controller: _freNetCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const Gap(4),
              Text('Lo que queda después de gastos del negocio y seguridad social.',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryDark)),
              const Gap(24),
              if (hasData)
                _NetCalculatorCard(
                  currency: widget.currency,
                  rows: [
                    _CalcRow('Neto como empleado', empNet, isDeduction: false),
                    _CalcRow('+ Neto independiente', freNet, isDeduction: false),
                  ],
                  net: net,
                  note: null,
                ),
              const Gap(24),
            ],
          ),
        ),
        _NextButton(enabled: _canContinue, onTap: _handleNext),
      ],
    );
  }
}

// ── Income helper widgets ─────────────────────────────────────────

class _IncomeTypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _IncomeTypeCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(description,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }
}

class _IncomeField extends StatelessWidget {
  final String label;
  final String hint;
  final String prefix;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _IncomeField({
    required this.label,
    required this.hint,
    required this.prefix,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Gap(6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          onChanged: onChanged,
          decoration: InputDecoration(prefixText: prefix, hintText: hint),
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final String currency;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({required this.currency, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Moneda:',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Gap(12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'COP', label: Text('COP')),
            ButtonSegment(value: 'USD', label: Text('USD')),
          ],
          selected: {currency},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _ActivityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }
}

class _CalcRow {
  final String label;
  final double amount;
  final bool isDeduction;
  const _CalcRow(this.label, this.amount, {required this.isDeduction});
}

class _NetCalculatorCard extends StatelessWidget {
  final String currency;
  final List<_CalcRow> rows;
  final double net;
  final String? note;

  const _NetCalculatorCard({
    required this.currency,
    required this.rows,
    required this.net,
    this.note,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Ingreso neto estimado',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          const Gap(10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(r.label, style: theme.textTheme.bodySmall)),
                    Text(
                      r.isDeduction ? '- ${_fmt(r.amount)}' : _fmt(r.amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: r.isDeduction ? AppColors.error : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Neto mensual disponible',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(_fmt(net),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  )),
            ],
          ),
          if (note != null) ...[
            const Gap(8),
            Text('⚠️ $note',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textSecondaryDark)),
          ],
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _NextButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          child: const Text('Siguiente →'),
        ),
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
