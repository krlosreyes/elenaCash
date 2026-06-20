import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/habit_engine_model.dart';
import '../../domain/entities/habit_engine_entity.dart';

part 'habit_engine_provider.g.dart';

// ── Stream del Habit Engine ───────────────────────────────────────

@riverpod
Stream<HabitEngineEntity?> habitEngineWatch(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colHabitEngine)
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return HabitEngineModel.fromFirestore(doc, userId);
  });
}

// ── Notifier ──────────────────────────────────────────────────────

@riverpod
class HabitEngineNotifier extends _$HabitEngineNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  DocumentReference get _docRef {
    final userId = ref.read(currentUserIdProvider);
    return ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colHabitEngine)
        .doc('current');
  }

  /// Marca el Ritual Quincenal como completado — actualiza racha
  Future<void> completeKeystoneHabit(String userId) async {
    state = const AsyncLoading();
    try {
      final snap = await _docRef.get();
      final current = snap.exists
          ? HabitEngineModel.fromFirestore(
              snap as DocumentSnapshot<Map<String, dynamic>>, userId)
          : null;

      final isAlreadyDone = current?.isCurrentPeriodComplete ?? false;
      if (isAlreadyDone) {
        state = const AsyncData(null);
        return;
      }

      final newStreak = (current?.habitStreak ?? 0) + 1;
      final longest = newStreak > (current?.longestStreak ?? 0)
          ? newStreak
          : (current?.longestStreak ?? 0);

      await _docRef.set({
        'keystoneHabitId': 'quincenal_review',
        'habitStreak': newStreak,
        'longestStreak': longest,
        'lastHabitCompletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Agrega un nuevo bucle de hábito personalizado
  Future<void> addHabitLoop({
    required String name,
    required String cue,
    required String badRoutine,
    required String newRoutine,
    required String reward,
  }) async {
    final loop = {
      'id': const Uuid().v4(),
      'name': name,
      'cue': cue,
      'badRoutine': badRoutine,
      'newRoutine': newRoutine,
      'reward': reward,
      'streakDays': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _docRef.set({
      'habitLoops': FieldValue.arrayUnion([loop]),
    }, SetOptions(merge: true));
  }

  /// Pausa un antojo por 24 horas (Modo Pausa)
  Future<void> pauseCraving({
    required String item,
    required double amount,
    required String currency,
  }) async {
    final craving = {
      'id': const Uuid().v4(),
      'item': item,
      'amount': amount,
      'pausedAt': FieldValue.serverTimestamp(),
      'decision': null,
      'currency': currency,
    };

    await _docRef.set({
      'pausedCravings': FieldValue.arrayUnion([craving]),
    }, SetOptions(merge: true));
  }

  /// Guarda el problema financiero principal del usuario
  Future<void> saveFinancialProblem(String problem) async {
    await _docRef.set({
      'financialProblem': problem,
    }, SetOptions(merge: true));
  }

  /// Registra la decisión sobre un antojo pausado
  Future<void> decideCraving({
    required String cravingId,
    required CravingDecision decision,
    required List<PausedCraving> allCravings,
  }) async {
    final updated = allCravings.map((c) {
      if (c.id == cravingId) {
        return {
          'id': c.id,
          'item': c.item,
          'amount': c.amount,
          'pausedAt': Timestamp.fromDate(c.pausedAt),
          'decision': decision.name,
          'currency': c.currency,
        };
      }
      return {
        'id': c.id,
        'item': c.item,
        'amount': c.amount,
        'pausedAt': Timestamp.fromDate(c.pausedAt),
        'decision': c.decision?.name,
        'currency': c.currency,
      };
    }).toList();

    await _docRef.update({'pausedCravings': updated});
  }
}
