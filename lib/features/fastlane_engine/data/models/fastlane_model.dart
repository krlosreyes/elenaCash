import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/fastlane_entity.dart';

class FastLaneModel extends FastLaneEntity {
  const FastLaneModel({
    required super.userId,
    super.fastLaneScore,
    super.activeIncomeMonthly,
    super.passiveIncomeMonthly,
    super.moneyTreeBranches,
    required super.lastUpdated,
  });

  factory FastLaneModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final d = doc.data()!;
    final branches = <MoneyTreeBranch>[
      ...(d['moneyTreeBranches'] as List<dynamic>? ?? [])
          .map((b) => MoneyTreeBranch(
                id: b['id'] as String,
                type: BranchType.values.byName(b['type'] as String? ?? 'other'),
                label: b['label'] as String? ?? '',
                monthlyAmount: (b['monthlyAmount'] as num?)?.toDouble() ?? 0.0,
                isActive: b['isActive'] as bool? ?? true,
                createdAt: b['createdAt'] != null
                    ? (b['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
              ))
    ];

    return FastLaneModel(
      userId: userId,
      fastLaneScore: ((d['fastLaneScore'] as num?)?.toDouble() ?? 0.0).round(),
      activeIncomeMonthly: (d['activeIncomeMonthly'] as num?)?.toDouble() ?? 0.0,
      passiveIncomeMonthly: (d['passiveIncomeMonthly'] as num?)?.toDouble() ?? 0.0,
      moneyTreeBranches: branches,
      lastUpdated: d['lastUpdated'] != null
          ? (d['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fastLaneScore': fastLaneScore,
      'activeIncomeMonthly': activeIncomeMonthly,
      'passiveIncomeMonthly': passiveIncomeMonthly,
      'moneyTreeBranches': moneyTreeBranches.map((b) => {
        'id': b.id,
        'type': b.type.name,
        'label': b.label,
        'monthlyAmount': b.monthlyAmount,
        'isActive': b.isActive,
        'createdAt': Timestamp.fromDate(b.createdAt),
      }).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}
