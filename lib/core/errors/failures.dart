import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos de la app.
/// Usada en el patrón Either<Failure, T> del dominio.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ── Auth Failures ─────────────────────────────────────────────────
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure()
      : super(message: 'Usuario no encontrado. Verifica tu correo.');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure()
      : super(message: 'Contraseña incorrecta. Inténtalo de nuevo.');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure()
      : super(message: 'Este correo ya está registrado.');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure()
      : super(message: 'La contraseña debe tener al menos 6 caracteres.');
}

// ── Network Failures ──────────────────────────────────────────────
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Sin conexión a internet. Revisa tu red.',
    super.code,
  });
}

// ── Server Failures ───────────────────────────────────────────────
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Error del servidor. Inténtalo más tarde.',
    super.code,
  });
}

// ── Cache Failures ────────────────────────────────────────────────
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Error al acceder a datos locales.',
    super.code,
  });
}

// ── Firestore Failures ────────────────────────────────────────────
class FirestoreFailure extends Failure {
  const FirestoreFailure({required super.message, super.code});
}

class PermissionDeniedFailure extends FirestoreFailure {
  const PermissionDeniedFailure()
      : super(message: 'No tienes permiso para acceder a estos datos.');
}

// ── Validation Failures ───────────────────────────────────────────
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

// ── Business Logic Failures ───────────────────────────────────────
class BudgetExceededFailure extends Failure {
  const BudgetExceededFailure({required super.message});
}

class SubscriptionRequiredFailure extends Failure {
  const SubscriptionRequiredFailure()
      : super(
          message:
              'Esta función requiere ElenaCash Premium.',
          code: 'subscription_required',
        );
}
