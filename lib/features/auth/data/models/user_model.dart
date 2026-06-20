import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

/// Modelo de usuario — capa de datos.
/// Se serializa/deserializa hacia/desde Firestore.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.currency,
    super.country,
    super.payFrequency,
    super.monthlyNetIncome,
    super.isPremium,
    super.premiumExpiresAt,
    super.richLifeDescription,
    super.onboardingCompleted,
    required super.createdAt,
    super.signInProvider,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String signInProvider = 'password',
  }) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      currency: data['currency'] as String? ?? 'COP',
      country: data['country'] as String? ?? 'CO',
      payFrequency: data['payFrequency'] as String? ?? 'biweekly',
      monthlyNetIncome: (data['monthlyNetIncome'] as num?)?.toDouble() ?? 0.0,
      isPremium: data['isPremium'] as bool? ?? false,
      premiumExpiresAt: data['premiumExpiresAt'] != null
          ? (data['premiumExpiresAt'] as Timestamp).toDate()
          : null,
      richLifeDescription: data['richLifeDescription'] as String? ?? '',
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      signInProvider: data['signInProvider'] as String? ?? signInProvider,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'currency': currency,
      'country': country,
      'payFrequency': payFrequency,
      'monthlyNetIncome': monthlyNetIncome,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt != null
          ? Timestamp.fromDate(premiumExpiresAt!)
          : null,
      'richLifeDescription': richLifeDescription,
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toInitialFirestore() {
    return {
      ...toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      currency: entity.currency,
      country: entity.country,
      payFrequency: entity.payFrequency,
      monthlyNetIncome: entity.monthlyNetIncome,
      isPremium: entity.isPremium,
      premiumExpiresAt: entity.premiumExpiresAt,
      richLifeDescription: entity.richLifeDescription,
      onboardingCompleted: entity.onboardingCompleted,
      createdAt: entity.createdAt,
      signInProvider: entity.signInProvider,
    );
  }
}
