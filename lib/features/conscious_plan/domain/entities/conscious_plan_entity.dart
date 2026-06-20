import 'package:equatable/equatable.dart';

/// El Plan de Gasto Consciente — el corazón financiero de ElenaCash.
/// Basado en Ramit Sethi: 4 cubos + automatización.
class ConsciousPlanEntity extends Equatable {
  final String userId;
  final double monthlyNetIncome;

  // Porcentajes (configurables por el usuario dentro de rangos)
  final double fixedCostsPct;    // 40–65%
  final double savingsPct;       // 5–20%
  final double investmentsPct;   // 5–20%
  final double guiltFreePct;     // 10–40%

  // Montos calculados
  final double fixedCostsBudget;
  final double savingsBudget;
  final double investmentsBudget;
  final double guiltFreeBudget;

  // Montos reales del mes actual (actualizados por el usuario)
  final double fixedCostsActual;
  final double savingsActual;
  final double investmentsActual;
  final double guiltFreeActual;

  final bool automationsConfigured;
  final DateTime lastUpdated;

  const ConsciousPlanEntity({
    required this.userId,
    required this.monthlyNetIncome,
    this.fixedCostsPct = 55.0,
    this.savingsPct = 7.5,
    this.investmentsPct = 7.5,
    this.guiltFreePct = 30.0,
    this.fixedCostsBudget = 0,
    this.savingsBudget = 0,
    this.investmentsBudget = 0,
    this.guiltFreeBudget = 0,
    this.fixedCostsActual = 0,
    this.savingsActual = 0,
    this.investmentsActual = 0,
    this.guiltFreeActual = 0,
    this.automationsConfigured = false,
    required this.lastUpdated,
  });

  // ── Computed Properties ───────────────────────────────────────

  double get totalBudget =>
      fixedCostsBudget + savingsBudget + investmentsBudget + guiltFreeBudget;

  double get totalActual =>
      fixedCostsActual + savingsActual + investmentsActual + guiltFreeActual;

  double get remainingBudget => totalBudget - totalActual;

  // Progreso de cada cubo (0.0 – 1.0, puede superar 1.0 si se excede)
  double get fixedCostsProgress =>
      fixedCostsBudget > 0 ? fixedCostsActual / fixedCostsBudget : 0;
  double get savingsProgress =>
      savingsBudget > 0 ? savingsActual / savingsBudget : 0;
  double get investmentsProgress =>
      investmentsBudget > 0 ? investmentsActual / investmentsBudget : 0;
  double get guiltFreeProgress =>
      guiltFreeBudget > 0 ? guiltFreeActual / guiltFreeBudget : 0;

  // Estado de cada cubo
  BucketStatus get fixedCostsStatus => _bucketStatus(fixedCostsProgress, isFixedCost: true);
  BucketStatus get savingsStatus => _bucketStatus(savingsProgress);
  BucketStatus get investmentsStatus => _bucketStatus(investmentsProgress);
  BucketStatus get guiltFreeStatus => _bucketStatus(guiltFreeProgress);

  BucketStatus _bucketStatus(double progress, {bool isFixedCost = false}) {
    if (isFixedCost) {
      // Para gastos fijos: exceder es malo
      if (progress > 1.05) return BucketStatus.over;
      if (progress > 0.9) return BucketStatus.warning;
      return BucketStatus.good;
    } else {
      // Para ahorro/inversión: exceder es bueno (más es mejor)
      if (progress >= 1.0) return BucketStatus.complete;
      if (progress >= 0.5) return BucketStatus.good;
      return BucketStatus.pending;
    }
  }

  // ── Factory desde porcentajes ─────────────────────────────────

  static ConsciousPlanEntity fromPercentages({
    required String userId,
    required double monthlyNetIncome,
    double fixedCostsPct = 55.0,
    double savingsPct = 7.5,
    double investmentsPct = 7.5,
    double guiltFreePct = 30.0,
    bool automationsConfigured = false,
  }) {
    return ConsciousPlanEntity(
      userId: userId,
      monthlyNetIncome: monthlyNetIncome,
      fixedCostsPct: fixedCostsPct,
      savingsPct: savingsPct,
      investmentsPct: investmentsPct,
      guiltFreePct: guiltFreePct,
      fixedCostsBudget: monthlyNetIncome * fixedCostsPct / 100,
      savingsBudget: monthlyNetIncome * savingsPct / 100,
      investmentsBudget: monthlyNetIncome * investmentsPct / 100,
      guiltFreeBudget: monthlyNetIncome * guiltFreePct / 100,
      automationsConfigured: automationsConfigured,
      lastUpdated: DateTime.now(),
    );
  }

  ConsciousPlanEntity copyWith({
    double? monthlyNetIncome,
    double? fixedCostsPct,
    double? savingsPct,
    double? investmentsPct,
    double? guiltFreePct,
    double? fixedCostsActual,
    double? savingsActual,
    double? investmentsActual,
    double? guiltFreeActual,
    bool? automationsConfigured,
    DateTime? lastUpdated,
  }) {
    final income = monthlyNetIncome ?? this.monthlyNetIncome;
    final fixedPct = fixedCostsPct ?? this.fixedCostsPct;
    final savPct = savingsPct ?? this.savingsPct;
    final invPct = investmentsPct ?? this.investmentsPct;
    final freePct = guiltFreePct ?? this.guiltFreePct;

    return ConsciousPlanEntity(
      userId: userId,
      monthlyNetIncome: income,
      fixedCostsPct: fixedPct,
      savingsPct: savPct,
      investmentsPct: invPct,
      guiltFreePct: freePct,
      fixedCostsBudget: income * fixedPct / 100,
      savingsBudget: income * savPct / 100,
      investmentsBudget: income * invPct / 100,
      guiltFreeBudget: income * freePct / 100,
      fixedCostsActual: fixedCostsActual ?? this.fixedCostsActual,
      savingsActual: savingsActual ?? this.savingsActual,
      investmentsActual: investmentsActual ?? this.investmentsActual,
      guiltFreeActual: guiltFreeActual ?? this.guiltFreeActual,
      automationsConfigured: automationsConfigured ?? this.automationsConfigured,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, monthlyNetIncome, fixedCostsPct, savingsPct,
      investmentsPct, guiltFreePct, fixedCostsActual, savingsActual,
      investmentsActual, guiltFreeActual, automationsConfigured];
}

enum BucketStatus { pending, good, warning, complete, over }

/// Metadatos de un cubo para la UI
class BucketInfo {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final double budget;
  final double actual;
  final double percentage;
  final BucketStatus status;

  const BucketInfo({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.budget,
    required this.actual,
    required this.percentage,
    required this.status,
  });

  double get progress => budget > 0 ? (actual / budget).clamp(0.0, 1.5) : 0;
}
