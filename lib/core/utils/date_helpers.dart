import 'package:intl/intl.dart';

/// Utilidades de fecha para ElenaCash.
class DateHelpers {
  static final _monthFormatter = DateFormat('MMMM yyyy', 'es');
  static final _shortDateFormatter = DateFormat('d MMM', 'es');
  static final _fullDateFormatter = DateFormat('d \'de\' MMMM yyyy', 'es');
  static final _monthKeyFormatter = DateFormat('yyyy-MM');

  /// Clave del mes actual para Firestore: "2026-06"
  static String currentMonthKey() => _monthKeyFormatter.format(DateTime.now());

  /// Clave de mes para una fecha dada
  static String monthKey(DateTime date) => _monthKeyFormatter.format(date);

  /// "Junio 2026"
  static String formatMonth(DateTime date) => _monthFormatter.format(date);

  /// "15 jun"
  static String formatShort(DateTime date) => _shortDateFormatter.format(date);

  /// "15 de junio de 2026"
  static String formatFull(DateTime date) => _fullDateFormatter.format(date);

  /// Determina si hoy es día de quincena (día 15 o último día del mes)
  static bool isBiweeklyPayday() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    return now.day == 15 || now.day == lastDayOfMonth;
  }

  /// Días hasta el próximo día de quincena
  static int daysUntilNextPayday() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    if (now.day < 15) return 15 - now.day;
    if (now.day < lastDay) return lastDay - now.day;
    // Es el último día del mes → próxima quincena es el 15 del siguiente
    final nextMonth15 = DateTime(now.year, now.month + 1, 15);
    return nextMonth15.difference(now).inDays;
  }

  /// Nombre del día de la semana en español
  static String dayOfWeek(DateTime date) {
    return DateFormat('EEEE', 'es').format(date);
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Retorna el primer día del mes actual
  static DateTime firstDayOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Retorna el último día del mes actual
  static DateTime lastDayOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// Formato relativo: "hace 2 días", "hace 1 hora"
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora mismo';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 30) return 'hace ${diff.inDays} días';
    if (diff.inDays < 365) return 'hace ${(diff.inDays / 30).round()} meses';
    return 'hace ${(diff.inDays / 365).round()} años';
  }
}
