// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketRates)
const marketRatesProvider = MarketRatesProvider._();

final class MarketRatesProvider extends $FunctionalProvider<
        AsyncValue<MarketRatesEntity?>,
        MarketRatesEntity?,
        FutureOr<MarketRatesEntity?>>
    with
        $FutureModifier<MarketRatesEntity?>,
        $FutureProvider<MarketRatesEntity?> {
  const MarketRatesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketRatesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketRatesHash();

  @$internal
  @override
  $FutureProviderElement<MarketRatesEntity?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarketRatesEntity?> create(Ref ref) {
    return marketRates(ref);
  }
}

String _$marketRatesHash() => r'd1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0';
