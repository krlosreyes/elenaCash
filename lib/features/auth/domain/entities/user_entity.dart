import 'package:equatable/equatable.dart';

/// Entidad de usuario del dominio.
/// Independiente de Firebase — pura lógica de negocio.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String currency;
  final String country;
  final String payFrequency; // 'biweekly' | 'monthly'
  final double monthlyNetIncome;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String richLifeDescription;
  final bool onboardingCompleted;
  final DateTime createdAt;
  /// 'password' | 'google.com' — proveedor con el que se autenticó
  final String signInProvider;
  /// IDs de las categorías de Rich Life seleccionadas en el onboarding.
  /// Ej: ['viajes', 'tiempo_libre', 'negocio']
  final List<String> richLifeCategories;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.currency = 'COP',
    this.country = 'CO',
    this.payFrequency = 'biweekly',
    this.monthlyNetIncome = 0,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.richLifeDescription = '',
    this.onboardingCompleted = false,
    required this.createdAt,
    this.signInProvider = 'password',
    this.richLifeCategories = const [],
  });

  bool get isGoogleUser => signInProvider == 'google.com';

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? currency,
    String? country,
    String? payFrequency,
    double? monthlyNetIncome,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? richLifeDescription,
    bool? onboardingCompleted,
    DateTime? createdAt,
    String? signInProvider,
    List<String>? richLifeCategories,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      payFrequency: payFrequency ?? this.payFrequency,
      monthlyNetIncome: monthlyNetIncome ?? this.monthlyNetIncome,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      richLifeDescription: richLifeDescription ?? this.richLifeDescription,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      signInProvider: signInProvider ?? this.signInProvider,
      richLifeCategories: richLifeCategories ?? this.richLifeCategories,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, isPremium, onboardingCompleted];
}
