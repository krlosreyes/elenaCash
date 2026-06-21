// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$marketRatesHash() => r'market_rates_provider_hash';

/// See also [marketRates].
@ProviderFor(marketRates)
final marketRatesProvider = AutoDisposeFutureProvider<MarketRatesEntity?>.internal(
  marketRates,
  name: r'marketRatesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$marketRatesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef MarketRatesRef = AutoDisposeFutureProviderRef<MarketRatesEntity?>;
