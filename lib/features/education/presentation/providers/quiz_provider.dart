import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/quizzes_seed.dart';
import '../../domain/entities/quiz_entity.dart';

part 'quiz_provider.g.dart';

// ── Lista de quizzes disponibles ──────────────────────────────────

@riverpod
Future<List<QuizEntity>> availableQuizzes(Ref ref) async {
  // Por ahora servimos el seed — en el futuro Firestore puede override
  return seedQuizzes;
}

// ── Intentos completados por el usuario ──────────────────────────

@riverpod
Stream<List<QuizAttemptEntity>> quizAttempts(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection('quizAttempts')
      .orderBy('completedAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            return QuizAttemptEntity(
              quizId: d['quizId'] as String,
              score: (d['score'] as num).toInt(),
              totalQuestions: (d['totalQuestions'] as num).toInt(),
              xpEarned: (d['xpEarned'] as num? ?? 0).toInt(),
              completedAt: (d['completedAt'] as Timestamp).toDate(),
            );
          }).toList());
}

// ── Notifier para guardar intentos ───────────────────────────────

@riverpod
class QuizNotifier extends _$QuizNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<QuizAttemptEntity?> submitQuiz({
    required String quizId,
    required int score,
    required int totalQuestions,
  }) async {
    state = const AsyncLoading();
    try {
      final userId = ref.read(currentUserIdProvider);
      final xp = _calcXP(score, totalQuestions);

      final attempt = QuizAttemptEntity(
        quizId: quizId,
        score: score,
        totalQuestions: totalQuestions,
        xpEarned: xp,
        completedAt: DateTime.now(),
      );

      final firestore = ref.read(firebaseFirestoreProvider);
      final batch = firestore.batch();

      // Guardar intento
      final attemptRef = firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection('quizAttempts')
          .doc();

      batch.set(attemptRef, {
        'quizId': quizId,
        'score': score,
        'totalQuestions': totalQuestions,
        'xpEarned': xp,
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Sumar XP al progreso educativo
      final progressRef = firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colEducationProgress)
          .doc('current');

      batch.set(progressRef, {
        'totalXP': FieldValue.increment(xp),
        'completedQuizzes': FieldValue.arrayUnion([quizId]),
      }, SetOptions(merge: true));

      await batch.commit();
      state = const AsyncData(null);
      return attempt;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  int _calcXP(int score, int total) {
    if (total == 0) return 0;
    final pct = score / total;
    if (pct >= 0.9) return 35;
    if (pct >= 0.7) return 25;
    if (pct >= 0.6) return 15;
    return 5;
  }
}
