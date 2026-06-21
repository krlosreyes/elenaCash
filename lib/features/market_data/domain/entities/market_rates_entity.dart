import 'package:equatable/equatable.dart';

class MarketRatesEntity extends Equatable {
  final double usdToCop;
  final double eurToCop;
  final double usdPrevClose;   // yesterday's rate for delta
  final DateTime updatedAt;

  const MarketRatesEntity({
    required this.usdToCop,
    required this.eurToCop,
    required this.usdPrevClose,
    required this.updatedAt,
  });

  /// Variación porcentual del USD vs ayer
  double get usdChangePct =>
      usdPrevClose > 0 ? ((usdToCop - usdPrevClose) / usdPrevClose) * 100 : 0;

  bool get usdUp => usdChangePct >= 0;

  /// Cuánto cuesta hoy en COP un ítem que vale [usdAmount] dólares
  double copCost(double usdAmount) => usdAmount * usdToCop;

  @override
  List<Object?> get props => [usdToCop, eurToCop, updatedAt];
}
