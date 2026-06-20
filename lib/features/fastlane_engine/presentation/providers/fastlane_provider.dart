import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/fastlane_model.dart';
import '../../domain/entities/fastlane_entity.dart';

part 'fastlane_provider.g.dart';

// ── Stream del FastLane Engine ────────────────────────────────────

@riverpod
Stream<FastLaneEntity?> fastLaneEngine(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colFastlaneEngine)
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return FastLaneModel.fromFirestore(doc, userId);
  });
}

// ── Notifier para operaciones de escritura ────────────────────────

@riverpod
class FastLaneNotifier extends _$FastLaneNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Recalcula y actualiza el FastLane Score
  Future<void> updateScoreFromIncomes({
    required String userId,
    required double activeIncome,
    required double passiveIncome,
  }) async {
    state = const AsyncLoading();
    try {
      final total = activeIncome + passiveIncome;
      final passiveRatio = total > 0 ? (passiveIncome / total) * 100 : 0.0;

      // Score: 0–100 basado en ratio de ingreso pasivo + cantidad absoluta
      double score = passiveRatio * 0.7; // 70% del score = ratio
      if (passiveIncome >= 500000) score += 10;    // +10 si > 500k COP
      if (passiveIncome >= 2000000) score += 10;   // +20 si > 2M COP
      if (passiveIncome >= 5000000) score += 10;   // +30 si > 5M COP
      score = score.clamp(0, 100);

      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colFastlaneEngine)
          .doc('current')
          .set({
        'activeIncomeMonthly': activeIncome,
        'passiveIncomeMonthly': passiveIncome,
        'fastLaneScore': score,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Agrega una nueva rama al Árbol del Dinero
  Future<void> addMoneyTreeBranch({
    required String userId,
    required BranchType type,
    required String label,
    required double monthlyAmount,
  }) async {
    final branch = {
      'id': const Uuid().v4(),
      'type': type.name,
      'label': label,
      'monthlyAmount': monthlyAmount,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colFastlaneEngine)
        .doc('current')
        .update({
      'moneyTreeBranches': FieldValue.arrayUnion([branch]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina una rama del árbol
  Future<void> removeBranch({
    required String userId,
    required MoneyTreeBranch branch,
  }) async {
    // Reescribimos sin esa rama (arrayRemove requiere objeto idéntico)
    final docRef = ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colFastlaneEngine)
        .doc('current');

    await ref.read(firebaseFirestoreProvider).runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final branches = (snap.data()!['moneyTreeBranches'] as List<dynamic>? ?? [])
          .where((b) => b['id'] != branch.id)
          .toList();
      tx.update(docRef, {
        'moneyTreeBranches': branches,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }
}
