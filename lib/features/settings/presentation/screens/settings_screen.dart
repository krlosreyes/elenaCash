import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // ── Perfil ────────────────────────────────────
          _SectionHeader('Perfil'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primarySurface,
              child: Text(
                (user?.displayName.isNotEmpty == true)
                    ? user!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(user?.displayName ?? 'Usuario'),
            subtitle: Text(user?.email ?? ''),
          ),

          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            label: 'Moneda',
            value: user?.currency ?? 'COP',
            onTap: () => _showCurrencyDialog(context, ref, user?.uid ?? '', user?.currency ?? 'COP'),
          ),

          _SettingsTile(
            icon: Icons.self_improvement_rounded,
            label: 'Mi Rich Life',
            value: user?.richLifeDescription?.isNotEmpty == true ? 'Configurada' : 'Sin configurar',
            onTap: () {},
          ),

          // ── Suscripción ────────────────────────────────
          _SectionHeader('Suscripción'),
          _SettingsTile(
            icon: Icons.star_rounded,
            label: user?.isPremium == true ? 'Premium activo' : 'Actualizar a Premium',
            subtitle: user?.isPremium == true
                ? 'Acceso a todas las funciones'
                : 'Desbloquea FastLane, inversiones avanzadas y más',
            iconColor: AppColors.gold,
            onTap: () => context.push(AppRoutes.subscription),
          ),

          // ── Configuración ─────────────────────────────
          _SectionHeader('Configuración'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notificaciones',
            subtitle: 'Recordatorios del Ritual Quincenal',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Tema',
            value: 'Oscuro',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Idioma',
            value: 'Español',
            onTap: () {},
          ),

          // ── Datos ──────────────────────────────────────
          _SectionHeader('Privacidad y datos'),
          _SettingsTile(
            icon: Icons.download_rounded,
            label: 'Exportar mis datos',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            label: 'Eliminar cuenta',
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: () => _showDeleteDialog(context, ref),
          ),

          // ── Sesión ────────────────────────────────────
          _SectionHeader('Sesión'),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),

          // ── About ─────────────────────────────────────
          _SectionHeader('Acerca de'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('ElenaCash'),
            subtitle: const Text('v1.0.0 · Finanzas que funcionan'),
          ),
          ListTile(
            leading: const Icon(Icons.book_outlined),
            title: const Text('Fuentes'),
            subtitle: const Text('Ramit Sethi · MJ DeMarco · Charles Duhigg'),
          ),

          const Gap(40),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, String userId, String current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Moneda principal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['COP', 'USD'].map((c) => RadioListTile<String>(
            title: Text(c == 'COP' ? '🇨🇴 Peso Colombiano (COP)' : '🇺🇸 Dólar (USD)'),
            value: c,
            groupValue: current,
            activeColor: AppColors.primary,
            onChanged: (v) {
              ctx.pop();
              // TODO: update currency via auth notifier
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Esta acción eliminará permanentemente todos tus datos. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              ctx.pop();
              await ref.read(authProvider.notifier).deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondaryDark,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle, value;
  final Color? iconColor, labelColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondaryDark),
      title: Text(label, style: TextStyle(color: labelColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
          const Gap(4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark),
        ],
      ),
      onTap: onTap,
    );
  }
}
