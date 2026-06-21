import 'dart:math';

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
  double _netMonthlyIncome = 0;   // ingreso laboral neto
  double _additionalIncome = 0;   // inversiones, arriendos, pasivos
  double get _totalIncome => _netMonthlyIncome + _additionalIncome;
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

  /// Convierte una clave del breakdown de ingresos en una rama del árbol.
  Map<String, dynamic>? _incomeBreakdownToBranch(String key, double monthly, String uid) {
    if (monthly <= 0) return null;
    String label, type;
    switch (key) {
      case 'plat_cdt':
      case 'totalCDT':
        label = 'CDT'; type = 'investment';
      case 'plat_fondos':
      case 'totalFondos':
        label = 'Fondos / ETFs'; type = 'investment';
      case 'plat_arriendo':
      case 'totalArriendo':
        label = 'Arriendos'; type = 'rental';
      case 'plat_negocio':
      case 'totalNegocio':
        label = 'Distribuciones de negocio'; type = 'business';
      default:
        label = 'Ingresos adicionales'; type = 'other';
    }
    return {
      'id': 'onboarding_$key',
      'label': label,
      'type': type,
      'monthlyAmount': monthly,
      'userId': uid,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
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
      final income = _totalIncome;

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
        'additionalIncome': _additionalIncome,
        'expenseBreakdown': _expenseAmounts,
        'totalMonthlyExpenses': totalExpenses,
        'totalMonthlyDebtPayments': totalDebtPayments,
        'financialDiagnosis': _totalIncome > 0
            ? _computeDiagnosis(((totalExpenses + totalDebtPayments) /
                        _totalIncome *
                        100)
                    .clamp(0.0, 100.0))
                .name
            : 'unknown',
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

      // 4. Árbol del Dinero — poblar desde ingresos pasivos capturados
      if (_additionalIncome > 0) {
        final fastlaneRef = firestore
            .collection(AppConstants.colUsers)
            .doc(uid)
            .collection(AppConstants.colFastlaneEngine)
            .doc('current');

        // Crear ramas desde el breakdown de ingresos adicionales
        final branches = <Map<String, dynamic>>[];
        _incomeBreakdown.forEach((key, value) {
          if (!key.startsWith('plat_') && value is num && value > 0) {
            final branchData = _incomeBreakdownToBranch(key, value.toDouble(), uid);
            if (branchData != null) branches.add(branchData);
          }
        });

        // Si no hay breakdown detallado, crear una rama genérica
        if (branches.isEmpty && _additionalIncome > 0) {
          branches.add({
            'id': 'onboarding_passive',
            'label': 'Ingresos pasivos',
            'type': 'investment',
            'monthlyAmount': _additionalIncome,
            'userId': uid,
            'isActive': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }

        final passiveRatio = income > 0 ? (_additionalIncome / income) * 100 : 0.0;
        double score = passiveRatio * 0.7;
        if (_additionalIncome >= 500000) score += 10;
        if (_additionalIncome >= 2000000) score += 10;
        if (_additionalIncome >= 5000000) score += 10;

        batch.set(fastlaneRef, {
          'userId': uid,
          'activeIncomeMonthly': _netMonthlyIncome,
          'passiveIncomeMonthly': _additionalIncome,
          'fastLaneScore': score.clamp(0, 100),
          'moneyTreeBranches': branches,
          'totalMonthlyExpenses': totalExpenses,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
                    onAdditionalIncomeChanged: (v) => setState(() => _additionalIncome = v),
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
                  _DiagnosisPage(
                    totalIncome: _totalIncome,
                    laborIncome: _netMonthlyIncome,
                    additionalIncome: _additionalIncome,
                    totalExpenses: _expenseAmounts.values.fold(0.0, (a, b) => a + b),
                    totalDebtPayments: _debtEntries.fold(
                        0.0, (a, d) => a + (d['monthlyPayment'] as num? ?? 0).toDouble()),
                    richLifeCategories: _richLifeCategories,
                    currency: _currency,
                    onBucketsConfirmed: (f, s, i, g) => setState(() {
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
  final ValueChanged<double> onAdditionalIncomeChanged;
  final ValueChanged<Map<String, dynamic>> onBreakdownChanged;
  final VoidCallback onNext;

  const _IncomePage({
    required this.currency,
    required this.onCurrencyChanged,
    required this.onIncomeChanged,
    required this.onAdditionalIncomeChanged,
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

  // Ingresos pasivos / adicionales — gestionados por _AdditionalIncomeSection
  double _additionalIncome = 0;

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
    final addInc = <String, dynamic>{
      if (_additionalIncome > 0) 'totalAdicional': _additionalIncome,
    };
    switch (_type) {
      case _IncomeType.employee:
        return {
          'type': 'employee',
          'salarioBaseBruto': _parse(_salaryCtrl.text),
          if (_hasCommissions) 'comisionesPrestacionales': _parse(_prestComCtrl.text),
          if (_hasCommissions) 'comisionesNoPrestacionales': _parse(_nonPrestComCtrl.text),
          'deduccionesEstimadas': (_parse(_salaryCtrl.text) + (_hasCommissions ? _parse(_prestComCtrl.text) : 0)) * 0.08,
          'netoLaboral': _computedNet,
          ...addInc,
        };
      case _IncomeType.freelance:
        return {
          'type': 'freelance',
          'actividad': _freelanceActivity,
          'ingresosBrutos': _parse(_grossCtrl.text),
          'gastosOperacionales': _parse(_expensesCtrl.text),
          if (_hasSocialSecurity) 'seguridadSocial': _parse(_socialSecCtrl.text),
          'netoLaboral': _computedNet,
          ...addInc,
        };
      case _IncomeType.mixed:
        return {
          'type': 'mixed',
          'netoEmpleado': _parse(_empNetCtrl.text),
          'netoIndependiente': _parse(_freNetCtrl.text),
          'netoLaboral': _computedNet,
          ...addInc,
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
    widget.onAdditionalIncomeChanged(_additionalIncome);
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
              _AdditionalIncomeSection(
                currency: widget.currency,
                onTotalChanged: (v) => setState(() => _additionalIncome = v),
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
              _AdditionalIncomeSection(
                currency: widget.currency,
                onTotalChanged: (v) => setState(() => _additionalIncome = v),
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
              _AdditionalIncomeSection(
                currency: widget.currency,
                onTotalChanged: (v) => setState(() => _additionalIncome = v),
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

// ── Additional income section — with investment calculators ────────
//
// KEY INSIGHT: investments generate INCOME, not a monthly cashflow
// equal to the principal. A CDT of $5M at 12% EA generates ~$47K/month,
// not $5M/month. This section separates capital from yield.

class _AdditionalIncomeSection extends StatefulWidget {
  final String currency;
  final ValueChanged<double> onTotalChanged;

  const _AdditionalIncomeSection({
    required this.currency,
    required this.onTotalChanged,
  });

  @override
  State<_AdditionalIncomeSection> createState() =>
      _AdditionalIncomeSectionState();
}

class _AdditionalIncomeSectionState extends State<_AdditionalIncomeSection> {
  bool _expanded = false;

  // CDT / Depósito a plazo
  bool _hasCdt = false;
  final _cdtCapCtrl = TextEditingController();
  final _cdtRateCtrl = TextEditingController();

  // Fondos / ETFs / Acciones
  bool _hasFunds = false;
  final _fundsCapCtrl = TextEditingController();
  final _fundsRateCtrl = TextEditingController();

  // Arriendos (direct monthly net income)
  bool _hasRental = false;
  final _rentalCtrl = TextEditingController();

  // Distribuciones de negocio (direct monthly average)
  bool _hasBusiness = false;
  final _businessCtrl = TextEditingController();

  // Otros
  bool _hasOther = false;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _cdtCapCtrl.dispose();
    _cdtRateCtrl.dispose();
    _fundsCapCtrl.dispose();
    _fundsRateCtrl.dispose();
    _rentalCtrl.dispose();
    _businessCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  double _parse(String v) =>
      double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  /// Rendimiento mensual de un instrumento dado capital y tasa EA.
  /// Usa la fórmula de tasa efectiva mensual: (1+EA)^(1/12) - 1
  double _monthlyYield(double capital, double annualRatePct) {
    if (capital <= 0 || annualRatePct <= 0) return 0;
    final ea = annualRatePct / 100;
    final em = pow(1 + ea, 1 / 12) - 1; // tasa efectiva mensual
    return capital * em;
  }

  double get _cdtMonthly =>
      _hasCdt ? _monthlyYield(_parse(_cdtCapCtrl.text), _parse(_cdtRateCtrl.text)) : 0;

  double get _fundsMonthly =>
      _hasFunds ? _monthlyYield(_parse(_fundsCapCtrl.text), _parse(_fundsRateCtrl.text)) : 0;

  double get _totalMonthly =>
      _cdtMonthly +
      _fundsMonthly +
      (_hasRental ? _parse(_rentalCtrl.text) : 0) +
      (_hasBusiness ? _parse(_businessCtrl.text) : 0) +
      (_hasOther ? _parse(_otherCtrl.text) : 0);

  void _notify() {
    widget.onTotalChanged(_totalMonthly);
    setState(() {});
  }

  String _fmt(double v) {
    if (widget.currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  String get _prefix => widget.currency == 'COP' ? '\$ ' : 'USD ';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalMonthly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _expanded ? AppColors.primarySurface : theme.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              border: Border.all(
                color: _expanded ? AppColors.primary : theme.dividerColor,
                width: _expanded ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 18)),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('¿Tienes ingresos pasivos o inversiones?',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        total > 0
                            ? '${_fmt(total)}/mes'
                            : 'CDTs, fondos, arriendos, negocios...',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: total > 0
                              ? AppColors.primary
                              : AppColors.textSecondaryDark,
                          fontWeight:
                              total > 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const Gap(10),
          // CDT
          _InvestmentTile(
            emoji: '🏦',
            title: 'CDT / Depósito a plazo',
            subtitle: 'Calculamos el rendimiento mensual desde tu capital y tasa',
            active: _hasCdt,
            onToggle: (v) => setState(() { _hasCdt = v; _notify(); }),
            child: _hasCdt
                ? _YieldCalculator(
                    prefix: _prefix,
                    capitalCtrl: _cdtCapCtrl,
                    rateCtrl: _cdtRateCtrl,
                    monthly: _cdtMonthly,
                    ratePlaceholder: 'Ej: 12',
                    rateLabel: 'Tasa EA (%)',
                    note: 'Rendimiento mensual = Capital × ((1 + Tasa EA)^(1/12) − 1). '
                        'Si tu CDT paga al vencimiento, este es el equivalente mensual acumulado.',
                    fmt: _fmt,
                    onChanged: _notify,
                  )
                : null,
          ),
          const Gap(8),
          // Fondos / ETFs
          _InvestmentTile(
            emoji: '📊',
            title: 'Fondos / ETFs / Acciones',
            subtitle: 'Calcula el rendimiento mensual de tu capital invertido',
            active: _hasFunds,
            onToggle: (v) => setState(() { _hasFunds = v; _notify(); }),
            child: _hasFunds
                ? _YieldCalculator(
                    prefix: _prefix,
                    capitalCtrl: _fundsCapCtrl,
                    rateCtrl: _fundsRateCtrl,
                    monthly: _fundsMonthly,
                    ratePlaceholder: 'Ej: 10',
                    rateLabel: 'Rentabilidad anual esperada (%)',
                    note: 'Usa la rentabilidad histórica del fondo o tu estimación. '
                        'Las acciones y ETFs tienen retornos variables.',
                    fmt: _fmt,
                    onChanged: _notify,
                  )
                : null,
          ),
          const Gap(8),
          // Arriendos
          _InvestmentTile(
            emoji: '🏘️',
            title: 'Arriendos',
            subtitle: 'Ingreso mensual neto después de gastos de la propiedad',
            active: _hasRental,
            onToggle: (v) => setState(() { _hasRental = v; _notify(); }),
            child: _hasRental
                ? _DirectIncomeField(
                    prefix: _prefix,
                    controller: _rentalCtrl,
                    hint: '0',
                    onChanged: (_) => _notify(),
                  )
                : null,
          ),
          const Gap(8),
          // Distribuciones
          _InvestmentTile(
            emoji: '💼',
            title: 'Distribuciones de negocio',
            subtitle: 'Utilidades o dividendos que recibes de una empresa',
            active: _hasBusiness,
            onToggle: (v) => setState(() { _hasBusiness = v; _notify(); }),
            child: _hasBusiness
                ? _DirectIncomeField(
                    prefix: _prefix,
                    controller: _businessCtrl,
                    hint: '0',
                    onChanged: (_) => _notify(),
                  )
                : null,
          ),
          const Gap(8),
          // Otros
          _InvestmentTile(
            emoji: '💰',
            title: 'Otros ingresos pasivos',
            subtitle: 'Regalías, pensión, cripto, ayudas...',
            active: _hasOther,
            onToggle: (v) => setState(() { _hasOther = v; _notify(); }),
            child: _hasOther
                ? _DirectIncomeField(
                    prefix: _prefix,
                    controller: _otherCtrl,
                    hint: '0',
                    onChanged: (_) => _notify(),
                  )
                : null,
          ),
          if (total > 0) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total ingresos pasivos/mes:',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Text(_fmt(total),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool active;
  final ValueChanged<bool> onToggle;
  final Widget? child;

  const _InvestmentTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onToggle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppConstants.animFast,
      decoration: BoxDecoration(
        color: active ? AppColors.primarySurface.withOpacity(0.5) : theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.primary.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondaryDark)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: active,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child!,
            ),
        ],
      ),
    );
  }
}

/// Calculator for yield-based instruments (CDTs, funds).
/// Converts: Capital + Annual Rate → Monthly income
class _YieldCalculator extends StatelessWidget {
  final String prefix;
  final TextEditingController capitalCtrl;
  final TextEditingController rateCtrl;
  final double monthly;
  final String ratePlaceholder;
  final String rateLabel;
  final String note;
  final String Function(double) fmt;
  final VoidCallback onChanged;

  const _YieldCalculator({
    required this.prefix,
    required this.capitalCtrl,
    required this.rateCtrl,
    required this.monthly,
    required this.ratePlaceholder,
    required this.rateLabel,
    required this.note,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capital invertido:',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(4),
                  TextField(
                    controller: capitalCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      prefixText: prefix,
                      hintText: '5,000,000',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rateLabel,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(4),
                  TextField(
                    controller: rateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      suffixText: '%',
                      hintText: ratePlaceholder,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (monthly > 0) ...[
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined,
                    size: 14, color: AppColors.primary),
                const Gap(6),
                Text('Rendimiento mensual: ',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondaryDark)),
                Text(fmt(monthly),
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
        const Gap(6),
        Text('⚠️ $note',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondaryDark)),
      ],
    );
  }
}

/// Simple direct monthly income field (for rentals, distributions, other).
class _DirectIncomeField extends StatelessWidget {
  final String prefix;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _DirectIncomeField({
    required this.prefix,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        prefixText: prefix,
        hintText: hint,
        labelText: 'Ingreso neto mensual',
        isDense: true,
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
    // Suscripciones físicas (plataformas digitales van en sección aparte)
    _ExpenseItem(id: 'gym', emoji: '💪', label: 'Gimnasio / fitness', group: 'Suscripciones'),
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

// ── Platform / subscription data ──────────────────────────────────

class _PlatformOption {
  final String id, emoji, name, category;
  const _PlatformOption({
    required this.id,
    required this.emoji,
    required this.name,
    required this.category,
  });
}

const _platformOptions = [
  // Streaming
  _PlatformOption(id: 'netflix',        emoji: '🎬', name: 'Netflix',          category: 'Streaming'),
  _PlatformOption(id: 'disney_plus',    emoji: '🏰', name: 'Disney+',          category: 'Streaming'),
  _PlatformOption(id: 'prime_video',    emoji: '📦', name: 'Prime Video',       category: 'Streaming'),
  _PlatformOption(id: 'max',            emoji: '🎭', name: 'Max',              category: 'Streaming'),
  _PlatformOption(id: 'paramount',      emoji: '⭐', name: 'Paramount+',       category: 'Streaming'),
  _PlatformOption(id: 'apple_tv',       emoji: '🍎', name: 'Apple TV+',        category: 'Streaming'),
  _PlatformOption(id: 'crunchyroll',    emoji: '🍜', name: 'Crunchyroll',      category: 'Streaming'),
  // Música
  _PlatformOption(id: 'spotify',        emoji: '🎵', name: 'Spotify',          category: 'Música'),
  _PlatformOption(id: 'apple_music',    emoji: '🎶', name: 'Apple Music',      category: 'Música'),
  _PlatformOption(id: 'youtube_prem',   emoji: '▶️', name: 'YouTube Premium',  category: 'Música'),
  _PlatformOption(id: 'deezer',         emoji: '🎧', name: 'Deezer',           category: 'Música'),
  // Gaming
  _PlatformOption(id: 'ps_plus',        emoji: '🎮', name: 'PlayStation Plus', category: 'Gaming'),
  _PlatformOption(id: 'xbox_gamepass',  emoji: '🕹️', name: 'Xbox Game Pass',  category: 'Gaming'),
  _PlatformOption(id: 'nintendo',       emoji: '🎯', name: 'Nintendo Online',  category: 'Gaming'),
  _PlatformOption(id: 'ea_play',        emoji: '⚽', name: 'EA Play',          category: 'Gaming'),
  // Productividad
  _PlatformOption(id: 'microsoft365',   emoji: '💼', name: 'Microsoft 365',    category: 'Productividad'),
  _PlatformOption(id: 'google_one',     emoji: '☁️', name: 'Google One',       category: 'Productividad'),
  _PlatformOption(id: 'icloud',         emoji: '🍎', name: 'iCloud+',          category: 'Productividad'),
  _PlatformOption(id: 'adobe_cc',       emoji: '🎨', name: 'Adobe CC',         category: 'Productividad'),
  _PlatformOption(id: 'canva_pro',      emoji: '🖼️', name: 'Canva Pro',        category: 'Productividad'),
  _PlatformOption(id: 'notion',         emoji: '📝', name: 'Notion',           category: 'Productividad'),
  _PlatformOption(id: 'dropbox',        emoji: '📁', name: 'Dropbox',          category: 'Productividad'),
  // Delivery
  _PlatformOption(id: 'rappi_prime',    emoji: '🛵', name: 'Rappi Prime',      category: 'Delivery'),
  _PlatformOption(id: 'amazon_prime',   emoji: '📦', name: 'Amazon Prime',     category: 'Delivery'),
  // Educación
  _PlatformOption(id: 'platzi',         emoji: '📚', name: 'Platzi',           category: 'Educación'),
  _PlatformOption(id: 'duolingo',       emoji: '🦉', name: 'Duolingo Plus',    category: 'Educación'),
  _PlatformOption(id: 'coursera',       emoji: '🎓', name: 'Coursera Plus',    category: 'Educación'),
  _PlatformOption(id: 'linkedin_prem',  emoji: '💼', name: 'LinkedIn Premium', category: 'Educación'),
  _PlatformOption(id: 'chatgpt',        emoji: '🤖', name: 'ChatGPT Plus',     category: 'Educación'),
  // Fitness digital
  _PlatformOption(id: 'wellhub',        emoji: '💪', name: 'Wellhub / Gympass',category: 'Fitness'),
  _PlatformOption(id: 'apple_fitness',  emoji: '🏃', name: 'Apple Fitness+',   category: 'Fitness'),
  // Otros
  _PlatformOption(id: 'vpn',            emoji: '🔒', name: 'VPN',              category: 'Otros'),
  _PlatformOption(id: 'antivirus',      emoji: '🛡️', name: 'Antivirus',        category: 'Otros'),
];

/// Categorías en el orden de presentación deseado.
const _platformCategories = [
  'Streaming', 'Música', 'Gaming', 'Productividad', 'Delivery',
  'Educación', 'Fitness', 'Otros',
];

/// Una plataforma que el usuario ya seleccionó con su monto.
class _PlatformEntry {
  final String id, name, emoji;
  final TextEditingController ctrl;
  bool isAnnual;

  _PlatformEntry({required this.id, required this.name, required this.emoji})
      : ctrl = TextEditingController(),
        isAnnual = false;

  double get rawAmount =>
      double.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

  /// Valor mensual equivalente.
  double get monthly => isAnnual ? rawAmount / 12 : rawAmount;

  void dispose() => ctrl.dispose();
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
  Map<String, double> _platformMap = {};

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
    map.addAll(_platformMap); // merge platform subscriptions
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
            itemCount: _ExpenseItem.groups.length + 1, // +1 for platforms section
            itemBuilder: (ctx, gi) {
              // Last item → platforms section
              if (gi == _ExpenseItem.groups.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: _PlatformsSection(
                    currency: widget.currency,
                    onChanged: (map) {
                      _platformMap = map;
                      _notify();
                    },
                  ),
                );
              }

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

// ── Platforms / subscriptions section ─────────────────────────────

class _PlatformsSection extends StatefulWidget {
  final String currency;
  final ValueChanged<Map<String, double>> onChanged;

  const _PlatformsSection({required this.currency, required this.onChanged});

  @override
  State<_PlatformsSection> createState() => _PlatformsSectionState();
}

class _PlatformsSectionState extends State<_PlatformsSection> {
  final List<_PlatformEntry> _selected = [];
  bool _showCustomForm = false;
  final _customNameCtrl = TextEditingController();
  String _customEmoji = '📱';

  @override
  void dispose() {
    for (final e in _selected) e.dispose();
    _customNameCtrl.dispose();
    super.dispose();
  }

  Set<String> get _selectedIds => _selected.map((e) => e.id).toSet();

  void _toggle(_PlatformOption opt) {
    setState(() {
      if (_selectedIds.contains(opt.id)) {
        final entry = _selected.firstWhere((e) => e.id == opt.id);
        entry.dispose();
        _selected.removeWhere((e) => e.id == opt.id);
      } else {
        _selected.add(_PlatformEntry(id: opt.id, name: opt.name, emoji: opt.emoji));
      }
    });
    _notify();
  }

  void _remove(_PlatformEntry entry) {
    entry.dispose();
    setState(() => _selected.remove(entry));
    _notify();
  }

  void _addCustom() {
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) return;
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _selected.add(_PlatformEntry(id: id, name: name, emoji: _customEmoji));
      _customNameCtrl.clear();
      _showCustomForm = false;
    });
    _notify();
  }

  void _notify() {
    final map = <String, double>{};
    for (final e in _selected) {
      if (e.monthly > 0) map['plat_${e.id}'] = e.monthly;
    }
    widget.onChanged(map);
  }

  String get _prefix => widget.currency == 'COP' ? '\$ ' : 'USD ';

  double get _sectionTotal =>
      _selected.fold(0, (acc, e) => acc + e.monthly);

  String _fmt(double v) {
    if (widget.currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  static const _customEmojis = ['📱', '💻', '📺', '🎮', '🎵', '📦', '🔧', '🌐'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Row(
          children: [
            const Text('📲', style: TextStyle(fontSize: 18)),
            const Gap(8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plataformas y suscripciones',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                  Text('Selecciona las que usas · toca para agregar',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            if (_sectionTotal > 0)
              Text(_fmt(_sectionTotal),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  )),
          ],
        ),
        const Gap(12),

        // ── Selected platforms ──
        if (_selected.isNotEmpty) ...[
          ...List.generate(_selected.length, (i) {
            final entry = _selected[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primarySurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    Text(entry.emoji, style: const TextStyle(fontSize: 16)),
                    const Gap(8),
                    Expanded(
                      child: Text(entry.name,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    // Mes / Año toggle
                    GestureDetector(
                      onTap: () {
                        setState(() => entry.isAnnual = !entry.isAnnual);
                        _notify();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: entry.isAnnual
                              ? AppColors.primary.withOpacity(0.15)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          entry.isAnnual ? 'Anual ÷12' : 'Mensual',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const Gap(6),
                    // Amount
                    SizedBox(
                      width: 90,
                      height: 34,
                      child: TextField(
                        controller: entry.ctrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          _notify();
                          setState(() {});
                        },
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          prefixText: _prefix,
                          hintText: entry.isAnnual ? 'Valor año' : '0',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                        ),
                      ),
                    ),
                    const Gap(2),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 28, minHeight: 28),
                      onPressed: () => _remove(entry),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Gap(4),
        ],

        // ── Chip grid by category ──
        ..._platformCategories.map((cat) {
          final opts =
              _platformOptions.where((p) => p.category == cat).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 8),
                child: Text(cat,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    )),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: opts.map((opt) {
                  final sel = _selectedIds.contains(opt.id);
                  return GestureDetector(
                    onTap: () => _toggle(opt),
                    child: AnimatedContainer(
                      duration: AppConstants.animFast,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(opt.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const Gap(4),
                          Text(opt.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : theme.textTheme.bodySmall?.color,
                              )),
                          if (sel) ...[
                            const Gap(4),
                            const Icon(Icons.check_rounded,
                                size: 12, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        }),

        const Gap(12),

        // ── Add custom ──
        if (!_showCustomForm)
          GestureDetector(
            onTap: () => setState(() => _showCustomForm = true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 16, color: AppColors.primary),
                const Gap(6),
                Text('Agregar otra plataforma',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emoji:',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(6),
                Wrap(
                  spacing: 6,
                  children: _customEmojis.map((e) {
                    final sel = _customEmoji == e;
                    return GestureDetector(
                      onTap: () => setState(() => _customEmoji = e),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primarySurface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : theme.dividerColor,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(e,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    );
                  }).toList(),
                ),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customNameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Nombre de la plataforma',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (_) => _addCustom(),
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton(
                      onPressed: _addCustom,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12)),
                      child: const Text('Agregar'),
                    ),
                    const Gap(4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () =>
                          setState(() => _showCustomForm = false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const Gap(8),
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

// ── Financial diagnosis engine ─────────────────────────────────────

enum _FinancialDiagnosis { critical, overextended, tight, balanced, thriving }

extension _DiagnosisX on _FinancialDiagnosis {
  String get emoji => switch (this) {
        _FinancialDiagnosis.critical => '😰',
        _FinancialDiagnosis.overextended => '⚠️',
        _FinancialDiagnosis.tight => '🔧',
        _FinancialDiagnosis.balanced => '✅',
        _FinancialDiagnosis.thriving => '🚀',
      };

  String get label => switch (this) {
        _FinancialDiagnosis.critical => 'Zona crítica',
        _FinancialDiagnosis.overextended => 'Sobre-extendido',
        _FinancialDiagnosis.tight => 'Ajustado',
        _FinancialDiagnosis.balanced => 'En equilibrio',
        _FinancialDiagnosis.thriving => 'Listo para crecer',
      };

  String get description => switch (this) {
        _FinancialDiagnosis.critical =>
          'Tus compromisos fijos consumen casi todo tu ingreso. El plan enfoca todo en recuperar margen y eliminar deudas.',
        _FinancialDiagnosis.overextended =>
          'Estás comprometiendo demasiado. El plan te da una ruta para recuperar control y respirar.',
        _FinancialDiagnosis.tight =>
          'Hay poco margen, pero es manejable. Cada peso cuenta — el plan te ayuda a optimizarlos.',
        _FinancialDiagnosis.balanced =>
          'Buena base financiera. El plan la consolida y empieza a trabajar para ti en automático.',
        _FinancialDiagnosis.thriving =>
          'Sólida posición. El plan maximiza tu crecimiento patrimonial y tu Rich Life.',
      };

  Color get color => switch (this) {
        _FinancialDiagnosis.critical => AppColors.error,
        _FinancialDiagnosis.overextended => const Color(0xFFFF8C00),
        _FinancialDiagnosis.tight => const Color(0xFFFFBF00),
        _FinancialDiagnosis.balanced => const Color(0xFF00B894),
        _FinancialDiagnosis.thriving => AppColors.primary,
      };
}

_FinancialDiagnosis _computeDiagnosis(double commitPct) {
  if (commitPct >= 85) return _FinancialDiagnosis.critical;
  if (commitPct >= 70) return _FinancialDiagnosis.overextended;
  if (commitPct >= 55) return _FinancialDiagnosis.tight;
  if (commitPct >= 35) return _FinancialDiagnosis.balanced;
  return _FinancialDiagnosis.thriving;
}

/// Returns recommended (fixedPct, savingsPct, investmentsPct, guiltFreePct).
(double, double, double, double) _recommendBuckets(
    double commitPct, List<String> richLife) {
  double fixed, savings, investments, guiltFree;

  if (commitPct >= 85) {
    fixed = commitPct.clamp(0, 90);
    savings = 5;
    investments = 0;
    guiltFree = (100 - fixed - savings).clamp(0, 15);
  } else if (commitPct >= 70) {
    fixed = commitPct;
    savings = 5;
    investments = 2;
    guiltFree = (100 - fixed - savings - investments).clamp(0, 20);
  } else if (commitPct >= 55) {
    fixed = commitPct;
    savings = 7.5;
    investments = 5;
    guiltFree = (100 - fixed - savings - investments).clamp(0, 30);
  } else if (commitPct >= 35) {
    fixed = 55;
    savings = 10;
    investments = 10;
    guiltFree = 25;
  } else {
    fixed = 40;
    savings = 15;
    investments = 20;
    guiltFree = 25;
  }

  // Rich Life modifiers (only when there's enough margin)
  final hasMargin = commitPct < 65;
  if (hasMargin) {
    if (richLife.any((c) => ['independencia', 'negocio'].contains(c))) {
      investments = (investments + 3).clamp(0, 25);
      guiltFree = (guiltFree - 3).clamp(5, 40);
    }
    if (richLife.any((c) => ['viajes', 'experiencias', 'lujo_cotidiano'].contains(c))) {
      guiltFree = (guiltFree + 3).clamp(5, 40);
      savings = (savings - 1.5).clamp(5, 20);
      investments = (investments - 1.5).clamp(0, 25);
    }
    if (richLife.contains('educacion')) {
      savings = (savings + 1).clamp(5, 20);
      guiltFree = (guiltFree - 1).clamp(5, 40);
    }
  }

  // Normalize to 100
  final total = fixed + savings + investments + guiltFree;
  if (total > 100) {
    final excess = total - 100;
    guiltFree = (guiltFree - excess).clamp(0, 40);
  }

  return (fixed, savings, investments, guiltFree);
}

// ── Diagnosis page ─────────────────────────────────────────────────

class _DiagnosisPage extends StatefulWidget {
  final double totalIncome;
  final double laborIncome;
  final double additionalIncome;
  final double totalExpenses;
  final double totalDebtPayments;
  final List<String> richLifeCategories;
  final String currency;
  final void Function(double, double, double, double) onBucketsConfirmed;
  final bool loading;
  final VoidCallback onFinish;

  const _DiagnosisPage({
    required this.totalIncome,
    required this.laborIncome,
    required this.additionalIncome,
    required this.totalExpenses,
    required this.totalDebtPayments,
    required this.richLifeCategories,
    required this.currency,
    required this.onBucketsConfirmed,
    required this.loading,
    required this.onFinish,
  });

  @override
  State<_DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<_DiagnosisPage> {
  late double _fixedPct;
  late double _savPct;
  late double _invPct;
  late double _freePct;
  bool _showAdjust = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(_DiagnosisPage old) {
    super.didUpdateWidget(old);
    _init();
  }

  void _init() {
    final commitPct = widget.totalIncome > 0
        ? ((widget.totalExpenses + widget.totalDebtPayments) /
                widget.totalIncome *
                100)
            .clamp(0.0, 100.0)
        : 55.0;
    final rec = _recommendBuckets(commitPct, widget.richLifeCategories);
    _fixedPct = rec.$1;
    _savPct = rec.$2;
    _invPct = rec.$3;
    _freePct = rec.$4;
  }

  String _fmt(double v) {
    if (widget.currency == 'COP') {
      final s = v.toStringAsFixed(0);
      return '\$ ${s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'USD ${v.toStringAsFixed(2)}';
  }

  String _pct(double v) => '${v.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = widget.totalIncome;
    final expenses = widget.totalExpenses;
    final debt = widget.totalDebtPayments;
    final committed = expenses + debt;
    final available = income - committed;
    final commitPct = income > 0 ? (committed / income * 100).clamp(0.0, 100.0) : 0.0;
    final diagnosis = _computeDiagnosis(commitPct);
    final total = _fixedPct + _savPct + _invPct + _freePct;

    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        const Gap(8),

        // ── Diagnosis card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: diagnosis.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: diagnosis.color.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(diagnosis.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu diagnóstico financiero',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: diagnosis.color,
                                fontWeight: FontWeight.w600)),
                        Text(diagnosis.label,
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: diagnosis.color,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(10),
              Text(diagnosis.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.85))),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05),

        const Gap(20),

        // ── Financial snapshot ──
        Text('📊 Tu panorama mensual',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              if (income > 0) ...[
                _SnapshotRow('Ingreso laboral neto', widget.laborIncome,
                    color: AppColors.primary, isIncome: true, fmt: _fmt),
                if (widget.additionalIncome > 0)
                  _SnapshotRow('+ Ingresos pasivos / adicionales',
                      widget.additionalIncome,
                      color: AppColors.primary, isIncome: true, fmt: _fmt),
                const Divider(height: 14),
                if (expenses > 0)
                  _SnapshotRow('- Gastos fijos', expenses,
                      color: AppColors.error, isIncome: false, fmt: _fmt),
                if (debt > 0)
                  _SnapshotRow('- Cuotas de deuda', debt,
                      color: AppColors.error, isIncome: false, fmt: _fmt),
                const Divider(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: Text('Disponible',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700))),
                    Text(
                      available >= 0
                          ? _fmt(available)
                          : '-${_fmt(available.abs())}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: available >= 0
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (available >= 0
                                ? AppColors.primary
                                : AppColors.error)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _pct(100.0 - commitPct),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: available >= 0
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Ingresa tus ingresos en el paso anterior para ver tu diagnóstico.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondaryDark),
                ),
            ],
          ),
        ).animate(delay: 100.ms).fadeIn(),

        const Gap(20),

        // ── Recommended buckets ──
        Row(
          children: [
            Expanded(
              child: Text('⚡ Tu plan configurado',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => setState(() => _showAdjust = !_showAdjust),
              child: Text(_showAdjust ? 'Ocultar' : 'Personalizar'),
            ),
          ],
        ),
        const Gap(8),
        _BucketBar(
            label: '🏠 Gastos Fijos',
            pct: _fixedPct,
            color: AppColors.bucketFixed,
            fmt: _pct),
        const Gap(6),
        _BucketBar(
            label: '🏦 Ahorro',
            pct: _savPct,
            color: AppColors.bucketSavings,
            fmt: _pct),
        const Gap(6),
        _BucketBar(
            label: '📈 Inversiones',
            pct: _invPct,
            color: AppColors.bucketInvestments,
            fmt: _pct),
        const Gap(6),
        _BucketBar(
            label: '🎉 Gasto Libre',
            pct: _freePct,
            color: AppColors.bucketFree,
            fmt: _pct),
        const Gap(4),
        Text(
          'Total: ${total.toStringAsFixed(0)}% ${total > 100 ? '⚠️ Excede 100%' : ''}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: total > 100 ? AppColors.error : AppColors.textSecondaryDark,
          ),
        ),

        // ── Adjustable sliders ──
        if (_showAdjust) ...[
          const Gap(16),
          Text('Personalizar distribución:',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(8),
          _BucketSlider(
              label: '🏠 Gastos Fijos',
              value: _fixedPct,
              color: AppColors.bucketFixed,
              onChanged: (v) => setState(() => _fixedPct = v)),
          _BucketSlider(
              label: '🏦 Ahorro',
              value: _savPct,
              color: AppColors.bucketSavings,
              onChanged: (v) => setState(() => _savPct = v)),
          _BucketSlider(
              label: '📈 Inversiones',
              value: _invPct,
              color: AppColors.bucketInvestments,
              onChanged: (v) => setState(() => _invPct = v)),
          _BucketSlider(
              label: '🎉 Gasto Libre',
              value: _freePct,
              color: AppColors.bucketFree,
              onChanged: (v) => setState(() => _freePct = v)),
        ],

        const Gap(24),

        // ── Action plan ──
        _ActionPlanSection(
          income: income,
          savBudget: income * _savPct / 100,
          invBudget: income * _invPct / 100,
          debtPayments: widget.totalDebtPayments,
          diagnosis: diagnosis,
          fmt: _fmt,
        ).animate(delay: 300.ms).fadeIn(),

        const Gap(24),

        // ── CTA ──
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (total <= 100 && !widget.loading)
                ? () {
                    widget.onBucketsConfirmed(
                        _fixedPct, _savPct, _invPct, _freePct);
                    widget.onFinish();
                  }
                : null,
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : const Text('¡Activar mi sistema financiero! 🚀',
                    style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const Gap(24),
      ],
    );
  }
}

// ── Action plan section (inside diagnosis + dashboard) ─────────────

class _ActionData {
  final String emoji, title, description;
  const _ActionData({required this.emoji, required this.title, required this.description});
}

class _ActionPlanSection extends StatelessWidget {
  final double income, savBudget, invBudget, debtPayments;
  final _FinancialDiagnosis diagnosis;
  final String Function(double) fmt;

  const _ActionPlanSection({
    required this.income,
    required this.savBudget,
    required this.invBudget,
    required this.debtPayments,
    required this.diagnosis,
    required this.fmt,
  });

  List<_ActionData> get _actions {
    final list = <_ActionData>[];

    // 1. Savings automation
    if (savBudget > 0) {
      list.add(_ActionData(
        emoji: '🏦',
        title: 'Automatiza tu ahorro',
        description:
            'El día de tu pago, transfiere ${fmt(savBudget)} a una cuenta separada. '
            'Hazlo automático — no cuentes con la fuerza de voluntad.',
      ));
    }

    // 2. Investment automation
    if (invBudget > 0) {
      list.add(_ActionData(
        emoji: '📈',
        title: 'Activa tus inversiones',
        description:
            'Programa ${fmt(invBudget)}/mes en un fondo de inversión o CDT. '
            'Es tu árbol del dinero: cada peso aquí genera más pesos sin tu tiempo.',
      ));
    }

    // 3. Debt attack
    if (debtPayments > 0) {
      final extra = (income * 0.03).clamp(50000.0, 500000.0);
      list.add(_ActionData(
        emoji: '💳',
        title: 'Golpea tu deuda más cara',
        description:
            'Identifica la deuda de mayor tasa EA y paga ${fmt(extra)} extra este mes. '
            'Ese dinero puede eliminar meses o años de pagos futuros.',
      ));
    }

    // 4. Emergency fund (if no debt or already have 2 actions)
    if (list.length < 3 && savBudget > 0 && income > 0) {
      final target = income * 3;
      final months = savBudget > 0 ? (target / savBudget).ceil() : 0;
      list.add(_ActionData(
        emoji: '🛡️',
        title: 'Construye tu colchón de emergencia',
        description:
            'Meta: ${fmt(target)} (3 meses de ingresos). '
            'Ahorrando ${fmt(savBudget)}/mes lo alcanzas en ~$months meses. '
            'Ponlo en una cuenta diferente, no la toques.',
      ));
    }

    // 5. Thriving bonus action
    if (diagnosis == _FinancialDiagnosis.thriving && list.length < 3) {
      list.add(_ActionData(
        emoji: '🌳',
        title: 'Siembra en el Árbol del Dinero',
        description:
            'Tienes margen financiero. Invierte en un CDT, ETF o fondo de largo plazo. '
            'El ingreso pasivo es lo que te compra tiempo libre.',
      ));
    }

    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _actions;
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 18)),
            const Gap(8),
            Text('Tu plan de acción',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const Gap(4),
        Text(
          '${actions.length} pasos concretos para este mes',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: AppColors.textSecondaryDark),
        ),
        const Gap(12),
        ...actions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(e.value.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const Gap(6),
                              Text(e.value.title,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const Gap(4),
                          Text(e.value.description,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondaryDark,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isIncome;
  final String Function(double) fmt;

  const _SnapshotRow(this.label, this.amount,
      {required this.color, required this.isIncome, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondaryDark)),
          ),
          Text(
            fmt(amount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _BucketBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  final String Function(double) fmt;

  const _BucketBar(
      {required this.label,
      required this.pct,
      required this.color,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const Gap(8),
        SizedBox(
          width: 36,
          child: Text(fmt(pct),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700, color: color)),
        ),
      ],
    );
  }
}

// ── (Legacy bucket page kept below for reference but not used) ─────

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
