import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/debt_model.dart';
import '../../domain/entities/debt_entity.dart';

part 'debts_provider.g.dart';

@riverpod
Stream<List<DebtEntity>> debtsWatch(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colDebts)
      .where('isActive', isEqualTo: true)
      .orderBy('interestRate', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => DebtModel.fromFirestore(doc, userId))
          .toList());
}

@riverpod
double totalDebtBalance(Ref ref) {
  final debtList = ref.watch(debtsWatchProvider).asData?.value ?? [];
  return debtList.fold(0.0, (sum, d) => sum + d.currentBalance);
}

@riverpod
double totalMonthlyInterest(Ref ref) {
  final debtList = ref.watch(debtsWatchProvider).asData?.value ?? [];
  return debtList.fold(0.0, (sum, d) => sum + d.monthlyInterestAmount);
}

@riverpod
class DebtsNotifier extends _$DebtsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> addDebt({
    required String userId,
    required String name,
    required DebtType type,
    required double totalAmount,
    required double currentBalance,
    required double interestRate,
    required double minimumPayment,
    required int paymentDay,
    DebtStrategy strategy = DebtStrategy.avalanche,
  }) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      final model = DebtModel(
        id: id,
        userId: userId,
        name: name,
        type: type,
        totalAmount: totalAmount,
        currentBalance: currentBalance,
        interestRate: interestRate,
        minimumPayment: minimumPayment,
        paymentDay: paymentDay,
        strategy: strategy,
        createdAt: DateTime.now(),
      );
      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colDebts)
          .doc(id)
          .set(model.toInitialFirestore());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateBalance({
    required String userId,
    required String debtId,
    required double newBalance,
  }) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colDebts)
        .doc(debtId)
        .update({
      'currentBalance': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDebt({required String userId, required String debtId}) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colDebts)
        .doc(debtId)
        .update({'isActive': false, 'updatedAt': FieldValue.serverTimestamp()});
  }
}
