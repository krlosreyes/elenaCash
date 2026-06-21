import 'package:equatable/equatable.dart';

/// Una pregunta individual de un quiz
class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;   // 4 opciones siempre
  final int correctIndex;       // índice de la respuesta correcta
  final String explanation;     // por qué es correcta — el aprendizaje real

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctIndex;

  @override
  List<Object?> get props => [id];
}

/// Un quiz completo con múltiples preguntas
class QuizEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<QuizQuestion> questions;
  final QuizTopic topic;
  final bool isPremium;
  final int xpReward;           // XP al completar

  const QuizEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.questions,
    required this.topic,
    this.isPremium = false,
    this.xpReward = 25,
  });

  int get questionCount => questions.length;

  @override
  List<Object?> get props => [id];
}

enum QuizTopic { presupuesto, inversiones, deudas, habitos, mentalidad }

extension QuizTopicX on QuizTopic {
  String get label => switch (this) {
    QuizTopic.presupuesto => 'Presupuesto',
    QuizTopic.inversiones => 'Inversiones',
    QuizTopic.deudas => 'Deudas',
    QuizTopic.habitos => 'Hábitos',
    QuizTopic.mentalidad => 'Mentalidad',
  };
  String get emoji => switch (this) {
    QuizTopic.presupuesto => '💰',
    QuizTopic.inversiones => '📈',
    QuizTopic.deudas => '💳',
    QuizTopic.habitos => '🧠',
    QuizTopic.mentalidad => '🚀',
  };
  String get color => switch (this) {
    QuizTopic.presupuesto => '#1DB954',
    QuizTopic.inversiones => '#4CAF50',
    QuizTopic.deudas => '#D85A30',
    QuizTopic.habitos => '#9C27B0',
    QuizTopic.mentalidad => '#FF9800',
  };
}

/// Resultado de un intento de quiz guardado en Firestore
class QuizAttemptEntity extends Equatable {
  final String quizId;
  final int score;          // respuestas correctas
  final int totalQuestions;
  final DateTime completedAt;
  final int xpEarned;

  const QuizAttemptEntity({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.xpEarned,
  });

  double get percentage => totalQuestions > 0 ? score / totalQuestions : 0;
  bool get passed => percentage >= 0.6;   // 60% para aprobar

  String get grade {
    if (percentage >= 0.9) return '🏆 Experto';
    if (percentage >= 0.7) return '⭐ Bueno';
    if (percentage >= 0.6) return '✅ Aprobado';
    return '📚 Sigue estudiando';
  }

  @override
  List<Object?> get props => [quizId, completedAt];
}
