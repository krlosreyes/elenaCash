// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(debtsWatch)
const debtsWatchProvider = DebtsWatchProvider._();

final class DebtsWatchProvider extends $FunctionalProvider<
        AsyncValue<List<DebtEntity>>,
        List<DebtEntity>,
        Stream<List<DebtEntity>>>
    with $FutureModifier<List<DebtEntity>>, $StreamProvider<List<DebtEntity>> {
  const DebtsWatchProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'debtsWatchProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$debtsWatchHash();

  @$internal
  @override
  $StreamProviderElement<List<DebtEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<DebtEntity>> create(Ref ref) {
    return debtsWatch(ref);
  }
}

String _$debtsWatchHash() => r'a5a832e152569b0e5d0d7203c74e262edb104da1';

@ProviderFor(totalDebtBalance)
const totalDebtBalanceProvider = TotalDebtBalanceProvider._();

final class TotalDebtBalanceProvider
    extends $FunctionalProvider<double, double, double> with $Provider<double> {
  const TotalDebtBalanceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'totalDebtBalanceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$totalDebtBalanceHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalDebtBalance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalDebtBalanceHash() => r'cae0242a67ceda98003abffb14650a7d8e2b6ace';

@ProviderFor(totalMonthlyInterest)
const totalMonthlyInterestProvider = TotalMonthlyInterestProvider._();

final class TotalMonthlyInterestProvider
    extends $FunctionalProvider<double, double, double> with $Provider<double> {
  const TotalMonthlyInterestProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'totalMonthlyInterestProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$totalMonthlyInterestHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return totalMonthlyInterest(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$totalMonthlyInterestHash() =>
    r'2a5390c439ea0ff2de1de8861d63608c27f4cc1c';

@ProviderFor(DebtsNotifier)
const debtsProvider = DebtsNotifierProvider._();

final class DebtsNotifierProvider
    extends $NotifierProvider<DebtsNotifier, AsyncValue<void>> {
  const DebtsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'debtsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$debtsNotifierHash();

  @$internal
  @override
  DebtsNotifier create() => DebtsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$debtsNotifierHash() => r'7c9d5fd6cf4e1b8f2e4adb3ade24f04d394749b5';

abstract class _$DebtsNotifier extends $Notifier<AsyncValue<void>> {
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
