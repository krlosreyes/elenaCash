# Sprint 1 — Coach Financiero
**Fecha:** 2026-06-21  
**Estado:** Implementado ✅

---

## Contexto estratégico

La hipótesis central de ElenaCash post-Sprint 1 es que la retención a largo plazo no viene de **tracking** (Mint, YNAB hacen eso) sino de **coaching**: enseñar, contextualizar y hacer que el usuario tome mejores decisiones financieras. Referencia: Cleo ($280M ARR, 20x engagement vs trackers clásicos).

Colombia tiene un score de literacy financiera de 53.5/100 (OCDE) — hay un mercado masivo de educación pendiente.

---

## SPEC-A: TRM Widget — Mercados en tiempo real

### Problema que resuelve
El usuario colombiano tiene gastos en USD (Netflix, Spotify, AWS, suscripciones) pero no tiene visibilidad de cómo el tipo de cambio afecta su bolsillo hoy.

### Solución
Widget `TRMWidget` en el Dashboard que muestra:
- **USD/COP** — tasa actual con % de cambio vs ayer (▲ o ▼)
- **EUR/COP** — tasa de referencia
- **Impacto contextual** — "Netflix hoy: $XXK" (cálculo en tiempo real de 17 USD en COP)
- **Banner de alerta** si el dólar sube/baja más del 1%: "El dólar subió X%. Tus suscripciones en USD cuestan más."

### Fuente de datos
- API: `https://api.frankfurter.dev/v2/latest?base=USD&symbols=COP,EUR`
- Sin API key, sin límite de uso, datos del Banco Central Europeo
- Actualización: cada día hábil ~16:00 CET
- Delta: segunda llamada a `/v2/{ayer}?base=USD&symbols=COP` para calcular % cambio

### Archivos
```
lib/features/market_data/domain/entities/market_rates_entity.dart
lib/features/market_data/presentation/providers/market_data_provider.dart
lib/features/market_data/presentation/providers/market_data_provider.g.dart
lib/features/market_data/presentation/widgets/trm_widget.dart
```

### Integración
- Importado en `dashboard_screen.dart` → `_DashboardContent.build()`
- Posición: entre `_IncomeCard` y los cubos del plan consciente
- Falla gracefully: si la API no responde, `SizedBox.shrink()` (no rompe el dashboard)

---

## SPEC-B: Quiz System — Academia con quizzes y score

### Problema que resuelve
La pestaña "Aprender" tenía lecciones hardcodeadas pero ningún mecanismo de medición ni engagement. El usuario leía y se iba — sin recordar nada, sin incentivo para volver.

### Solución
Sistema de quizzes integrado en la Academia con:
- 3 quizzes semilla sobre temas críticos (presupuesto, inversiones, deudas)
- 5 preguntas por quiz con explicación detallada de cada respuesta
- Sistema de XP: +5 a +35 XP según puntaje (≥90% = 35XP, ≥70% = 25XP, ≥60% = 15XP)
- Badge de puntaje en la tarjeta del quiz si ya fue intentado
- Intentos guardados en Firestore → histórico del usuario

### Entidades
```dart
// QuizEntity — quiz completo
QuizEntity { id, title, description, emoji, questions, topic, xpReward }

// QuizQuestion — pregunta individual
QuizQuestion { id, question, options[4], correctIndex, explanation }

// QuizAttemptEntity — intento guardado
QuizAttemptEntity { quizId, score, totalQuestions, xpEarned, completedAt }
```

### Quizzes semilla
| ID | Título | Tópico | XP |
|----|--------|--------|----|
| `quiz_presupuesto_01` | Plan Consciente | Presupuesto | 25 |
| `quiz_inversiones_01` | Inversiones Básicas | Inversiones | 25 |
| `quiz_deudas_01` | Deudas y Crédito | Deudas | 30 |

### Flujo UX
1. Usuario ve sección "Pon a prueba tu conocimiento" en Education Home
2. Toca un quiz → `QuizScreen` (push, sin nav bar)
3. Pregunta por pregunta: selecciona respuesta → feedback inmediato + explicación
4. Barra de progreso en AppBar
5. Pantalla de resultado: emoji + grade + XP ganado + botones Volver/Reintentar

### Firestore schema
```
users/{userId}/quizAttempts/{autoId}
  quizId: string
  score: int
  totalQuestions: int
  xpEarned: int
  completedAt: Timestamp

users/{userId}/educationProgress/current
  completedQuizzes: string[]   ← nuevo campo, arrayUnion
  totalXP: number              ← increment
```

### Archivos
```
lib/features/education/domain/entities/quiz_entity.dart
lib/features/education/data/quizzes_seed.dart
lib/features/education/presentation/providers/quiz_provider.dart
lib/features/education/presentation/providers/quiz_provider.g.dart
lib/features/education/presentation/screens/quiz_screen.dart
```

### Cambios a archivos existentes
- `education_home_screen.dart` → añadida sección de quizzes + widget `_QuizCard`
- `app_router.dart` → nueva ruta `/education/quiz/:id` → `QuizScreen`

---

## Próximos pasos (Sprint 2)

- [ ] Quizzes desde Firestore (admin puede crear nuevos sin release)
- [ ] Artículos dinámicos en Firestore con editor admin
- [ ] TRM: push notification cuando el dólar sube >2% ("Tu Netflix subió X hoy")
- [ ] Quiz streak: racha de quizzes diarios = bonus XP
- [ ] Leaderboard anónimo de XP (engagement social)
- [ ] Certificado de literacy financiera al completar todos los quizzes
