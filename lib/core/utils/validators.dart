/// Validadores de formularios para ElenaCash.
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'El correo es requerido';
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!regex.hasMatch(value)) return 'Ingresa un correo válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$fieldName es requerido';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa un monto';
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    final number = double.tryParse(cleaned);
    if (number == null) return 'Ingresa un monto válido';
    if (number <= 0) return 'El monto debe ser mayor a cero';
    return null;
  }

  static String? percentage(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa un porcentaje';
    final number = double.tryParse(value);
    if (number == null) return 'Ingresa un porcentaje válido';
    if (number < 0 || number > 100) return 'El porcentaje debe estar entre 0 y 100';
    return null;
  }

  static String? interestRate(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa la tasa de interés';
    final number = double.tryParse(value);
    if (number == null) return 'Ingresa una tasa válida';
    if (number < 0 || number > 200) return 'Tasa inválida (0–200%)';
    return null;
  }

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa tu nombre';
    if (value.trim().length < 2) return 'Mínimo 2 caracteres';
    if (value.trim().length > 50) return 'Máximo 50 caracteres';
    return null;
  }
}
