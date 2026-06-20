import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/lesson_entity.dart';

class LessonModel extends LessonEntity {
  const LessonModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.content,
    required super.source,
    required super.category,
    super.readingSeconds,
    required super.order,
    super.isPremium,
    super.tags,
    super.keyTakeaway,
  });

  factory LessonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return LessonModel(
      id: doc.id,
      title: d['title'] as String,
      slug: d['slug'] as String,
      content: d['content'] as String,
      source: LessonSource.values.byName(d['source'] as String? ?? 'elenacash'),
      category: LessonCategory.values.byName(d['category'] as String? ?? 'mindset'),
      readingSeconds: d['readingSeconds'] as int? ?? 90,
      order: d['order'] as int? ?? 0,
      isPremium: d['isPremium'] as bool? ?? false,
      tags: List<String>.from(d['tags'] as List<dynamic>? ?? []),
      keyTakeaway: d['keyTakeaway'] as String?,
    );
  }
}

class EducationProgressModel extends EducationProgressEntity {
  const EducationProgressModel({
    required super.userId,
    super.currentWeek,
    super.completedLessons,
    super.totalXP,
    super.currentMindset,
    super.dailyStreakDays,
    super.lastLessonAt,
  });

  factory EducationProgressModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final d = doc.data()!;
    return EducationProgressModel(
      userId: userId,
      currentWeek: d['currentWeek'] as int? ?? 1,
      completedLessons: List<String>.from(d['completedLessons'] as List<dynamic>? ?? []),
      totalXP: d['totalXP'] as int? ?? 0,
      currentMindset: d['currentMindset'] as String? ?? 'arcen',
      dailyStreakDays: d['dailyStreakDays'] as int? ?? 0,
      lastLessonAt: d['lastLessonAt'] != null
          ? (d['lastLessonAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentWeek': currentWeek,
      'completedLessons': completedLessons,
      'totalXP': totalXP,
      'currentMindset': currentMindset,
      'dailyStreakDays': dailyStreakDays,
      'lastLessonAt': lastLessonAt != null
          ? Timestamp.fromDate(lastLessonAt!)
          : null,
    };
  }
}
