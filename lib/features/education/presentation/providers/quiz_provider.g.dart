// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

part of 'quiz_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$availableQuizzesHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

/// Quizzes disponibles (seed + futura Firestore override)
@ProviderFor(availableQuizzes)
final availableQuizzesProvider =
    AutoDisposeFutureProvider<List<QuizEntity>>.internal(
  availableQuizzes,
  name: r'availableQuizzesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableQuizzesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef AvailableQuizzesRef = AutoDisposeFutureProviderRef<List<QuizEntity>>;

String _$quizAttemptsHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

/// Intentos del usuario ordenados por fecha
@ProviderFor(quizAttempts)
final quizAttemptsProvider =
    AutoDisposeStreamProvider<List<QuizAttemptEntity>>.internal(
  quizAttempts,
  name: r'quizAttemptsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$quizAttemptsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef QuizAttemptsRef = AutoDisposeStreamProviderRef<List<QuizAttemptEntity>>;

String _$quizNotifierHash() => r'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

/// Notifier para manejar envío y guardado de quizzes
@ProviderFor(QuizNotifier)
final quizNotifierProvider =
    AutoDisposeNotifierProvider<QuizNotifier, AsyncValue<void>>.internal(
  QuizNotifier.new,
  name: r'quizNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$quizNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef QuizNotifierRef = AutoDisposeNotifierProviderRef<AsyncValue<void>>;
