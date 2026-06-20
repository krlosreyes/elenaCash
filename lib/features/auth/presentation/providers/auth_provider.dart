import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

// ── Current User Stream ───────────────────────────────────────────

@riverpod
Stream<UserEntity?> currentUser(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// ── Auth Notifier ─────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Escuchar cambios de auth automáticamente
    ref.listen(currentUserProvider, (_, next) {
      next.when(
        data: (user) => state = AuthState(
          status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
          user: user,
        ),
        // No sobreescribir el estado con loading: causaba spinner infinito en login
        loading: () {},
        error: (e, _) => state = AuthState(
          status: AuthStatus.error,
          errorMessage: e.toString(),
        ),
      );
    });
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> signInWithEmail({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await ref.read(authRepositoryProvider).signInWithEmail(
          email: email,
          password: password,
        );
    result.fold(
      (failure) => state = AuthState(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await ref.read(authRepositoryProvider).registerWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );
    result.fold(
      (failure) => state = AuthState(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    result.fold(
      (failure) => state = AuthState(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Elimina la cuenta. Devuelve null si ok, Failure si hay error.
  /// Puede devolver ReauthRequiredFailure si la sesión es antigua.
  Future<Failure?> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    return result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return failure;
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return null;
      },
    );
  }

  Future<Failure?> reauthenticateWithPassword(String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .reauthenticateWithPassword(password);
    return result.fold((f) => f, (_) => null);
  }

  Future<Failure?> reauthenticateWithGoogle() async {
    final result =
        await ref.read(authRepositoryProvider).reauthenticateWithGoogle();
    return result.fold((f) => f, (_) => null);
  }

  Future<void> updateProfile({
    String? displayName,
    String? currency,
    String? richLifeDescription,
    String? country,
    String? payFrequency,
    double? monthlyNetIncome,
  }) async {
    final result = await ref.read(authRepositoryProvider).updateUserProfile(
      displayName: displayName,
      currency: currency,
      richLifeDescription: richLifeDescription,
      country: country,
      payFrequency: payFrequency,
      monthlyNetIncome: monthlyNetIncome,
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }
}
