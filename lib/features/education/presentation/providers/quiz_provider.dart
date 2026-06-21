import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/models/quiz_models.dart';
import '../../data/quizzes_seed.dart';
import '../../domain/entities/quiz_entity.dart';

part 'quiz_provider.g.dart';

// ── Leaderboard anónimo de XP (top 10) ───────────────────────────

class LeaderboardEntry {
  final String userId;
  final int totalXP;
  const LeaderboardEntry({required this.userId, required this.totalXP});
}

@riverpod
Stream<List<LeaderboardEntry>> leaderboard(Ref ref) {
  return ref
      .watch(firebaseFirestoreProvider)
      .collection('leaderboard')
      .orderBy('totalXP', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            return LeaderboardEntry(
              userId: doc.id,
              totalXP: (doc.data()['totalXP'] as num? ?? 0).toInt(),
            );
          }).toList());
}

// ── Lista de quizzes disponibles ──────────────────────────────────
// Intenta cargar desde Firestore `education_quizzes/`; fallback al seed.
// Esto permite que un admin agregue quizzes sin nuevo release.

@riverpod
Future<List<QuizEntity>> availableQuizzes(Ref ref) async {
  try {
    final snap = await ref
        .watch(firebaseFirestoreProvider)
        .collection('education_quizzes')
        .orderBy('order')
        .get();

    if (snap.docs.isEmpty) return seedQuizzes;

    return snap.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();
  } catch (_) {
    // Sin conexión o colección no existente → seed local
    return seedQuizzes;
  }
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

      // ── Leer progreso actual para calcular racha ──────────────────
      final progressRef = firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colEducationProgress)
          .doc('current');

      final progressSnap = await progressRef.get();
      final progressData =
          progressSnap.exists ? progressSnap.data() as Map<String, dynamic>? : null;

      final currentStreak = (progressData?['dailyStreakDays'] as num?)?.toInt() ?? 0;
      final lastActivity = progressData?['lastLessonAt'];

      // Igual que completeLesson: ayer = +1, hoy = mantener, >1d = reiniciar
      int newStreak = currentStreak;
      if (lastActivity != null) {
        final lastDate = (lastActivity as Timestamp).toDate();
        final diffDays = DateTime.now().difference(lastDate).inDays;
        if (diffDays == 0) newStreak = currentStreak;
        else if (diffDays == 1) newStreak = currentStreak + 1;
        else newStreak = 1;
      } else {
        newStreak = 1;
      }

      // ── Batch: intento + progreso ─────────────────────────────────
      final batch = firestore.batch();

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

      batch.set(progressRef, {
        'totalXP': FieldValue.increment(xp),
        'completedQuizzes': FieldValue.arrayUnion([quizId]),
        'dailyStreakDays': newStreak,
        'lastLessonAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Mantener leaderboard sincronizado
      batch.set(
        firestore.collection('leaderboard').doc(userId),
        {'totalXP': FieldValue.increment(xp), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

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
