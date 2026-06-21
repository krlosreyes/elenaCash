import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/lessons_seed.dart';
import '../../data/models/education_models.dart';
import '../../domain/entities/lesson_entity.dart';

part 'education_provider.g.dart';

// ── Progreso del usuario ──────────────────────────────────────────

@riverpod
Stream<EducationProgressEntity?> educationProgress(Ref ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection(AppConstants.colUsers)
      .doc(userId)
      .collection(AppConstants.colEducationProgress)
      .doc('current')
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return EducationProgressModel.fromFirestore(doc, userId);
  });
}

// ── Lecciones disponibles (seed + Firestore) ──────────────────────

@riverpod
Future<List<LessonEntity>> availableLessons(Ref ref) async {
  // Primero devolvemos las semilla (siempre disponibles offline)
  try {
    final snap = await ref
        .watch(firebaseFirestoreProvider)
        .collection('education')
        .orderBy('order')
        .limit(50)
        .get();

    if (snap.docs.isEmpty) return seedLessons;

    return snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList();
  } catch (_) {
    return seedLessons;
  }
}

// ── Lección actual de la semana ───────────────────────────────────

@riverpod
Future<LessonEntity?> weeklyLesson(Ref ref) async {
  final lessons = await ref.watch(availableLessonsProvider.future);
  final progress = ref.watch(educationProgressProvider).asData?.value;
  final week = progress?.currentWeek ?? 1;

  // Lesson = order == week (o la primera si no hay match)
  return lessons.where((l) => l.order == week).firstOrNull ??
      (lessons.isNotEmpty ? lessons.first : null);
}

// ── Notifier ──────────────────────────────────────────────────────

@riverpod
class EducationNotifier extends _$EducationNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  DocumentReference get _progressRef {
    final userId = ref.read(currentUserIdProvider);
    return ref
        .read(firebaseFirestoreProvider)
        .collection(AppConstants.colUsers)
        .doc(userId)
        .collection(AppConstants.colEducationProgress)
        .doc('current');
  }

  /// Marca una lección como completada y otorga XP
  Future<void> completeLesson(String lessonId) async {
    state = const AsyncLoading();
    try {
      final userId = ref.read(currentUserIdProvider);
      final firestore = ref.read(firebaseFirestoreProvider);

      final progressRef = firestore
          .collection(AppConstants.colUsers)
          .doc(userId)
          .collection(AppConstants.colEducationProgress)
          .doc('current');

      final snap = await progressRef.get();
      final data = snap.exists ? snap.data() : null;

      final existing = List<String>.from(data?['completedLessons'] ?? []);

      if (existing.contains(lessonId)) {
        state = const AsyncData(null);
        return;
      }

      final currentStreak = (data?['dailyStreakDays'] as int?) ?? 0;
      final lastLesson = data?['lastLessonAt'];

      // Racha: si la última lección fue ayer, incrementa; si fue hoy, mantiene; si fue antes, reinicia
      int newStreak = currentStreak;
      if (lastLesson != null) {
        final lastDate = (lastLesson as Timestamp).toDate();
        final diff = DateTime.now().difference(lastDate).inDays;
        if (diff == 0) newStreak = currentStreak; // mismo día
        else if (diff == 1) newStreak = currentStreak + 1;
        else newStreak = 1;
      } else {
        newStreak = 1;
      }

      final batch = firestore.batch();

      batch.set(progressRef, {
        'completedLessons': FieldValue.arrayUnion([lessonId]),
        'totalXP': FieldValue.increment(10),
        'dailyStreakDays': newStreak,
        'lastLessonAt': FieldValue.serverTimestamp(),
        'currentWeek': existing.length + 2,
      }, SetOptions(merge: true));

      // Mantener leaderboard sincronizado
      batch.set(
        firestore.collection('leaderboard').doc(userId),
        {'totalXP': FieldValue.increment(10), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      await batch.commit();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
