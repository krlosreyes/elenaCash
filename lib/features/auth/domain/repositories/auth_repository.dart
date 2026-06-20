import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contrato del repositorio de autenticación.
/// La capa de dominio solo conoce esta interfaz — nunca la implementación.
abstract class AuthRepository {
  /// Stream del usuario autenticado actual. null = no autenticado.
  Stream<UserEntity?> get authStateChanges;

  /// Inicia sesión con email y contraseña.
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con email y contraseña.
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Inicia sesión con Google.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Cierra la sesión.
  Future<Either<Failure, void>> signOut();

  /// Envía correo de restablecimiento de contraseña.
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Obtiene el usuario actual desde Firestore.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Actualiza el perfil del usuario.
  Future<Either<Failure, UserEntity>> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? currency,
    String? country,
    String? richLifeDescription,
    double? monthlyNetIncome,
    String? payFrequency,
    bool? onboardingCompleted,
  });

  /// Elimina la cuenta del usuario y todos sus datos.
  /// Puede devolver [ReauthRequiredFailure] si la sesión es antigua.
  Future<Either<Failure, void>> deleteAccount();

  /// Re-autentica con email/contraseña (requerido antes de deleteAccount).
  Future<Either<Failure, void>> reauthenticateWithPassword(String password);

  /// Re-autentica con Google (para usuarios que iniciaron sesión con Google).
  Future<Either<Failure, void>> reauthenticateWithGoogle();
}
