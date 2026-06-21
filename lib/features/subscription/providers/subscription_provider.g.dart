// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(customerInfoStream)
const customerInfoStreamProvider = CustomerInfoStreamProvider._();

final class CustomerInfoStreamProvider extends $FunctionalProvider<
        AsyncValue<CustomerInfo>,
        CustomerInfo,
        Stream<CustomerInfo>>
    with
        $FutureModifier<CustomerInfo>,
        $StreamProvider<CustomerInfo> {
  const CustomerInfoStreamProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'customerInfoStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$customerInfoStreamHash();

  @$internal
  @override
  $StreamProviderElement<CustomerInfo> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CustomerInfo> create(Ref ref) {
    return customerInfoStream(ref);
  }
}

String _$customerInfoStreamHash() =>
    r'e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0';

@ProviderFor(purchaseOfferings)
const purchaseOfferingsProvider = PurchaseOfferingsProvider._();

final class PurchaseOfferingsProvider extends $FunctionalProvider<
        AsyncValue<Offerings?>, Offerings?, FutureOr<Offerings?>>
    with $FutureModifier<Offerings?>, $FutureProvider<Offerings?> {
  const PurchaseOfferingsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'purchaseOfferingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$purchaseOfferingsHash();

  @$internal
  @override
  $FutureProviderElement<Offerings?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Offerings?> create(Ref ref) {
    return purchaseOfferings(ref);
  }
}

String _$purchaseOfferingsHash() =>
    r'f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0';

@ProviderFor(SubscriptionNotifier)
const subscriptionNotifierProvider = SubscriptionNotifierProvider._();

final class SubscriptionNotifierProvider
    extends $NotifierProvider<SubscriptionNotifier, AsyncValue<String?>> {
  const SubscriptionNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subscriptionNotifierProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subscriptionNotifierHash();

  @$internal
  @override
  SubscriptionNotifier create() => SubscriptionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<String?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<String?>>(value),
    );
  }
}

String _$subscriptionNotifierHash() =>
    r'a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1';

abstract class _$SubscriptionNotifier extends $Notifier<AsyncValue<String?>> {
  AsyncValue<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<String?>, AsyncValue<String?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<String?>, AsyncValue<String?>>,
        AsyncValue<String?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
