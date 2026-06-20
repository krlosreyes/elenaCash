// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(habitEngineWatch)
const habitEngineWatchProvider = HabitEngineWatchProvider._();

final class HabitEngineWatchProvider extends $FunctionalProvider<
        AsyncValue<HabitEngineEntity?>,
        HabitEngineEntity?,
        Stream<HabitEngineEntity?>>
    with
        $FutureModifier<HabitEngineEntity?>,
        $StreamProvider<HabitEngineEntity?> {
  const HabitEngineWatchProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'habitEngineWatchProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$habitEngineWatchHash();

  @$internal
  @override
  $StreamProviderElement<HabitEngineEntity?> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<HabitEngineEntity?> create(Ref ref) {
    return habitEngineWatch(ref);
  }
}

String _$habitEngineWatchHash() => r'859fe46c58e172d728bd795e451f0b18ca3c9886';

@ProviderFor(HabitEngineNotifier)
const habitEngineProvider = HabitEngineNotifierProvider._();

final class HabitEngineNotifierProvider
    extends $NotifierProvider<HabitEngineNotifier, AsyncValue<void>> {
  const HabitEngineNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'habitEngineProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$habitEngineNotifierHash();

  @$internal
  @override
  HabitEngineNotifier create() => HabitEngineNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$habitEngineNotifierHash() =>
    r'989ce4a5b5c407add038f7c570ff04c13870db61';

abstract class _$HabitEngineNotifier extends $Notifier<AsyncValue<void>> {
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
