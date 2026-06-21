import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/quiz_entity.dart';

/// Modelo Firestore para QuizEntity.
///
/// Schema esperado en `education_quizzes/{quizId}`:
/// ```
/// title: string
/// description: string
/// emoji: string
/// topic: string          // nombre del enum QuizTopic
/// xpReward: int
/// isPremium: bool
/// order: int             // para ordenar en la lista
/// questions: [
///   { id, question, options: [x4], correctIndex, explanation }
/// ]
/// ```
class QuizModel extends QuizEntity {
  const QuizModel({
    required super.id,
    required super.title,
    required super.description,
    required super.emoji,
    required super.questions,
    required super.topic,
    super.isPremium,
    super.xpReward,
  });

  factory QuizModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;

    final rawQuestions =
        List<Map<String, dynamic>>.from(d['questions'] as List<dynamic>? ?? []);

    final questions = rawQuestions.map((q) {
      return QuizQuestion(
        id: q['id'] as String? ?? '',
        question: q['question'] as String,
        options: List<String>.from(q['options'] as List<dynamic>),
        correctIndex: (q['correctIndex'] as num).toInt(),
        explanation: q['explanation'] as String? ?? '',
      );
    }).toList();

    return QuizModel(
      id: doc.id,
      title: d['title'] as String,
      description: d['description'] as String? ?? '',
      emoji: d['emoji'] as String? ?? '❓',
      topic: QuizTopic.values.byName(d['topic'] as String? ?? 'presupuesto'),
      xpReward: (d['xpReward'] as num?)?.toInt() ?? 25,
      isPremium: d['isPremium'] as bool? ?? false,
      questions: questions,
    );
  }
}
