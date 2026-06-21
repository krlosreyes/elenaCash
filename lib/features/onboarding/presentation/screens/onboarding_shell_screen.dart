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
  // Step 3 – Gastos fijos
  Map<String, double> _expenseAmounts = {};
  // Step 4 – Deudas
  List<Map<String, dynamic>> _debtEntries = [];
  // Step 5 – Percentages (usa defaults)
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
    if (_page < 5) {
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

      final totalExpenses = _expenseAmounts.values.fold(0.0, (a, b) => a + b);
      final totalDebtPayments = _debtEntries.fold(
          0.0, (a, d) => a + (d['monthlyPayment'] as num? ?? 0).toDouble());

      // 2. Perfil del usuario: onboarding + Rich Life + ingresos + gastos
      final userRef = firestore.collection(AppConstants.colUsers).doc(uid);
      batch.set(userRef, {
        'onboardingCompleted': true,
        'monthlyNetIncome': income,
        'richLifeCategories': _richLifeCategories,
        'richLifeDescription': _richLifeCategories
            .map((id) => _RichLifeOption.labelFor(id))
            .join(', '),
        'incomeBreakdown': _incomeBreakdown,
        'expenseBreakdown': _expenseAmounts,
        'totalMonthlyExpenses': totalExpenses,
        'totalMonthlyDebtPayments': totalDebtPayments,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Deudas como subcolección
      for (final debt in _debtEntries) {
        final debtRef = userRef.collection(AppConstants.colDebts).doc();
        batch.set(debtRef, {
          ...debt,
          'userId': uid,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

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
              value: (_page + 1) / 6,
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
                  _ExpensesPage(
                    currency: _currency,
                    onExpensesChanged: (v) => setState(() => _expenseAmounts = v),
                    onNext: _next,
                  ),
                  _DebtsPage(
                    currency: _currency,
                    onDebtsChanged: (v) => setState(() => _debtEntries = v),
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

// ── Expense data ──────────────────────────────────────────────────

class _ExpenseItem {
  final String id;
  final String emoji;
  final String label;
  final String group;
  const _ExpenseItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.group,
  });

  static const _all = [
    // Vivienda
    _ExpenseItem(id: 'vivienda', emoji: '🏠', label: 'Arriendo / Cuota hipoteca', group: 'Vivienda'),
    _ExpenseItem(id: 'admin', emoji: '🏢', label: 'Administración', group: 'Vivienda'),
    // Servicios hogar
    _ExpenseItem(id: 'agua', emoji: '💧', label: 'Agua y alcantarillado', group: 'Servicios hogar'),
    _ExpenseItem(id: 'energia', emoji: '⚡', label: 'Energía eléctrica', group: 'Servicios hogar'),
    _ExpenseItem(id: 'gas', emoji: '🔥', label: 'Gas natural', group: 'Servicios hogar'),
    _ExpenseItem(id: 'internet', emoji: '📡', label: 'Internet hogar', group: 'Servicios hogar'),
    _ExpenseItem(id: 'tv_cable', emoji: '📺', label: 'TV / Cable', group: 'Servicios hogar'),
    // Servicios personales
    _ExpenseItem(id: 'celular', emoji: '📱', label: 'Plan celular', group: 'Servicios personales'),
    _ExpenseItem(id: 'transporte', emoji: '🚌', label: 'Transporte mensual', group: 'Servicios personales'),
    // Suscripciones
    _ExpenseItem(id: 'streaming', emoji: '🎬', label: 'Streaming (Netflix, Disney+...)', group: 'Suscripciones'),
    _ExpenseItem(id: 'musica', emoji: '🎵', label: 'Música (Spotify...)', group: 'Suscripciones'),
    _ExpenseItem(id: 'gym', emoji: '💪', label: 'Gimnasio / fitness', group: 'Suscripciones'),
    _ExpenseItem(id: 'otras_subs', emoji: '🔄', label: 'Otras suscripciones', group: 'Suscripciones'),
    // Alimentación
    _ExpenseItem(id: 'mercado', emoji: '🛒', label: 'Mercado mensual', group: 'Alimentación'),
    _ExpenseItem(id: 'restaurantes', emoji: '🍽️', label: 'Restaurantes / domicilios', group: 'Alimentación'),
    // Educación
    _ExpenseItem(id: 'educacion', emoji: '🎓', label: 'Colegio / universidad / pensión', group: 'Educación'),
    _ExpenseItem(id: 'cursos', emoji: '📚', label: 'Cursos y capacitaciones', group: 'Educación'),
    // Vehículo
    _ExpenseItem(id: 'gasolina', emoji: '⛽', label: 'Gasolina mensual', group: 'Vehículo'),
    _ExpenseItem(id: 'seg_vehiculo', emoji: '🚗', label: 'Seguro vehículo / SOAT', group: 'Vehículo'),
    // Seguros
    _ExpenseItem(id: 'medicina', emoji: '💊', label: 'Medicina prepagada / EPS voluntaria', group: 'Seguros'),
    _ExpenseItem(id: 'seg_vida', emoji: '🛡️', label: 'Seguro de vida', group: 'Seguros'),
  ];

  static List<String> get groups =>
      _all.map((e) => e.group).toSet().toList();

  static List<_ExpenseItem> byGroup(String group) =>
      _all.where((e) => e.group == group).toList();
}

// ── Expenses page ──────────────────────────────────────────────────

class _ExpensesPage extends StatefulWidget {
  final String currency;
  final ValueChanged<Map<String, double>> onExpensesChanged;
  final VoidCallback onNext;

  const _ExpensesPage({
    required this.currency,
    required this.onExpensesChanged,
    required this.onNext,
  });

  @override
  State<_ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<_ExpensesPage> {
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {for (final item in _ExpenseItem._all) item.id: TextEditingController()};
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  double _parse(String v) =>
      double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  Map<String, double> get _expenseMap {
    final map = <String, double>{};
    for (final e in _ctrls.entries) {
      final v = _parse(e.value.text);
      if (v > 0) map[e.key] = v;
    }
    return map;
  }

  double get _total => _expenseMap.values.fold(0, (a, b) => a + b);

  String _fmt(double v) {
    if (widget.currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  void _notify() {
    widget.onExpensesChanged(_expenseMap);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding, 20, AppConstants.defaultPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🧾', style: const TextStyle(fontSize: 40)).animate().fadeIn(),
              const Gap(10),
              Text('¿Cuánto gastas al mes?',
                      style: theme.textTheme.headlineSmall)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(4),
              Text(
                'Solo los gastos fijos y recurrentes. Deja en blanco los que no aplican.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ).animate().fadeIn(delay: 150.ms),
            ],
          ),
        ),
        const Gap(8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding),
            itemCount: _ExpenseItem.groups.length,
            itemBuilder: (ctx, gi) {
              final group = _ExpenseItem.groups[gi];
              final items = _ExpenseItem.byGroup(group);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(16),
                  Text(group,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                  const Gap(6),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text(item.emoji,
                                style: const TextStyle(fontSize: 16)),
                            const Gap(8),
                            Expanded(
                              child: Text(item.label,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                            ),
                            const Gap(8),
                            SizedBox(
                              width: 110,
                              height: 38,
                              child: TextField(
                                controller: _ctrls[item.id],
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _notify(),
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  prefixText:
                                      widget.currency == 'COP' ? '\$ ' : 'USD ',
                                  hintText: '0',
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
        ),
        // Total bar
        Container(
          margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text('Total gastos fijos:',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                total > 0 ? _fmt(total) : '—',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onNext,
                    child: const Text('Omitir'),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onExpensesChanged(_expenseMap);
                      widget.onNext();
                    },
                    child: Text(total > 0 ? 'Siguiente →' : 'Continuar sin gastos'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
      ],
    );
  }
}

// ── Debt data ──────────────────────────────────────────────────────

class _DebtEntry {
  final String tempId;
  String type;
  String name;
  double monthlyPayment;
  double balance;

  _DebtEntry({
    required this.tempId,
    this.type = 'tarjeta',
    this.name = '',
    this.monthlyPayment = 0,
    this.balance = 0,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'name': name,
    'monthlyPayment': monthlyPayment,
    'balance': balance,
  };
}

const _debtTypes = [
  (id: 'hipotecario', emoji: '🏠', label: 'Hipotecario'),
  (id: 'vehiculo', emoji: '🚗', label: 'Vehículo'),
  (id: 'estudio', emoji: '🎓', label: 'Educación'),
  (id: 'tarjeta', emoji: '💳', label: 'Tarjeta crédito'),
  (id: 'libre_inversion', emoji: '💰', label: 'Libre inversión'),
  (id: 'libranza', emoji: '📋', label: 'Libranza'),
  (id: 'rotativo', emoji: '🔄', label: 'Cupo rotativo'),
  (id: 'personal', emoji: '🤝', label: 'Préstamo personal'),
];

// ── Debts page ──────────────────────────────────────────────────────

class _DebtsPage extends StatefulWidget {
  final String currency;
  final ValueChanged<List<Map<String, dynamic>>> onDebtsChanged;
  final VoidCallback onNext;

  const _DebtsPage({
    required this.currency,
    required this.onDebtsChanged,
    required this.onNext,
  });

  @override
  State<_DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<_DebtsPage> {
  final List<_DebtEntry> _debts = [];
  int _idCounter = 0;

  void _addDebt() {
    final entry = _DebtEntry(tempId: 'debt_${_idCounter++}');
    _showDebtForm(entry, isNew: true);
  }

  void _editDebt(_DebtEntry entry) => _showDebtForm(entry, isNew: false);

  void _removeDebt(String id) {
    setState(() => _debts.removeWhere((d) => d.tempId == id));
    widget.onDebtsChanged(_debts.map((d) => d.toMap()).toList());
  }

  void _showDebtForm(_DebtEntry entry, {required bool isNew}) {
    final nameCtrl = TextEditingController(text: entry.name);
    final payCtrl = TextEditingController(
        text: entry.monthlyPayment > 0 ? entry.monthlyPayment.toStringAsFixed(0) : '');
    final balCtrl = TextEditingController(
        text: entry.balance > 0 ? entry.balance.toStringAsFixed(0) : '');
    String selectedType = entry.type;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final theme = Theme.of(ctx);
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(isNew ? 'Agregar deuda' : 'Editar deuda',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Text('Tipo de deuda:',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _debtTypes.map((dt) {
                      final sel = dt.id == selectedType;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedType = dt.id),
                        child: AnimatedContainer(
                          duration: AppConstants.animFast,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primarySurface
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : theme.dividerColor,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Text('${dt.emoji} ${dt.label}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: sel ? AppColors.primary : null,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(16),
                  Text('Nombre / descripción:',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(6),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Tarjeta Davivienda, Crédito Bancolombia...',
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cuota mensual:',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const Gap(6),
                            TextField(
                              controller: payCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: widget.currency == 'COP'
                                    ? '\$ '
                                    : 'USD ',
                                hintText: '0',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saldo actual (opcional):',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const Gap(6),
                            TextField(
                              controller: balCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: widget.currency == 'COP'
                                    ? '\$ '
                                    : 'USD ',
                                hintText: '0',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final pay = double.tryParse(payCtrl.text
                                .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                            0;
                        final bal = double.tryParse(balCtrl.text
                                .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                            0;
                        if (pay <= 0 && nameCtrl.text.trim().isEmpty) {
                          Navigator.pop(ctx);
                          return;
                        }
                        setState(() {
                          entry.type = selectedType;
                          entry.name = nameCtrl.text.trim().isEmpty
                              ? _debtTypes
                                    .firstWhere((d) => d.id == selectedType)
                                    .label
                              : nameCtrl.text.trim();
                          entry.monthlyPayment = pay;
                          entry.balance = bal;
                          if (isNew) _debts.add(entry);
                        });
                        widget.onDebtsChanged(
                            _debts.map((d) => d.toMap()).toList());
                        Navigator.pop(ctx);
                      },
                      child: Text(isNew ? 'Agregar' : 'Guardar cambios'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(double v) {
    if (widget.currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  double get _totalPayments =>
      _debts.fold(0, (a, d) => a + d.monthlyPayment);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.defaultPadding, 20, AppConstants.defaultPadding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💳', style: const TextStyle(fontSize: 40)).animate().fadeIn(),
              const Gap(10),
              Text('¿Tienes deudas?',
                      style: theme.textTheme.headlineSmall)
                  .animate().fadeIn(delay: 100.ms),
              const Gap(4),
              Text(
                'Créditos, tarjetas, libranzas, cupos rotativos — todo lo que tienes en cuotas.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark),
              ).animate().fadeIn(delay: 150.ms),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: _debts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉',
                          style: const TextStyle(fontSize: 48)).animate().fadeIn(),
                      const Gap(12),
                      Text('Sin deudas registradas',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Gap(4),
                      Text('Toca + para agregar una deuda',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondaryDark)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding),
                  itemCount: _debts.length,
                  separatorBuilder: (_, __) => const Gap(8),
                  itemBuilder: (ctx, i) {
                    final debt = _debts[i];
                    final typeInfo = _debtTypes.firstWhere(
                        (t) => t.id == debt.type,
                        orElse: () => _debtTypes.last);
                    return GestureDetector(
                      onTap: () => _editDebt(debt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(
                              AppConstants.buttonRadius),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Text(typeInfo.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const Gap(10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(debt.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(typeInfo.label,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color:
                                                  AppColors.textSecondaryDark)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_fmt(debt.monthlyPayment),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error)),
                                Text('/mes',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                            color:
                                                AppColors.textSecondaryDark)),
                              ],
                            ),
                            const Gap(8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              color: theme.dividerColor,
                              onPressed: () => _removeDebt(debt.tempId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.04),
                    );
                  },
                ),
        ),
        // Add button
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _addDebt,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar deuda'),
            ),
          ),
        ),
        const Gap(8),
        // Total
        if (_debts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text('Total cuotas mensuales:',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    _fmt(_totalPayments),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onNext,
                    child: const Text('Omitir'),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDebtsChanged(
                          _debts.map((d) => d.toMap()).toList());
                      widget.onNext();
                    },
                    child: Text(_debts.isEmpty
                        ? 'No tengo deudas →'
                        : 'Siguiente →'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(16),
      ],
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
