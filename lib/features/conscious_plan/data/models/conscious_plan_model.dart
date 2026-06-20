import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/conscious_plan_entity.dart';

class ConsciousPlanModel extends ConsciousPlanEntity {
  const ConsciousPlanModel({
    required super.userId,
    required super.monthlyNetIncome,
    super.fixedCostsPct,
    super.savingsPct,
    super.investmentsPct,
    super.guiltFreePct,
    super.fixedCostsBudget,
    super.savingsBudget,
    super.investmentsBudget,
    super.guiltFreeBudget,
    super.fixedCostsActual,
    super.savingsActual,
    super.investmentsActual,
    super.guiltFreeActual,
    super.automationsConfigured,
    required super.lastUpdated,
  });

  factory ConsciousPlanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final data = doc.data()!;
    final income = (data['monthlyNetIncome'] as num?)?.toDouble() ?? 0.0;
    final fixedPct = (data['fixedCostsPct'] as num?)?.toDouble() ?? 55.0;
    final savPct = (data['savingsPct'] as num?)?.toDouble() ?? 7.5;
    final invPct = (data['investmentsPct'] as num?)?.toDouble() ?? 7.5;
    final freePct = (data['guiltFreePct'] as num?)?.toDouble() ?? 30.0;

    return ConsciousPlanModel(
      userId: userId,
      monthlyNetIncome: income,
      fixedCostsPct: fixedPct,
      savingsPct: savPct,
      investmentsPct: invPct,
      guiltFreePct: freePct,
      fixedCostsBudget: (data['fixedCostsBudget'] as num?)?.toDouble() ?? income * fixedPct / 100,
      savingsBudget: (data['savingsBudget'] as num?)?.toDouble() ?? income * savPct / 100,
      investmentsBudget: (data['investmentsBudget'] as num?)?.toDouble() ?? income * invPct / 100,
      guiltFreeBudget: (data['guiltFreeBudget'] as num?)?.toDouble() ?? income * freePct / 100,
      fixedCostsActual: (data['fixedCostsActual'] as num?)?.toDouble() ?? 0.0,
      savingsActual: (data['savingsActual'] as num?)?.toDouble() ?? 0.0,
      investmentsActual: (data['investmentsActual'] as num?)?.toDouble() ?? 0.0,
      guiltFreeActual: (data['guiltFreeActual'] as num?)?.toDouble() ?? 0.0,
      automationsConfigured: data['automationsConfigured'] as bool? ?? false,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthlyNetIncome': monthlyNetIncome,
      'fixedCostsPct': fixedCostsPct,
      'savingsPct': savingsPct,
      'investmentsPct': investmentsPct,
      'guiltFreePct': guiltFreePct,
      'fixedCostsBudget': fixedCostsBudget,
      'savingsBudget': savingsBudget,
      'investmentsBudget': investmentsBudget,
      'guiltFreeBudget': guiltFreeBudget,
      'fixedCostsActual': fixedCostsActual,
      'savingsActual': savingsActual,
      'investmentsActual': investmentsActual,
      'guiltFreeActual': guiltFreeActual,
      'automationsConfigured': automationsConfigured,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
