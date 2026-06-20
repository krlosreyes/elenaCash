import 'package:equatable/equatable.dart';

/// Motor de hábitos — implementa el bucle Cue→Routine→Reward de Duhigg.
class HabitEngineEntity extends Equatable {
  final String userId;
  final String keystoneHabitId;
  final int habitStreak;           // Racha actual en quincenas
  final int longestStreak;
  final DateTime? lastHabitCompletedAt;
  final List<HabitLoop> habitLoops;
  final List<PausedCraving> pausedCravings;

  const HabitEngineEntity({
    required this.userId,
    this.keystoneHabitId = 'quincenal_review',
    this.habitStreak = 0,
    this.longestStreak = 0,
    this.lastHabitCompletedAt,
    this.habitLoops = const [],
    this.pausedCravings = const [],
  });

  /// ¿El hábito bisagra está completo para el período actual?
  bool get isCurrentPeriodComplete {
    if (lastHabitCompletedAt == null) return false;
    final now = DateTime.now();
    final last = lastHabitCompletedAt!;
    // Mismo mes y misma quincena (1–15 o 16–fin)
    final nowPeriod = now.day <= 15 ? 1 : 2;
    final lastPeriod = last.day <= 15 ? 1 : 2;
    return now.year == last.year &&
        now.month == last.month &&
        nowPeriod == lastPeriod;
  }

  /// Días desde el último hábito completado
  int get daysSinceLastHabit {
    if (lastHabitCompletedAt == null) return -1;
    return DateTime.now().difference(lastHabitCompletedAt!).inDays;
  }

  HabitEngineEntity copyWith({
    int? habitStreak,
    int? longestStreak,
    DateTime? lastHabitCompletedAt,
    List<HabitLoop>? habitLoops,
    List<PausedCraving>? pausedCravings,
  }) {
    return HabitEngineEntity(
      userId: userId,
      keystoneHabitId: keystoneHabitId,
      habitStreak: habitStreak ?? this.habitStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastHabitCompletedAt: lastHabitCompletedAt ?? this.lastHabitCompletedAt,
      habitLoops: habitLoops ?? this.habitLoops,
      pausedCravings: pausedCravings ?? this.pausedCravings,
    );
  }

  @override
  List<Object?> get props => [userId, habitStreak, lastHabitCompletedAt];
}

/// Un bucle de hábito personalizado (Duhigg: Cue → Routine → Reward)
class HabitLoop extends Equatable {
  final String id;
  final String name;
  final String cue;             // Señal que dispara el hábito
  final String badRoutine;      // Rutina actual negativa
  final String newRoutine;      // Rutina nueva propuesta
  final String reward;          // Recompensa (igual para ambas rutinas)
  final int streakDays;
  final bool isActive;
  final DateTime createdAt;

  const HabitLoop({
    required this.id,
    required this.name,
    required this.cue,
    required this.badRoutine,
    required this.newRoutine,
    required this.reward,
    this.streakDays = 0,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, isActive];
}

/// Un antojo pausado (Modo Pausa de 24 horas)
class PausedCraving extends Equatable {
  final String id;
  final String item;
  final double amount;
  final DateTime pausedAt;
  final CravingDecision? decision; // null = pendiente
  final String currency;

  const PausedCraving({
    required this.id,
    required this.item,
    required this.amount,
    required this.pausedAt,
    this.decision,
    this.currency = 'COP',
  });

  bool get isPending => decision == null;
  bool get isExpired =>
      DateTime.now().difference(pausedAt).inHours >= 24 && isPending;

  Duration get timeRemaining {
    final expiresAt = pausedAt.add(const Duration(hours: 24));
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  List<Object?> get props => [id, item, amount, pausedAt, decision];
}

enum CravingDecision { bought, skipped, later }
