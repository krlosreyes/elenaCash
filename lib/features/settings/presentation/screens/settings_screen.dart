import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../conscious_plan/presentation/providers/conscious_plan_provider.dart';
import '../../../fastlane_engine/presentation/providers/fastlane_provider.dart';
import '../../../debts/presentation/providers/debts_provider.dart';
import '../../../savings_goals/presentation/providers/goals_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final themeMode = ref.watch(themeModeProvider);

    final themeModeLabel = switch (themeMode) {
      ThemeMode.dark => 'Oscuro',
      ThemeMode.light => 'Claro',
      ThemeMode.system => 'Sistema',
    };

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
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(user?.displayName ?? 'Usuario'),
            subtitle: Text(user?.email ?? ''),
          ),

          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            label: 'Moneda',
            value: user?.currency ?? 'COP',
            onTap: () => _showCurrencyDialog(
                context, ref, user?.currency ?? 'COP'),
          ),

          _SettingsTile(
            icon: Icons.self_improvement_rounded,
            label: 'Mi Rich Life',
            value: (user?.richLifeDescription.isNotEmpty == true)
                ? 'Configurada ✓'
                : 'Sin configurar',
            onTap: () => _showRichLifeDialog(
                context, ref, user?.richLifeDescription ?? ''),
          ),

          // ── Suscripción ────────────────────────────────
          _SectionHeader('Suscripción'),
          _SettingsTile(
            icon: Icons.star_rounded,
            label: user?.isPremium == true
                ? 'Premium activo'
                : 'Actualizar a Premium',
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
            subtitle: 'Recordatorio del Ritual Quincenal',
            onTap: () => _showNotificationsDialog(context),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            label: 'Tema',
            value: themeModeLabel,
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),

          // ── Datos ──────────────────────────────────────
          _SectionHeader('Privacidad y datos'),
          _SettingsTile(
            icon: Icons.download_rounded,
            label: 'Exportar mis datos',
            onTap: () => _exportData(context, ref, user?.currency ?? 'COP'),
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
            title: const Text('Cerrar sesión',
                style: TextStyle(color: AppColors.error)),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),

          // ── Acerca de ─────────────────────────────────
          _SectionHeader('Acerca de'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('ElenaCash'),
            subtitle: Text('v1.0.0 · Finanzas que funcionan'),
          ),
          const ListTile(
            leading: Icon(Icons.book_outlined),
            title: Text('Fuentes'),
            subtitle: Text('Ramit Sethi · MJ DeMarco · Charles Duhigg'),
          ),

          const Gap(40),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────

  void _showCurrencyDialog(
      BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder: (ctx) {
        String selected = current;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Moneda principal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Afecta cómo se muestran todos los montos en la app.',
                  style: TextStyle(fontSize: 13),
                ),
                const Gap(12),
                ...['COP', 'USD', 'MXN', 'CLP', 'PEN'].map((c) =>
                    RadioListTile<String>(
                      title: Text(_currencyLabel(c)),
                      value: c,
                      groupValue: selected,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => selected = v!),
                    )),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => ctx.pop(), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  ctx.pop();
                  await ref
                      .read(authProvider.notifier)
                      .updateProfile(currency: selected);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRichLifeDialog(
      BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mi Rich Life'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Cómo sería un martes ordinario de tu vida si el dinero no fuera un problema?',
              style: TextStyle(fontSize: 13),
            ),
            const Gap(12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Ej: Trabajar desde casa, viajar 2 meses al año, pagar el colegio de mis hijos...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.dispose();
              ctx.pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              ctx.pop();
              ctrl.dispose();
              if (text.isNotEmpty) {
                await ref
                    .read(authProvider.notifier)
                    .updateProfile(richLifeDescription: text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tema de la app'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('🌙 Oscuro'),
              value: ThemeMode.dark,
              groupValue: current,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setTheme(v!);
                ctx.pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('☀️ Claro'),
              value: ThemeMode.light,
              groupValue: current,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setTheme(v!);
                ctx.pop();
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('📱 Sistema'),
              value: ThemeMode.system,
              groupValue: current,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setTheme(v!);
                ctx.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notificaciones'),
        content: const Text(
          'Las notificaciones del Ritual Quincenal se configuran según tu '
          'frecuencia de pago. Asegúrate de que ElenaCash tenga permisos '
          'de notificación en la configuración de tu dispositivo.',
        ),
        actions: [
          ElevatedButton(
              onPressed: () => ctx.pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Future<void> _exportData(
      BuildContext context, WidgetRef ref, String currency) async {
    final plan =
        ref.read(consciousPlanWatchProvider).asData?.value;
    final fastlane =
        ref.read(fastLaneEngineProvider).asData?.value;
    final debts = ref.read(debtsWatchProvider).asData?.value ?? [];
    final goals = ref.read(savingsGoalsProvider).asData?.value ?? [];

    final buf = StringBuffer();
    buf.writeln('=== ELENACASH — Mis datos financieros ===');
    buf.writeln('Exportado: ${DateTime.now().toString().substring(0, 16)}');
    buf.writeln();

    if (plan != null) {
      buf.writeln('── Plan Consciente ──────────────────');
      buf.writeln(
          'Ingreso mensual neto: ${CurrencyFormatter.format(plan.monthlyNetIncome, currency)}');
      buf.writeln(
          'Gastos Fijos (${plan.fixedCostsPct.toStringAsFixed(0)}%): ${CurrencyFormatter.format(plan.fixedCostsBudget, currency)}');
      buf.writeln(
          'Ahorro (${plan.savingsPct.toStringAsFixed(0)}%): ${CurrencyFormatter.format(plan.savingsBudget, currency)}');
      buf.writeln(
          'Inversiones (${plan.investmentsPct.toStringAsFixed(0)}%): ${CurrencyFormatter.format(plan.investmentsBudget, currency)}');
      buf.writeln(
          'Gasto Libre (${plan.guiltFreePct.toStringAsFixed(0)}%): ${CurrencyFormatter.format(plan.guiltFreeBudget, currency)}');
      buf.writeln();
    }

    if (fastlane != null) {
      final branches = fastlane.moneyTreeBranches.where((b) => b.isActive);
      buf.writeln('── Árbol del Dinero ─────────────────');
      buf.writeln('FastLane Score: ${fastlane.fastLaneScore}/100');
      buf.writeln(
          'Ingreso pasivo total: ${CurrencyFormatter.format(fastlane.passiveIncomeMonthly, currency)}/mes');
      for (final b in branches) {
        buf.writeln(
            '  • ${b.label}: ${CurrencyFormatter.format(b.monthlyAmount, currency)}/mes');
      }
      buf.writeln();
    }

    if (debts.isNotEmpty) {
      buf.writeln('── Deudas ───────────────────────────');
      for (final d in debts) {
        buf.writeln(
            '  • ${d.name}: ${CurrencyFormatter.format(d.currentBalance, currency)} al ${d.interestRate.toStringAsFixed(1)}% E.A.');
      }
      buf.writeln();
    }

    if (goals.isNotEmpty) {
      buf.writeln('── Metas de Ahorro ──────────────────');
      for (final g in goals) {
        buf.writeln(
            '  • ${g.name}: ${CurrencyFormatter.format(g.currentAmount, currency)} de ${CurrencyFormatter.format(g.targetAmount, currency)} (${(g.progressPct * 100).toStringAsFixed(0)}%)');
      }
      buf.writeln();
    }

    buf.writeln('Generado con ElenaCash · Tu Sistema Operativo Financiero');

    await Share.share(buf.toString());
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
          TextButton(
              onPressed: () => ctx.pop(), child: const Text('Cancelar')),
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

  String _currencyLabel(String code) => switch (code) {
        'COP' => '🇨🇴 Peso Colombiano (COP)',
        'USD' => '🇺🇸 Dólar (USD)',
        'MXN' => '🇲🇽 Peso Mexicano (MXN)',
        'CLP' => '🇨🇱 Peso Chileno (CLP)',
        'PEN' => '🇵🇪 Sol Peruano (PEN)',
        _ => code,
      };
}

// ── Section Header ─────────────────────────────────────────────────

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

// ── Settings Tile ──────────────────────────────────────────────────

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
            Text(value!,
                style: const TextStyle(
                    color: AppColors.textSecondaryDark, fontSize: 13)),
          const Gap(4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondaryDark),
        ],
      ),
      onTap: onTap,
    );
  }
}
