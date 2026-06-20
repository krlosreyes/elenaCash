/// Constantes globales de la aplicación.
abstract class AppConstants {
  // ── App Info ─────────────────────────────────────────
  static const appName = 'ElenaCash';
  static const appTagline = 'Tu Sistema Operativo Financiero';

  // ── Firestore Collections ─────────────────────────────
  static const colUsers = 'users';
  static const colConsciousPlan = 'consciousPlan';
  static const colMonthlySnapshots = 'monthlySnapshots';
  static const colDebts = 'debts';
  static const colSavingsGoals = 'savingsGoals';
  static const colAutomations = 'automations';
  static const colHabitEngine = 'habitEngine';
  static const colFastlaneEngine = 'fastlaneEngine';
  static const colEducationProgress = 'educationProgress';
  static const colNotificationPrefs = 'notification_prefs';
  static const colEducation = 'education';
  static const colAppConfig = 'app_config';

  // ── Conscious Plan Defaults (%) ───────────────────────
  static const defaultFixedCostsPct = 55.0;
  static const defaultSavingsPct = 7.5;
  static const defaultInvestmentsPct = 7.5;
  static const defaultGuiltFreePct = 30.0;

  // ── Conscious Plan Ranges ─────────────────────────────
  static const fixedCostsMin = 40.0;
  static const fixedCostsMax = 65.0;
  static const savingsMin = 5.0;
  static const savingsMax = 20.0;
  static const investmentsMin = 5.0;
  static const investmentsMax = 20.0;
  static const guiltFreeMin = 10.0;
  static const guiltFreeMax = 40.0;

  // ── Fast Lane Score Thresholds ────────────────────────
  static const fastLaneScoreSidewalk = 0;
  static const fastLaneScoreSlowLane = 25;
  static const fastLaneScoreFastLane = 60;
  static const fastLaneScoreElite = 85;

  // ── Habit Engine ──────────────────────────────────────
  static const keystoneHabitId = 'quincenal_review';
  static const habitLoopDays = 30;
  static const cravingPauseHours = 24;

  // ── Education ────────────────────────────────────────
  static const dailyLessonMinutes = 2;
  static const lessonsPerWeek = 5;

  // ── RevenueCat Product IDs ────────────────────────────
  static const revenueCatApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const revenueCatApiKeyIOS = 'YOUR_REVENUECAT_IOS_KEY';
  static const premiumMonthlyId = 'elenacash_premium_monthly';
  static const premiumAnnualId = 'elenacash_premium_annual';
  static const familyMonthlyId = 'elenacash_family_monthly';

  // ── Currencies ───────────────────────────────────────
  static const defaultCurrency = 'COP';
  static const supportedCurrencies = ['COP', 'USD', 'MXN', 'CLP', 'PEN'];

  // ── UI ───────────────────────────────────────────────
  static const defaultPadding = 20.0;
  static const smallPadding = 12.0;
  static const largePadding = 32.0;
  static const cardRadius = 16.0;
  static const buttonRadius = 12.0;
  static const chipRadius = 8.0;

  // ── Animation Durations ──────────────────────────────
  static const animFast = Duration(milliseconds: 200);
  static const animMedium = Duration(milliseconds: 400);
  static const animSlow = Duration(milliseconds: 700);
  static const animCelebration = Duration(milliseconds: 1200);

  // ── Shared Prefs Keys ────────────────────────────────
  static const prefThemeMode = 'theme_mode';
  static const prefOnboardingDone = 'onboarding_done';
  static const prefLastHabitDate = 'last_habit_date';
  static const prefHabitStreak = 'habit_streak';
  static const prefBiometricEnabled = 'biometric_enabled';
}
