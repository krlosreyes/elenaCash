// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(leaderboard)
const leaderboardProvider = LeaderboardProvider._();

final class LeaderboardProvider extends $FunctionalProvider<
        AsyncValue<List<LeaderboardEntry>>,
        List<LeaderboardEntry>,
        Stream<List<LeaderboardEntry>>>
    with
        $FutureModifier<List<LeaderboardEntry>>,
        $StreamProvider<List<LeaderboardEntry>> {
  const LeaderboardProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'leaderboardProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$leaderboardHash();

  @$internal
  @override
  $StreamProviderElement<List<LeaderboardEntry>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<LeaderboardEntry>> create(Ref ref) {
    return leaderboard(ref);
  }
}

String _$leaderboardHash() => r'd1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0';

@ProviderFor(availableQuizzes)
const availableQuizzesProvider = AvailableQuizzesProvider._();

final class AvailableQuizzesProvider extends $FunctionalProvider<
        AsyncValue<List<QuizEntity>>,
        List<QuizEntity>,
        FutureOr<List<QuizEntity>>>
    with
        $FutureModifier<List<QuizEntity>>,
        $FutureProvider<List<QuizEntity>> {
  const AvailableQuizzesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availableQuizzesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availableQuizzesHash();

  @$internal
  @override
  $FutureProviderElement<List<QuizEntity>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<QuizEntity>> create(Ref ref) {
    return availableQuizzes(ref);
  }
}

String _$availableQuizzesHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

@ProviderFor(quizAttempts)
const quizAttemptsProvider = QuizAttemptsProvider._();

final class QuizAttemptsProvider extends $FunctionalProvider<
        AsyncValue<List<QuizAttemptEntity>>,
        List<QuizAttemptEntity>,
        Stream<List<QuizAttemptEntity>>>
    with
        $FutureModifier<List<QuizAttemptEntity>>,
        $StreamProvider<List<QuizAttemptEntity>> {
  const QuizAttemptsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'quizAttemptsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$quizAttemptsHash();

  @$internal
  @override
  $StreamProviderElement<List<QuizAttemptEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<QuizAttemptEntity>> create(Ref ref) {
    return quizAttempts(ref);
  }
}

String _$quizAttemptsHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

@ProviderFor(QuizNotifier)
const quizNotifierProvider = QuizNotifierProvider._();

final class QuizNotifierProvider
    extends $NotifierProvider<QuizNotifier, AsyncValue<void>> {
  const QuizNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'quizNotifierProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$quizNotifierHash();

  @$internal
  @override
  QuizNotifier create() => QuizNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$quizNotifierHash() => r'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

abstract class _$QuizNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
