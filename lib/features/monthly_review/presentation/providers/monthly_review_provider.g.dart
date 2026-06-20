// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_review_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(currentMonthReview)
const currentMonthReviewProvider = CurrentMonthReviewProvider._();

final class CurrentMonthReviewProvider extends $FunctionalProvider<
        AsyncValue<MonthlyReviewEntity?>,
        MonthlyReviewEntity?,
        Stream<MonthlyReviewEntity?>>
    with
        $FutureModifier<MonthlyReviewEntity?>,
        $StreamProvider<MonthlyReviewEntity?> {
  const CurrentMonthReviewProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentMonthReviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentMonthReviewHash();

  @$internal
  @override
  $StreamProviderElement<MonthlyReviewEntity?> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<MonthlyReviewEntity?> create(Ref ref) {
    return currentMonthReview(ref);
  }
}

String _$currentMonthReviewHash() =>
    r'f16b44c182a59b1d0814c11452647210d7a9dd3f';

@ProviderFor(monthlyReviewHistory)
const monthlyReviewHistoryProvider = MonthlyReviewHistoryProvider._();

final class MonthlyReviewHistoryProvider extends $FunctionalProvider<
        AsyncValue<List<MonthlyReviewEntity>>,
        List<MonthlyReviewEntity>,
        Stream<List<MonthlyReviewEntity>>>
    with
        $FutureModifier<List<MonthlyReviewEntity>>,
        $StreamProvider<List<MonthlyReviewEntity>> {
  const MonthlyReviewHistoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlyReviewHistoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlyReviewHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<MonthlyReviewEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<MonthlyReviewEntity>> create(Ref ref) {
    return monthlyReviewHistory(ref);
  }
}

String _$monthlyReviewHistoryHash() =>
    r'b629f9e3236ad4c97703aa71c788b603b7acd439';

@ProviderFor(MonthlyReviewNotifier)
const monthlyReviewProvider = MonthlyReviewNotifierProvider._();

final class MonthlyReviewNotifierProvider
    extends $NotifierProvider<MonthlyReviewNotifier, AsyncValue<void>> {
  const MonthlyReviewNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monthlyReviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monthlyReviewNotifierHash();

  @$internal
  @override
  MonthlyReviewNotifier create() => MonthlyReviewNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$monthlyReviewNotifierHash() =>
    r'afd49ada588cc3a8b1315cce5ea566e3fc90fddf';

abstract class _$MonthlyReviewNotifier extends $Notifier<AsyncValue<void>> {
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
