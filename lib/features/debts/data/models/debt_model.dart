import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    required super.totalAmount,
    required super.currentBalance,
    required super.interestRate,
    required super.minimumPayment,
    required super.paymentDay,
    super.strategy,
    super.isActive,
    required super.createdAt,
  });

  factory DebtModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, String userId) {
    final d = doc.data()!;
    return DebtModel(
      id: doc.id,
      userId: userId,
      name: d['name'] as String? ?? '',
      type: DebtType.values.firstWhere(
        (e) => e.name == (d['type'] as String? ?? 'creditCard'),
        orElse: () => DebtType.other,
      ),
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0,
      currentBalance: (d['currentBalance'] as num?)?.toDouble() ?? 0,
      interestRate: (d['interestRate'] as num?)?.toDouble() ?? 0,
      minimumPayment: (d['minimumPayment'] as num?)?.toDouble() ?? 0,
      paymentDay: (d['paymentDay'] as int?) ?? 1,
      strategy: DebtStrategy.values.firstWhere(
        (e) => e.name == (d['strategy'] as String? ?? 'avalanche'),
        orElse: () => DebtStrategy.avalanche,
      ),
      isActive: d['isActive'] as bool? ?? true,
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type.name,
    'totalAmount': totalAmount,
    'currentBalance': currentBalance,
    'interestRate': interestRate,
    'minimumPayment': minimumPayment,
    'paymentDay': paymentDay,
    'strategy': strategy.name,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toInitialFirestore() => {
    ...toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
  };
}
