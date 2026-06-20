// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conscious_plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(consciousPlanWatch)
const consciousPlanWatchProvider = ConsciousPlanWatchProvider._();

final class ConsciousPlanWatchProvider extends $FunctionalProvider<
        AsyncValue<ConsciousPlanEntity?>,
        ConsciousPlanEntity?,
        Stream<ConsciousPlanEntity?>>
    with
        $FutureModifier<ConsciousPlanEntity?>,
        $StreamProvider<ConsciousPlanEntity?> {
  const ConsciousPlanWatchProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'consciousPlanWatchProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$consciousPlanWatchHash();

  @$internal
  @override
  $StreamProviderElement<ConsciousPlanEntity?> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ConsciousPlanEntity?> create(Ref ref) {
    return consciousPlanWatch(ref);
  }
}

String _$consciousPlanWatchHash() =>
    r'23ed156c7ad0c1ef23beaa3a8cc8e8de409ac995';

@ProviderFor(ConsciousPlanNotifier)
const consciousPlanProvider = ConsciousPlanNotifierProvider._();

final class ConsciousPlanNotifierProvider
    extends $NotifierProvider<ConsciousPlanNotifier, AsyncValue<void>> {
  const ConsciousPlanNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'consciousPlanProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$consciousPlanNotifierHash();

  @$internal
  @override
  ConsciousPlanNotifier create() => ConsciousPlanNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$consciousPlanNotifierHash() =>
    r'78d5e9a9fbf4406bcae89bd8288fe4d9ab80aa6f';

abstract class _$ConsciousPlanNotifier extends $Notifier<AsyncValue<void>> {
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
