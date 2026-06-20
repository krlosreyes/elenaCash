import 'dart:math' as math;
import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final DebtType type;
  final double totalAmount;
  final double currentBalance;
  final double interestRate;  // % anual
  final double minimumPayment;
  final int paymentDay;
  final DebtStrategy strategy;
  final bool isActive;
  final DateTime createdAt;

  const DebtEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.totalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.minimumPayment,
    required this.paymentDay,
    this.strategy = DebtStrategy.avalanche,
    this.isActive = true,
    required this.createdAt,
  });

  double get progressPct =>
      totalAmount > 0 ? ((totalAmount - currentBalance) / totalAmount).clamp(0.0, 1.0) : 0;

  double get paidAmount => totalAmount - currentBalance;

  double get monthlyInterestAmount => currentBalance * (interestRate / 100 / 12);

  double get totalInterestCost {
    double balance = currentBalance;
    double totalInterest = 0;
    final monthly = interestRate / 100 / 12;
    int months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthly;
      totalInterest += interest;
      balance += interest - minimumPayment;
      months++;
    }
    return totalInterest.clamp(0, double.infinity);
  }

  int monthsToPayoff(double payment) => monthsToPayoffWith(payment);

  int monthsToPayoffWith(double payment) {
    if (payment <= 0) return 9999;
    final monthly = interestRate / 100 / 12;
    if (monthly == 0) return (currentBalance / payment).ceil();
    double balance = currentBalance;
    int months = 0;
    while (balance > 0 && months < 600) {
      balance += balance * monthly - payment;
      months++;
    }
    return months;
  }

  double totalInterestWith(double payment) {
    double balance = currentBalance;
    double totalInterest = 0;
    final monthly = interestRate / 100 / 12;
    int months = 0;
    while (balance > 0 && months < 600) {
      final interest = balance * monthly;
      totalInterest += interest;
      balance += interest - payment;
      months++;
    }
    return totalInterest.clamp(0, double.infinity);
  }

  String get typeLabel => switch (type) {
    DebtType.creditCard => 'Tarjeta de crédito',
    DebtType.personalLoan => 'Préstamo personal',
    DebtType.mortgage => 'Hipoteca / Vivienda',
    DebtType.carLoan => 'Crédito de carro',
    DebtType.studentLoan => 'Préstamo educativo',
    DebtType.other => 'Otra deuda',
  };

  String get typeEmoji => switch (type) {
    DebtType.creditCard => '💳',
    DebtType.personalLoan => '🤝',
    DebtType.mortgage => '🏠',
    DebtType.carLoan => '🚗',
    DebtType.studentLoan => '🎓',
    DebtType.other => '📋',
  };

  @override
  List<Object?> get props => [id, currentBalance, interestRate, isActive];
}

enum DebtType { creditCard, personalLoan, mortgage, carLoan, studentLoan, other }
enum DebtStrategy { avalanche, snowball }

extension DebtTypeX on DebtType {
  String get label => switch (this) {
    DebtType.creditCard => 'Tarjeta de crédito',
    DebtType.personalLoan => 'Préstamo personal',
    DebtType.mortgage => 'Hipoteca',
    DebtType.carLoan => 'Crédito vehículo',
    DebtType.studentLoan => 'Préstamo educativo',
    DebtType.other => 'Otro',
  };
  String get emoji => switch (this) {
    DebtType.creditCard => '💳',
    DebtType.personalLoan => '💵',
    DebtType.mortgage => '🏠',
    DebtType.carLoan => '🚗',
    DebtType.studentLoan => '🎓',
    DebtType.other => '📋',
  };
}
