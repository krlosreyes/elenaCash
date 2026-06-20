import 'package:flutter/material.dart';

/// Paleta de colores de ElenaCash.
/// Filosofía: dark-first, colores que transmiten confianza y crecimiento.
abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────
  static const backgroundDark = Color(0xFF0A0A0A);
  static const surfaceDark = Color(0xFF141414);
  static const cardDark = Color(0xFF1C1C1C);
  static const borderDark = Color(0xFF2A2A2A);

  static const backgroundLight = Color(0xFFF5F5F5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE5E5E5);

  // ── Brand / Primary ───────────────────────────────────
  /// Verde esmeralda: crecimiento, prosperidad
  static const primary = Color(0xFF00D084);
  static const primaryDark = Color(0xFF00A868);
  static const primaryLight = Color(0xFF33DA9D);
  static const primarySurface = Color(0xFF002A1A);

  // ── Accent ───────────────────────────────────────────
  /// Dorado: Fast Lane, aspiración
  static const gold = Color(0xFFFFB800);
  static const goldDark = Color(0xFFCC9200);
  static const goldSurface = Color(0xFF2A2200);

  // ── Cubos del Conscious Plan ─────────────────────────
  static const bucketFixed = Color(0xFF4A9EFF);       // Azul: estabilidad
  static const bucketSavings = Color(0xFF00D084);     // Verde: crecimiento
  static const bucketInvestments = Color(0xFFFFB800); // Dorado: riqueza
  static const bucketFree = Color(0xFFFF6B6B);        // Coral: vida y placer

  static const bucketFixedSurface = Color(0xFF0A1F3A);
  static const bucketSavingsSurface = Color(0xFF002A1A);
  static const bucketInvestmentsSurface = Color(0xFF2A2200);
  static const bucketFreeSurface = Color(0xFF2A1010);

  // ── Fast Lane Levels ─────────────────────────────────
  static const fastLaneSidewalk = Color(0xFF6B7280);   // Gris: sin rumbo
  static const fastLaneSlow = Color(0xFF4A9EFF);        // Azul: vía lenta
  static const fastLaneFast = Color(0xFFFFB800);        // Dorado: vía rápida

  // ── Semantic ─────────────────────────────────────────
  static const success = Color(0xFF00D084);
  static const warning = Color(0xFFFFB800);
  static const error = Color(0xFFFF4444);
  static const info = Color(0xFF4A9EFF);

  // ── Text ─────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const textTertiaryDark = Color(0xFF6B7280);
  static const textPrimaryLight = Color(0xFF0A0A0A);
  static const textSecondaryLight = Color(0xFF374151);
  static const textTertiaryLight = Color(0xFF9CA3AF);

  // ── Money Tree ───────────────────────────────────────
  static const treeActive = Color(0xFF00D084);
  static const treePassive = Color(0xFFFFB800);
  static const treeTrunk = Color(0xFF8B6914);
}
