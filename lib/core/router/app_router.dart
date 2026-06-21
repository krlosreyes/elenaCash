import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_shell_screen.dart';
import '../../features/conscious_plan/presentation/screens/conscious_plan_screen.dart';
import '../../features/habit_engine/presentation/screens/habit_bisagra_screen.dart';
import '../../features/habit_engine/presentation/screens/habit_loop_designer_screen.dart';
import '../../features/habit_engine/presentation/screens/craving_pause_screen.dart';
import '../../features/fastlane_engine/presentation/screens/money_tree_screen.dart';
import '../../features/fastlane_engine/presentation/screens/fastlane_score_screen.dart';
import '../../features/debts/presentation/screens/debts_list_screen.dart';
import '../../features/debts/presentation/screens/debt_detail_screen.dart';
import '../../features/savings_goals/presentation/screens/goals_screen.dart';
import '../../features/monthly_review/presentation/screens/monthly_review_screen.dart';
import '../../features/education/presentation/screens/daily_lesson_screen.dart';
import '../../features/education/presentation/screens/education_home_screen.dart';
import '../../features/education/presentation/screens/quiz_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/subscription_screen.dart';
import '../../shared/providers/firebase_providers.dart';

part 'app_router.g.dart';

// ── Route Names ───────────────────────────────────────────────────
abstract class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';
  static const consciousPlan = '/conscious-plan';
  static const habitBisagra = '/habit/bisagra';
  static const habitLoopDesigner = '/habit/loop-designer';
  static const cravingPause = '/habit/craving-pause';
  static const moneyTree = '/fastlane/money-tree';
  static const fastlaneScore = '/fastlane/score';
  static const debts = '/debts';
  static const debtDetail = '/debts/:id';
  static const goals = '/goals';
  static const monthlyReview = '/monthly-review';
  static const education = '/education';
  static const dailyLesson = '/education/lesson/:id';
  static const quiz = '/education/quiz/:id';
  static const settings = '/settings';
  static const subscription = '/settings/subscription';
}

@riverpod
GoRouter appRouter(Ref ref) {
  // El router se crea UNA sola vez. Se refresca (re-evalúa redirects)
  // cuando cambia el estado de auth o los datos del usuario.
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final isLoggedIn = firebaseUser != null;
      final location = state.matchedLocation;

      final isOnAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isOnOnboarding = location.startsWith(AppRoutes.onboarding);

      // No autenticado → forzar login
      if (!isLoggedIn && !isOnAuthRoute) return AppRoutes.login;
      if (!isLoggedIn) return null;

      // Autenticado: leer datos del usuario (ya cargados en el provider)
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.asData?.value;

      if (isOnAuthRoute) {
        // Si los datos aún no cargaron, esperar (no redirigir todavía)
        if (user == null) return null;
        // Onboarding pendiente → ir al onboarding
        if (!user.onboardingCompleted) return AppRoutes.onboarding;
        return AppRoutes.dashboard;
      }

      // Si está en onboarding pero ya lo completó → dashboard
      if (isOnOnboarding && user?.onboardingCompleted == true) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ── Auth Routes ─────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (ctx, state) => const RegisterScreen(),
      ),

      // ── Onboarding ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (ctx, state) => const OnboardingShellScreen(),
      ),

      // ── Main Shell ──────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (ctx, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.consciousPlan,
            name: 'conscious-plan',
            builder: (ctx, state) => const ConsciousPlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.debts,
            name: 'debts',
            builder: (ctx, state) => const DebtsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'debt-detail',
                builder: (ctx, state) => DebtDetailScreen(
                  debtId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.goals,
            name: 'goals',
            builder: (ctx, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: AppRoutes.education,
            name: 'education',
            builder: (ctx, state) => const EducationHomeScreen(),
            routes: [
              GoRoute(
                path: 'lesson/:id',
                name: 'daily-lesson',
                builder: (ctx, state) => DailyLessonScreen(
                  lessonId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'quiz/:id',
                name: 'quiz',
                builder: (ctx, state) => QuizScreen(
                  quizId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (ctx, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'subscription',
                name: 'subscription',
                builder: (ctx, state) => const SubscriptionScreen(),
              ),
            ],
          ),

          // ── FastLane Engine (dentro del shell → siempre con nav bar) ──
          GoRoute(
            path: AppRoutes.moneyTree,
            name: 'money-tree',
            builder: (ctx, state) => const MoneyTreeScreen(),
          ),
          GoRoute(
            path: AppRoutes.fastlaneScore,
            name: 'fastlane-score',
            builder: (ctx, state) => const FastlaneScoreScreen(),
          ),
        ],
      ),

      // ── Habit Engine (modal routes, sin nav bar) ─────────
      GoRoute(
        path: AppRoutes.habitBisagra,
        name: 'habit-bisagra',
        builder: (ctx, state) => const HabitBisagraScreen(),
      ),
      GoRoute(
        path: AppRoutes.habitLoopDesigner,
        name: 'habit-loop-designer',
        builder: (ctx, state) => const HabitLoopDesignerScreen(),
      ),
      GoRoute(
        path: AppRoutes.cravingPause,
        name: 'craving-pause',
        builder: (ctx, state) => const CravingPauseScreen(),
      ),

      // ── Monthly Review ──────────────────────────────────
      GoRoute(
        path: AppRoutes.monthlyReview,
        name: 'monthly-review',
        builder: (ctx, state) => const MonthlyReviewScreen(),
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404 — Página no encontrada'),
            TextButton(
              onPressed: () => ctx.go(AppRoutes.dashboard),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );

  // Refrescar el router (re-evalúa redirects) cuando cambia auth o el usuario
  ref.listen(authStateProvider, (_, __) => router.refresh());
  ref.listen(currentUserProvider, (_, __) => router.refresh());
  ref.onDispose(router.dispose);

  return router;
}

/// Shell principal con BottomNavigationBar
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => _onTabTap(context, idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_rounded), label: 'Ingresos'),
          BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Aprender'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }

  int _indexForLocation(String location) {
    if (location.startsWith(AppRoutes.dashboard)) return 0;
    if (location.startsWith(AppRoutes.consciousPlan) || location.startsWith(AppRoutes.debts) || location.startsWith(AppRoutes.goals)) return 1;
    if (location.startsWith(AppRoutes.moneyTree) || location.startsWith(AppRoutes.fastlaneScore)) return 2;
    if (location.startsWith(AppRoutes.education)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.dashboard);
      case 1: context.go(AppRoutes.consciousPlan);
      case 2: context.go(AppRoutes.moneyTree);
      case 3: context.go(AppRoutes.education);
      case 4: context.go(AppRoutes.settings);
    }
  }
}
