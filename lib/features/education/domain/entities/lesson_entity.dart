import 'package:equatable/equatable.dart';

/// Lección del sistema educativo de ElenaCash.
/// Integra los tres libros fuente: Sethi / DeMarco / Duhigg.
class LessonEntity extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String content;         // Markdown
  final LessonSource source;    // De qué libro viene
  final LessonCategory category;
  final int readingSeconds;     // ~90 segundos por lección
  final int order;
  final bool isPremium;
  final List<String> tags;
  final String? keyTakeaway;    // La frase que se lleva el usuario

  const LessonEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.source,
    required this.category,
    this.readingSeconds = 90,
    required this.order,
    this.isPremium = false,
    this.tags = const [],
    this.keyTakeaway,
  });

  String get sourceLabel => switch (source) {
    LessonSource.sethi => 'I Will Teach You to Be Rich',
    LessonSource.demarco => 'La Vía Rápida del Millonario',
    LessonSource.duhigg => 'El Poder de los Hábitos',
    LessonSource.elenacash => 'ElenaCash',
  };

  String get sourceEmoji => switch (source) {
    LessonSource.sethi => '💰',
    LessonSource.demarco => '🚀',
    LessonSource.duhigg => '🧠',
    LessonSource.elenacash => '🌱',
  };

  String get categoryLabel => switch (category) {
    LessonCategory.mindset => 'Mentalidad',
    LessonCategory.system => 'El Sistema',
    LessonCategory.habits => 'Hábitos',
    LessonCategory.fastlane => 'Vía Rápida',
    LessonCategory.investing => 'Inversiones',
    LessonCategory.debt => 'Deudas',
    LessonCategory.richLife => 'Rich Life',
  };

  @override
  List<Object?> get props => [id, order];
}

enum LessonSource { sethi, demarco, duhigg, elenacash }
enum LessonCategory { mindset, system, habits, fastlane, investing, debt, richLife }

extension LessonSourceX on LessonSource {
  String get sourceLabel => switch (this) {
    LessonSource.sethi => 'Ramit Sethi',
    LessonSource.demarco => 'MJ DeMarco',
    LessonSource.duhigg => 'Charles Duhigg',
    LessonSource.elenacash => 'ElenaCash',
  };
  String get sourceEmoji => switch (this) {
    LessonSource.sethi => '💰',
    LessonSource.demarco => '🚀',
    LessonSource.duhigg => '🧠',
    LessonSource.elenacash => '🌱',
  };
}

/// Registro de progreso educativo del usuario
class EducationProgressEntity extends Equatable {
  final String userId;
  final int currentWeek;
  final List<String> completedLessons;
  final int totalXP;
  final String currentMindset;    // sin_rumbo | via_lenta | activo
  final int dailyStreakDays;
  final DateTime? lastLessonAt;

  const EducationProgressEntity({
    required this.userId,
    this.currentWeek = 1,
    this.completedLessons = const [],
    this.totalXP = 0,
    this.currentMindset = 'via_lenta',
    this.dailyStreakDays = 0,
    this.lastLessonAt,
  });

  bool get lessonCompletedToday {
    if (lastLessonAt == null) return false;
    final now = DateTime.now();
    return lastLessonAt!.year == now.year &&
        lastLessonAt!.month == now.month &&
        lastLessonAt!.day == now.day;
  }

  bool isLessonCompleted(String lessonId) => completedLessons.contains(lessonId);

  @override
  List<Object?> get props => [userId, totalXP, dailyStreakDays];
}
