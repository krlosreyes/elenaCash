// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savingsGoals)
const savingsGoalsProvider = SavingsGoalsProvider._();

final class SavingsGoalsProvider extends $FunctionalProvider<
        AsyncValue<List<GoalEntity>>,
        List<GoalEntity>,
        Stream<List<GoalEntity>>>
    with $FutureModifier<List<GoalEntity>>, $StreamProvider<List<GoalEntity>> {
  const SavingsGoalsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'savingsGoalsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$savingsGoalsHash();

  @$internal
  @override
  $StreamProviderElement<List<GoalEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<GoalEntity>> create(Ref ref) {
    return savingsGoals(ref);
  }
}

String _$savingsGoalsHash() => r'8a931dced48ec31797ab10a28ebabce518285357';

@ProviderFor(GoalsNotifier)
const goalsProvider = GoalsNotifierProvider._();

final class GoalsNotifierProvider
    extends $NotifierProvider<GoalsNotifier, AsyncValue<void>> {
  const GoalsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'goalsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$goalsNotifierHash();

  @$internal
  @override
  GoalsNotifier create() => GoalsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$goalsNotifierHash() => r'd6a16ee7eec91fc177c9f40aaadcdf6ea5d8a886';

abstract class _$GoalsNotifier extends $Notifier<AsyncValue<void>> {
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
