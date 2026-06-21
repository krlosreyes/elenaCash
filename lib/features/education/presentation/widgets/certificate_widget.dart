import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/quiz_entity.dart';

/// Sección del certificado que aparece en EducationHomeScreen cuando
/// el usuario completa todos los quizzes disponibles con ≥70%.
///
/// Si las condiciones no se cumplen, muestra el progreso hacia el certificado.
class CertificateSection extends StatelessWidget {
  final List<QuizEntity> quizzes;
  final List<QuizAttemptEntity> attempts;

  const CertificateSection({
    super.key,
    required this.quizzes,
    required this.attempts,
  });

  /// Devuelve el mejor intento por quiz.
  Map<String, QuizAttemptEntity> get _bestAttemptByQuiz {
    final map = <String, QuizAttemptEntity>{};
    for (final attempt in attempts) {
      final existing = map[attempt.quizId];
      if (existing == null || attempt.percentage > existing.percentage) {
        map[attempt.quizId] = attempt;
      }
    }
    return map;
  }

  /// ¿Cuántos quizzes pasados con ≥70%?
  int _passedCount(Map<String, QuizAttemptEntity> best) {
    return best.values.where((a) => a.percentage >= 0.7).length;
  }

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) return const SizedBox();

    final best = _bestAttemptByQuiz;
    final passed = _passedCount(best);
    final total = quizzes.length;
    final earned = passed == total;

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🎓 Certificado', style: theme.textTheme.titleLarge)
            .animate().fadeIn(delay: 500.ms),
        const Gap(4),
        Text(
          earned
              ? '¡Completaste todos los quizzes con ≥70%!'
              : 'Completa todos los quizzes con ≥70% para obtenerlo.',
          style: theme.textTheme.bodySmall,
        ).animate().fadeIn(delay: 520.ms),
        const Gap(12),

        if (earned)
          _EarnedCertificate(quizzes: quizzes, best: best)
              .animate()
              .fadeIn(delay: 540.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1))
        else
          _CertificateProgress(
            quizzes: quizzes,
            best: best,
            passed: passed,
          ).animate().fadeIn(delay: 540.ms),
      ],
    );
  }
}

// ── Certificado ganado ────────────────────────────────────────────────

class _EarnedCertificate extends StatefulWidget {
  final List<QuizEntity> quizzes;
  final Map<String, QuizAttemptEntity> best;

  const _EarnedCertificate({required this.quizzes, required this.best});

  @override
  State<_EarnedCertificate> createState() => _EarnedCertificateState();
}

class _EarnedCertificateState extends State<_EarnedCertificate> {
  final _repaintKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capturar a 3x para alta resolución
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/certificado_elenacash.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '¡Obtuve mi Certificado de Literacy Financiera en ElenaCash! 🎓💰',
      );
    } catch (_) {
      // Silencioso — el share puede fallar en simuladores
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.best.values
        .map((a) => a.completedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Column(
      children: [
        // ── El certificado (capturable) ────────────────────────────
        RepaintBoundary(
          key: _repaintKey,
          child: _CertificateCard(
            quizzes: widget.quizzes,
            dateStr: dateStr,
          ),
        ),
        const Gap(16),

        // ── Botón de compartir ─────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_rounded, size: 18),
            label: Text(_sharing ? 'Generando...' : 'Compartir certificado'),
          ),
        ),
      ],
    );
  }
}

// ── Card visual del certificado ───────────────────────────────────────

class _CertificateCard extends StatelessWidget {
  final List<QuizEntity> quizzes;
  final String dateStr;

  const _CertificateCard({required this.quizzes, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002A1A), Color(0xFF001A10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sello
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              color: AppColors.goldSurface,
            ),
            child: const Text('🎓', style: TextStyle(fontSize: 36)),
          ),
          const Gap(16),

          // Título
          const Text(
            'CERTIFICADO',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Gap(4),
          const Text(
            'de Literacy Financiera',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),

          // Línea decorativa
          Row(
            children: [
              const Expanded(
                child: Divider(color: AppColors.gold, thickness: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.star_rounded,
                    color: AppColors.gold.withOpacity(0.7), size: 14),
              ),
              const Expanded(
                child: Divider(color: AppColors.gold, thickness: 0.5),
              ),
            ],
          ),
          const Gap(14),

          // Texto cuerpo
          Text(
            'Este certificado acredita que su portador ha demostrado '
            'dominio en los fundamentos de finanzas personales.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),

          // Topics completados
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: quizzes.map((q) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '${q.emoji} ${q.topic.label}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
          const Gap(16),

          // Firma y fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ElenaCash',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Tu Sistema Operativo Financiero',
                    style: TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Fecha de obtención',
                    style: TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Progreso hacia el certificado ─────────────────────────────────────

class _CertificateProgress extends StatelessWidget {
  final List<QuizEntity> quizzes;
  final Map<String, QuizAttemptEntity> best;
  final int passed;

  const _CertificateProgress({
    required this.quizzes,
    required this.best,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = quizzes.length;
    final progress = total > 0 ? passed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 20)),
              const Gap(8),
              Text(
                '$passed / $total quizzes con ≥70%',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.goldSurface,
              color: AppColors.gold,
              minHeight: 6,
            ),
          ),
          const Gap(10),
          // Quiz por quiz
          ...quizzes.map((q) {
            final attempt = best[q.id];
            final pct = attempt?.percentage ?? 0.0;
            final ok = pct >= 0.7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: ok ? AppColors.primary : AppColors.textTertiaryDark,
                    size: 16,
                  ),
                  const Gap(8),
                  Text(
                    '${q.emoji} ${q.title}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ok ? null : AppColors.textSecondaryDark,
                    ),
                  ),
                  if (attempt != null) ...[
                    const Spacer(),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: ok ? AppColors.primary : AppColors.textTertiaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
