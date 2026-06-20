import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/monthly_review_model.dart';
import '../../domain/entities/monthly_review_entity.dart';

part 'monthly_review_provider.g.dart';

// ── Stream de la revisión del mes actual ──────────────────────────

@riverpod
Stream<MonthlyReviewEntity?> currentMonthReview(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  final monthKey = DateHelpers.currentMonthKey();
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colMonthlySnapshots)
      .doc(monthKey)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return MonthlyReviewModel.fromFirestore(doc, userId);
  });
}

// ── Stream del historial de revisiones ───────────────────────────

@riverpod
Stream<List<MonthlyReviewEntity>> monthlyReviewHistory(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colMonthlySnapshots)
      .orderBy('createdAt', descending: true)
      .limit(12)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => MonthlyReviewModel.fromFirestore(doc, userId))
          .toList());
}

// ── Notifier ──────────────────────────────────────────────────────

@riverpod
class MonthlyReviewNotifier extends _$MonthlyReviewNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Completa la revisión mensual con notas del usuario
  Future<void> completeReview({
    required String userId,
    required String monthKey,
    required List<String> wins,
    required List<String> improvements,
    String? userNote,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colMonthlySnapshots)
          .doc(monthKey)
          .set({
        'wins': wins,
        'improvements': improvements,
        'userNote': userNote,
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Crea manualmente un snapshot (si Cloud Function no lo hizo)
  Future<void> createSnapshotIfMissing({
    required String userId,
    required String monthKey,
    required double totalIncome,
    required double fixedCostsBudget,
    required double savingsBudget,
    required double investmentsBudget,
    required double guiltFreeBudget,
  }) async {
    final docRef = ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colMonthlySnapshots)
        .doc(monthKey);

    final snap = await docRef.get();
    if (snap.exists) return;

    await docRef.set({
      'monthKey': monthKey,
      'totalIncome': totalIncome,
      'fixedCostsBudget': fixedCostsBudget,
      'savingsBudget': savingsBudget,
      'investmentsBudget': investmentsBudget,
      'guiltFreeBudget': guiltFreeBudget,
      'isCompleted': false,
      'wins': [],
      'improvements': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
