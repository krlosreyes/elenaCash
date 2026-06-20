import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones.')),
      );
      return;
    }
    await ref.read(authProvider.notifier).registerWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    ref.listen(authProvider, (_, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
      if (next.status == AuthStatus.authenticated && mounted) {
        context.go(AppRoutes.onboarding);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crea tu cuenta', style: theme.textTheme.displayMedium)
                    .animate()
                    .fadeIn(duration: AppConstants.animMedium),
                const Gap(8),
                Text(
                  'Empieza tu camino hacia la libertad financiera. Gratis.',
                  style: theme.textTheme.bodyMedium,
                ).animate().fadeIn(delay: 100.ms),
                const Gap(32),

                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  validator: Validators.displayName,
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const Gap(16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const Gap(20),

                // Términos y condiciones
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Acepto los ',
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: 'términos y condiciones',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'política de privacidad',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _register,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Crear cuenta gratis'),
                  ),
                ),
                const Gap(16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta?', style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Inicia sesión'),
                    ),
                  ],
                ),
              ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}
