// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fastlane_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fastLaneEngine)
const fastLaneEngineProvider = FastLaneEngineProvider._();

final class FastLaneEngineProvider extends $FunctionalProvider<
        AsyncValue<FastLaneEntity?>, FastLaneEntity?, Stream<FastLaneEntity?>>
    with $FutureModifier<FastLaneEntity?>, $StreamProvider<FastLaneEntity?> {
  const FastLaneEngineProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'fastLaneEngineProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fastLaneEngineHash();

  @$internal
  @override
  $StreamProviderElement<FastLaneEntity?> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<FastLaneEntity?> create(Ref ref) {
    return fastLaneEngine(ref);
  }
}

String _$fastLaneEngineHash() => r'2809fbfbd7846a5008f68db69a056b7b248b0968';

@ProviderFor(FastLaneNotifier)
const fastLaneProvider = FastLaneNotifierProvider._();

final class FastLaneNotifierProvider
    extends $NotifierProvider<FastLaneNotifier, AsyncValue<void>> {
  const FastLaneNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'fastLaneProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fastLaneNotifierHash();

  @$internal
  @override
  FastLaneNotifier create() => FastLaneNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$fastLaneNotifierHash() => r'1c1a8d08cd52ddc6500e4220d481522f42cff566';

abstract class _$FastLaneNotifier extends $Notifier<AsyncValue<void>> {
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
