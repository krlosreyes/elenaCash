import 'package:intl/intl.dart';

/// Formateador de moneda para LATAM.
/// Soporte para COP, USD, MXN, CLP, PEN.
class CurrencyFormatter {
  static final _formatters = <String, NumberFormat>{
    'COP': NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0),
    'USD': NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 2),
    'MXN': NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2),
    'CLP': NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0),
    'PEN': NumberFormat.currency(locale: 'es_PE', symbol: 'S/', decimalDigits: 2),
  };

  /// Formatea un número como moneda.
  /// Ejemplo: format(4500000, 'COP') → '$4.500.000'
  static String format(double amount, String currency) {
    final formatter = _formatters[currency] ?? _formatters['COP']!;
    return formatter.format(amount);
  }

  /// Formato compacto: $4.5M, $450K
  static String formatCompact(double amount, String currency) {
    final symbol = _currencySymbol(currency);
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
    }
    return format(amount, currency);
  }

  /// Calcula el costo en horas trabajadas.
  /// Ejemplo: timeCost(650000, 4500000) → "3.5 horas de tu vida"
  static String timeCost(double amount, double monthlyIncome) {
    if (monthlyIncome <= 0) return '—';
    final hourlyRate = monthlyIncome / (8 * 22); // 8h/día × 22 días
    final hours = amount / hourlyRate;
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)} minutos de tu vida';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} horas de tu vida';
    } else {
      final days = hours / 8;
      return '${days.toStringAsFixed(1)} días de trabajo';
    }
  }

  static String _currencySymbol(String currency) {
    return switch (currency) {
      'COP' || 'USD' || 'MXN' || 'CLP' => '\$',
      'PEN' => 'S/',
      _ => '\$',
    };
  }

  /// Parsea un string de moneda a double.
  static double? parse(String value, String currency) {
    try {
      final cleaned = value
          .replaceAll(RegExp(r'[^\d,.]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}
