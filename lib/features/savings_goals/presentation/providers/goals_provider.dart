import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../domain/entities/goal_entity.dart';

part 'goals_provider.g.dart';

@riverpod
Stream<List<GoalEntity>> savingsGoals(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colSavingsGoals)
      .where('isCompleted', isEqualTo: false)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => _fromDoc(doc, userId)).toList());
}

GoalEntity _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String userId) {
  final d = doc.data()!;
  return GoalEntity(
    id: doc.id,
    userId: userId,
    name: d['name'] as String? ?? '',
    emoji: d['emoji'] as String? ?? '⭐',
    category: GoalCategory.values.firstWhere(
      (e) => e.name == (d['category'] as String? ?? 'other'),
      orElse: () => GoalCategory.other,
    ),
    targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0,
    currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0,
    monthlyContribution: (d['monthlyContribution'] as num?)?.toDouble() ?? 0,
    targetDate: d['targetDate'] != null
        ? (d['targetDate'] as Timestamp).toDate()
        : null,
    isCompleted: d['isCompleted'] as bool? ?? false,
    createdAt: d['createdAt'] != null
        ? (d['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

@riverpod
class GoalsNotifier extends _$GoalsNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> addGoal({
    required String userId,
    required String name,
    required String emoji,
    required GoalCategory category,
    required double targetAmount,
    required double monthlyContribution,
    DateTime? targetDate,
  }) async {
    state = const AsyncLoading();
    try {
      final id = const Uuid().v4();
      await ref
          .read(firebaseFirestoreProvider)
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colSavingsGoals)
          .doc(id)
          .set({
        'name': name,
        'emoji': emoji,
        'category': category.name,
        'targetAmount': targetAmount,
        'currentAmount': 0,
        'monthlyContribution': monthlyContribution,
        'targetDate': targetDate != null ? Timestamp.fromDate(targetDate) : null,
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addContribution({
    required String userId,
    required String goalId,
    required double amount,
  }) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colSavingsGoals)
        .doc(goalId)
        .update({
      'currentAmount': FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCompleted({required String userId, required String goalId}) async {
    await ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colSavingsGoals)
        .doc(goalId)
        .update({
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
