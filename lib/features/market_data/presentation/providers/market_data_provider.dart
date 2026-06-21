import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/market_rates_entity.dart';

part 'market_data_provider.g.dart';

// ── Frankfurter API — sin key, datos del BCE ──────────────────────
// https://api.frankfurter.dev/v2/latest?base=USD&symbols=COP,EUR
// Actualiza cada día hábil ~16:00 CET

@riverpod
Future<MarketRatesEntity?> marketRates(Ref ref) async {
  try {
    // Tasa actual
    final latestRes = await http
        .get(Uri.parse(
            'https://api.frankfurter.dev/v2/latest?base=USD&symbols=COP,EUR'))
        .timeout(const Duration(seconds: 8));

    if (latestRes.statusCode != 200) return null;
    final latestJson = jsonDecode(latestRes.body) as Map<String, dynamic>;
    final rates = latestJson['rates'] as Map<String, dynamic>;
    final usdToCop = (rates['COP'] as num).toDouble();
    final eurToCop = (rates['EUR'] as num? ?? 0) > 0
        ? usdToCop / (rates['EUR'] as num).toDouble()
        : usdToCop * 1.08;

    // Tasa de ayer para calcular delta (último dato disponible antes de hoy)
    double usdPrev = usdToCop;
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final y = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final prevRes = await http
          .get(Uri.parse(
              'https://api.frankfurter.dev/v2/$y?base=USD&symbols=COP'))
          .timeout(const Duration(seconds: 6));
      if (prevRes.statusCode == 200) {
        final prevJson = jsonDecode(prevRes.body) as Map<String, dynamic>;
        final prevRates = prevJson['rates'] as Map<String, dynamic>;
        usdPrev = (prevRates['COP'] as num).toDouble();
      }
    } catch (_) {
      // Si falla, usamos tasa actual como prev (delta = 0)
    }

    return MarketRatesEntity(
      usdToCop: usdToCop,
      eurToCop: eurToCop,
      usdPrevClose: usdPrev,
      updatedAt: DateTime.now(),
    );
  } catch (_) {
    return null;
  }
}
