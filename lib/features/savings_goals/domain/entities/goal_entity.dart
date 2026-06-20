import 'package:equatable/equatable.dart';

class GoalEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final GoalCategory category;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime createdAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.category,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.monthlyContribution,
    this.targetDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get progressPct =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  int get monthsRemaining {
    if (monthlyContribution <= 0) return 9999;
    return (remaining / monthlyContribution).ceil();
  }

  DateTime get estimatedCompletionDate {
    final months = monthsRemaining;
    return DateTime.now().add(Duration(days: months * 30));
  }

  bool get isOnTrack {
    if (targetDate == null) return true;
    final totalMonths =
        targetDate!.difference(createdAt).inDays / 30;
    final elapsedMonths = DateTime.now().difference(createdAt).inDays / 30;
    final expectedProgress = elapsedMonths / totalMonths;
    return progressPct >= (expectedProgress - 0.1);
  }

  @override
  List<Object?> get props => [id, currentAmount, targetAmount, isCompleted];
}

enum GoalCategory {
  emergency,
  travel,
  housing,
  education,
  car,
  retirement,
  gifts,
  health,
  other
}

extension GoalCategoryExt on GoalCategory {
  String get label => switch (this) {
    GoalCategory.emergency => 'Fondo de emergencia',
    GoalCategory.travel => 'Viaje',
    GoalCategory.housing => 'Vivienda',
    GoalCategory.education => 'Educación',
    GoalCategory.car => 'Vehículo',
    GoalCategory.retirement => 'Retiro',
    GoalCategory.gifts => 'Regalos',
    GoalCategory.health => 'Salud',
    GoalCategory.other => 'Otro',
  };

  String get emoji => switch (this) {
    GoalCategory.emergency => '🛡️',
    GoalCategory.travel => '✈️',
    GoalCategory.housing => '🏠',
    GoalCategory.education => '🎓',
    GoalCategory.car => '🚗',
    GoalCategory.retirement => '🌴',
    GoalCategory.gifts => '🎁',
    GoalCategory.health => '💊',
    GoalCategory.other => '⭐',
  };
}
