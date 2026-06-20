import 'package:equatable/equatable.dart';

/// Snapshot mensual de las finanzas del usuario.
/// Se genera automáticamente cada fin de mes vía Cloud Function.
class MonthlyReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String monthKey;            // e.g. "2026-06"
  final double totalIncome;
  final double fixedCostsActual;
  final double savingsActual;
  final double investmentsActual;
  final double guiltFreeActual;
  final double fixedCostsBudget;
  final double savingsBudget;
  final double investmentsBudget;
  final double guiltFreeBudget;
  final int habitStreakAtClose;
  final double fastLaneScoreAtClose;
  final List<String> wins;          // logros del mes
  final List<String> improvements;  // áreas a mejorar
  final String? userNote;           // nota libre del usuario
  final bool isCompleted;           // ¿el usuario ya hizo la revisión?
  final DateTime createdAt;

  const MonthlyReviewEntity({
    required this.id,
    required this.userId,
    required this.monthKey,
    required this.totalIncome,
    this.fixedCostsActual = 0,
    this.savingsActual = 0,
    this.investmentsActual = 0,
    this.guiltFreeActual = 0,
    required this.fixedCostsBudget,
    required this.savingsBudget,
    required this.investmentsBudget,
    required this.guiltFreeBudget,
    this.habitStreakAtClose = 0,
    this.fastLaneScoreAtClose = 0,
    this.wins = const [],
    this.improvements = const [],
    this.userNote,
    this.isCompleted = false,
    required this.createdAt,
  });

  // ── Métricas calculadas ───────────────────────────────────────

  double get savingsRate =>
      totalIncome > 0 ? (savingsActual / totalIncome) * 100 : 0;

  double get investmentRate =>
      totalIncome > 0 ? (investmentsActual / totalIncome) * 100 : 0;

  double get totalSaved => savingsActual + investmentsActual;

  bool get hitSavingsGoal => savingsActual >= savingsBudget;
  bool get hitInvestmentsGoal => investmentsActual >= investmentsBudget;
  bool get stayedInFixedBudget => fixedCostsActual <= fixedCostsBudget;

  /// Puntuación de salud del mes (0–100)
  double get healthScore {
    double score = 0;
    if (hitSavingsGoal) score += 30;
    if (hitInvestmentsGoal) score += 30;
    if (stayedInFixedBudget) score += 25;
    if (habitStreakAtClose > 0) score += 15;
    return score.clamp(0, 100);
  }

  String get healthLabel {
    if (healthScore >= 80) return 'Excelente 🚀';
    if (healthScore >= 60) return 'Bien 🎯';
    if (healthScore >= 40) return 'Regular 📈';
    return 'Mejorable 💪';
  }

  MonthlyReviewEntity copyWith({
    List<String>? wins,
    List<String>? improvements,
    String? userNote,
    bool? isCompleted,
  }) {
    return MonthlyReviewEntity(
      id: id,
      userId: userId,
      monthKey: monthKey,
      totalIncome: totalIncome,
      fixedCostsActual: fixedCostsActual,
      savingsActual: savingsActual,
      investmentsActual: investmentsActual,
      guiltFreeActual: guiltFreeActual,
      fixedCostsBudget: fixedCostsBudget,
      savingsBudget: savingsBudget,
      investmentsBudget: investmentsBudget,
      guiltFreeBudget: guiltFreeBudget,
      habitStreakAtClose: habitStreakAtClose,
      fastLaneScoreAtClose: fastLaneScoreAtClose,
      wins: wins ?? this.wins,
      improvements: improvements ?? this.improvements,
      userNote: userNote ?? this.userNote,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, monthKey, healthScore, isCompleted];
}
