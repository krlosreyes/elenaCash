import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
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
        final user = next.user;
        if (user != null && !user.onboardingCompleted) {
          context.go(AppRoutes.onboarding);
        } else {
          context.go(AppRoutes.dashboard);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(48),

                // Logo y titular
                _buildHeader(theme)
                    .animate()
                    .fadeIn(duration: AppConstants.animMedium)
                    .slideY(begin: -0.2, end: 0),

                const Gap(48),

                // Formulario
                _buildForm(theme, authState)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: AppConstants.animMedium),

                const Gap(24),

                // Botones sociales
                _buildSocialLogin(authState)
                    .animate()
                    .fadeIn(delay: 400.ms, duration: AppConstants.animMedium),

                const Gap(32),

                // Ir a registro
                _buildFooter(context, theme)
                    .animate()
                    .fadeIn(delay: 600.ms, duration: AppConstants.animMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.park_rounded, color: Colors.black, size: 32),
        ),
        const Gap(24),
        Text(
          'Bienvenido de\nvuelta 👋',
          style: theme.textTheme.displayMedium,
        ),
        const Gap(8),
        Text(
          'Inicia sesión para continuar construyendo\ntu vida rica.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, AuthState authState) {
    return Column(
      children: [
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _signIn(),
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
        const Gap(8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // TODO: Pantalla de recuperación
            },
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const Gap(8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _signIn,
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Text('Iniciar sesión'),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLogin(AuthState authState) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'o continúa con',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: authState.isLoading ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
            label: const Text('Continuar con Google'),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿No tienes cuenta?', style: theme.textTheme.bodyMedium),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text('Regístrate gratis'),
        ),
      ],
    );
  }
}
