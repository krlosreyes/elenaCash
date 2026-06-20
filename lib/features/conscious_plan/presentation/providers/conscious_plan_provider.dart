import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/conscious_plan_model.dart';
import '../../domain/entities/conscious_plan_entity.dart';

part 'conscious_plan_provider.g.dart';

// ── Stream del Plan Consciente ────────────────────────────────────

@riverpod
Stream<ConsciousPlanEntity?> consciousPlanWatch(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colConsciousPlan)
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return ConsciousPlanModel.fromFirestore(doc, userId);
  });
}

// ── Notifier para operaciones de escritura ────────────────────────

@riverpod
class ConsciousPlanNotifier extends _$ConsciousPlanNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createOrUpdatePlan({
    required String userId,
    required double monthlyNetIncome,
    double fixedCostsPct = AppConstants.defaultFixedCostsPct,
    double savingsPct = AppConstants.defaultSavingsPct,
    double investmentsPct = AppConstants.defaultInvestmentsPct,
    double guiltFreePct = AppConstants.defaultGuiltFreePct,
  }) async {
    state = const AsyncLoading();
    try {
      final plan = ConsciousPlanEntity.fromPercentages(
        userId: userId,
        monthlyNetIncome: monthlyNetIncome,
        fixedCostsPct: fixedCostsPct,
        savingsPct: savingsPct,
        investmentsPct: investmentsPct,
        guiltFreePct: guiltFreePct,
      );

      final model = ConsciousPlanModel(
        userId: plan.userId,
        monthlyNetIncome: plan.monthlyNetIncome,
        fixedCostsPct: plan.fixedCostsPct,
        savingsPct: plan.savingsPct,
        investmentsPct: plan.investmentsPct,
        guiltFreePct: plan.guiltFreePct,
        fixedCostsBudget: plan.fixedCostsBudget,
        savingsBudget: plan.savingsBudget,
        investmentsBudget: plan.investmentsBudget,
        guiltFreeBudget: plan.guiltFreeBudget,
        automationsConfigured: false,
        lastUpdated: DateTime.now(),
      );

      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colConsciousPlan)
          .doc('current')
          .set(model.toFirestore(), SetOptions(merge: true));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Actualiza montos reales de un cubo específico
  Future<void> updateBucketActual({
    required String userId,
    required String bucket, // 'fixedCosts' | 'savings' | 'investments' | 'guiltFree'
    required double amount,
  }) async {
    try {
      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colConsciousPlan)
          .doc('current')
          .update({
        '${bucket}Actual': amount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore: silently fail and retry
    }
  }

  Future<void> markAutomationsConfigured(String userId) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colConsciousPlan)
        .doc('current')
        .update({
      'automationsConfigured': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
