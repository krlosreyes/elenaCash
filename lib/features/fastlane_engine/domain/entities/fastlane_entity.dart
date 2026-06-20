import 'package:equatable/equatable.dart';

/// FastLane Engine — basado en DeMarco "La Vía Rápida del Millonario"
/// Rastrea el progreso del usuario desde Vía Lenta hacia Vía Rápida.
class FastLaneEntity extends Equatable {
  final String userId;
  final int fastLaneScore;          // 0–100
  final FastLaneRoadmap roadmap;    // sinRumbo | viaLenta | viaRapida
  final double activeIncomeMonthly;
  final double passiveIncomeMonthly;
  final List<MoneyTreeBranch> moneyTreeBranches;
  final DateTime lastUpdated;

  const FastLaneEntity({
    required this.userId,
    this.fastLaneScore = 0,
    this.roadmap = FastLaneRoadmap.sinRumbo,
    this.activeIncomeMonthly = 0,
    this.passiveIncomeMonthly = 0,
    this.moneyTreeBranches = const [],
    required this.lastUpdated,
  });

  double get totalMonthlyIncome => activeIncomeMonthly + passiveIncomeMonthly;

  double get passiveRatioPct {
    if (totalMonthlyIncome == 0) return 0;
    return (passiveIncomeMonthly / totalMonthlyIncome) * 100;
  }

  String get roadmapLabel => switch (roadmap) {
    FastLaneRoadmap.sinRumbo => 'Sin Rumbo',
    FastLaneRoadmap.viaLenta => 'Vía Lenta',
    FastLaneRoadmap.viaRapida => 'Vía Rápida',
    FastLaneRoadmap.elite => 'Elite',
  };

  String get nextMilestone => switch (fastLaneScore) {
    < 25 => 'Configura tu sistema básico (Score 25)',
    < 50 => 'Planta tu primera rama de ingreso pasivo (Score 50)',
    < 75 => 'Alcanza 30% de ingreso pasivo (Score 75)',
    < 90 => 'Libertad financiera parcial (Score 90)',
    _ => '¡Eres un constructor de riqueza! (Score 100)',
  };

  @override
  List<Object?> get props => [userId, fastLaneScore, passiveIncomeMonthly];
}

enum FastLaneRoadmap { sinRumbo, viaLenta, viaRapida, elite }

/// Una rama del Árbol del Dinero — fuente de ingreso adicional.
class MoneyTreeBranch extends Equatable {
  final String id;
  final String label;
  final BranchType type;
  final double monthlyAmount;
  final DateTime createdAt;
  final bool isActive;

  const MoneyTreeBranch({
    required this.id,
    required this.label,
    required this.type,
    required this.monthlyAmount,
    required this.createdAt,
    this.isActive = true,
  });

  String get typeLabel => switch (type) {
    BranchType.freelance => 'Freelance',
    BranchType.investment => 'Inversión',
    BranchType.content => 'Contenido',
    BranchType.rental => 'Arriendo',
    BranchType.business => 'Negocio',
    BranchType.other => 'Otro',
  };

  String get typeName => switch (type) {
    BranchType.freelance => 'Freelance',
    BranchType.investment => 'Inversión',
    BranchType.content => 'Contenido',
    BranchType.rental => 'Renta',
    BranchType.business => 'Negocio',
    BranchType.other => 'Otro',
  };

  String get typeEmoji => switch (type) {
    BranchType.freelance => '💻',
    BranchType.investment => '📊',
    BranchType.content => '🎬',
    BranchType.rental => '🏠',
    BranchType.business => '🏢',
    BranchType.other => '🌿',
  };

  @override
  List<Object?> get props => [id, label, monthlyAmount, isActive];
}

enum BranchType { freelance, investment, content, rental, business, other }

extension BranchTypeX on BranchType {
  String get typeEmoji => switch (this) {
    BranchType.freelance => '💻',
    BranchType.investment => '📊',
    BranchType.content => '🎬',
    BranchType.rental => '🏠',
    BranchType.business => '🏢',
    BranchType.other => '🌿',
  };
  String get typeName => switch (this) {
    BranchType.freelance => 'Freelance',
    BranchType.investment => 'Inversión',
    BranchType.content => 'Contenido',
    BranchType.rental => 'Renta',
    BranchType.business => 'Negocio',
    BranchType.other => 'Otro',
  };
}

extension FastLaneRoadmapX on FastLaneRoadmap {
  String get label => switch (this) {
    FastLaneRoadmap.sinRumbo => 'Sin Rumbo',
    FastLaneRoadmap.viaLenta => 'Vía Lenta',
    FastLaneRoadmap.viaRapida => 'Vía Rápida',
    FastLaneRoadmap.elite => 'Élite',
  };
}
