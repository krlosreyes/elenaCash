import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/monthly_review_entity.dart';

class MonthlyReviewModel extends MonthlyReviewEntity {
  const MonthlyReviewModel({
    required super.id,
    required super.userId,
    required super.monthKey,
    required super.totalIncome,
    super.fixedCostsActual,
    super.savingsActual,
    super.investmentsActual,
    super.guiltFreeActual,
    required super.fixedCostsBudget,
    required super.savingsBudget,
    required super.investmentsBudget,
    required super.guiltFreeBudget,
    super.habitStreakAtClose,
    super.fastLaneScoreAtClose,
    super.wins,
    super.improvements,
    super.userNote,
    super.isCompleted,
    required super.createdAt,
  });

  factory MonthlyReviewModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final d = doc.data()!;
    return MonthlyReviewModel(
      id: doc.id,
      userId: userId,
      monthKey: d['monthKey'] as String,
      totalIncome: (d['totalIncome'] as num?)?.toDouble() ?? 0,
      fixedCostsActual: (d['fixedCostsActual'] as num?)?.toDouble() ?? 0,
      savingsActual: (d['savingsActual'] as num?)?.toDouble() ?? 0,
      investmentsActual: (d['investmentsActual'] as num?)?.toDouble() ?? 0,
      guiltFreeActual: (d['guiltFreeActual'] as num?)?.toDouble() ?? 0,
      fixedCostsBudget: (d['fixedCostsBudget'] as num?)?.toDouble() ?? 0,
      savingsBudget: (d['savingsBudget'] as num?)?.toDouble() ?? 0,
      investmentsBudget: (d['investmentsBudget'] as num?)?.toDouble() ?? 0,
      guiltFreeBudget: (d['guiltFreeBudget'] as num?)?.toDouble() ?? 0,
      habitStreakAtClose: d['habitStreakAtClose'] as int? ?? 0,
      fastLaneScoreAtClose: (d['fastLaneScoreAtClose'] as num?)?.toDouble() ?? 0,
      wins: List<String>.from(d['wins'] as List<dynamic>? ?? []),
      improvements: List<String>.from(d['improvements'] as List<dynamic>? ?? []),
      userNote: d['userNote'] as String?,
      isCompleted: d['isCompleted'] as bool? ?? false,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthKey': monthKey,
      'totalIncome': totalIncome,
      'fixedCostsActual': fixedCostsActual,
      'savingsActual': savingsActual,
      'investmentsActual': investmentsActual,
      'guiltFreeActual': guiltFreeActual,
      'fixedCostsBudget': fixedCostsBudget,
      'savingsBudget': savingsBudget,
      'investmentsBudget': investmentsBudget,
      'guiltFreeBudget': guiltFreeBudget,
      'habitStreakAtClose': habitStreakAtClose,
      'fastLaneScoreAtClose': fastLaneScoreAtClose,
      'wins': wins,
      'improvements': improvements,
      'userNote': userNote,
      'isCompleted': isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
