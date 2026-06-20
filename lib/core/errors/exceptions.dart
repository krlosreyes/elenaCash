/// Excepciones lanzadas desde la capa de datos.
/// Se mapean a [Failure] en los repositorios.

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException({required this.message, this.code});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'Sin conexión a internet.'});
}

class FirestoreException implements Exception {
  final String message;
  final String? code;
  const FirestoreException({required this.message, this.code});
}

class CacheException implements Exception {
  final String message;
  const CacheException({this.message = 'Error al acceder a datos locales.'});
}

class SubscriptionException implements Exception {
  final String message;
  const SubscriptionException({this.message = 'Error con la suscripción.'});
}

class ValidationException implements Exception {
  final String message;
  const ValidationException({required this.message});
}
