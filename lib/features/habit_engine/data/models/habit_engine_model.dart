import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/habit_engine_entity.dart';

class HabitEngineModel extends HabitEngineEntity {
  const HabitEngineModel({
    required super.userId,
    super.keystoneHabitId,
    super.habitStreak,
    super.longestStreak,
    super.lastHabitCompletedAt,
    super.habitLoops,
    super.pausedCravings,
  });

  factory HabitEngineModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final d = doc.data()!;

    final loops = (d['habitLoops'] as List<dynamic>? ?? [])
        .map((l) => HabitLoop(
              id: l['id'] as String,
              name: l['name'] as String,
              cue: l['cue'] as String,
              badRoutine: l['badRoutine'] as String,
              newRoutine: l['newRoutine'] as String,
              reward: l['reward'] as String,
              streakDays: l['streakDays'] as int? ?? 0,
              isActive: l['isActive'] as bool? ?? true,
              createdAt: (l['createdAt'] as Timestamp).toDate(),
            ))
        .toList();

    final cravings = (d['pausedCravings'] as List<dynamic>? ?? [])
        .map((c) => PausedCraving(
              id: c['id'] as String,
              item: c['item'] as String,
              amount: (c['amount'] as num).toDouble(),
              pausedAt: (c['pausedAt'] as Timestamp).toDate(),
              decision: c['decision'] != null
                  ? CravingDecision.values.byName(c['decision'] as String)
                  : null,
              currency: c['currency'] as String? ?? 'COP',
            ))
        .toList();

    return HabitEngineModel(
      userId: userId,
      keystoneHabitId: d['keystoneHabitId'] as String? ?? 'quincenal_review',
      habitStreak: d['habitStreak'] as int? ?? 0,
      longestStreak: d['longestStreak'] as int? ?? 0,
      lastHabitCompletedAt: d['lastHabitCompletedAt'] != null
          ? (d['lastHabitCompletedAt'] as Timestamp).toDate()
          : null,
      habitLoops: loops,
      pausedCravings: cravings,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'keystoneHabitId': keystoneHabitId,
      'habitStreak': habitStreak,
      'longestStreak': longestStreak,
      'lastHabitCompletedAt': lastHabitCompletedAt != null
          ? Timestamp.fromDate(lastHabitCompletedAt!)
          : null,
      'habitLoops': habitLoops.map((l) => {
        'id': l.id,
        'name': l.name,
        'cue': l.cue,
        'badRoutine': l.badRoutine,
        'newRoutine': l.newRoutine,
        'reward': l.reward,
        'streakDays': l.streakDays,
        'isActive': l.isActive,
        'createdAt': Timestamp.fromDate(l.createdAt),
      }).toList(),
      'pausedCravings': pausedCravings.map((c) => {
        'id': c.id,
        'item': c.item,
        'amount': c.amount,
        'pausedAt': Timestamp.fromDate(c.pausedAt),
        'decision': c.decision?.name,
        'currency': c.currency,
      }).toList(),
    };
  }
}
