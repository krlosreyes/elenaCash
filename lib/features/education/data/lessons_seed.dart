import '../domain/entities/lesson_entity.dart';

/// Lecciones semilla — las primeras 20 lecciones integradas en el build.
/// Las adicionales se cargan desde Firestore (colección: education/).
final List<LessonEntity> seedLessons = [
  // ── Semana 1: Sin Rumbo ───────────────────────────────────────────
  LessonEntity(
    id: 'w1_l1_sin_rumbo',
    title: '¿Estás Sin Rumbo financiero sin saberlo?',
    slug: 'sin-rumbo-diagnostico',
    source: LessonSource.demarco,
    category: LessonCategory.mindset,
    order: 1,
    readingSeconds: 90,
    keyTakeaway: 'Estar "sin rumbo" no es falta de dinero — es falta de sistema.',
    content: '''
## El diagnóstico que nadie quiere hacer

MJ DeMarco describe tres tipos de personas con el dinero:

**El Sin Rumbo:** Vive el hoy, sin plan. "Si tengo plata, gasto. Si no, me endeudo." El dinero llega y desaparece. No es maldad — es ausencia de sistema.

**La Vía Lenta:** Trabaja duro, ahorra el 10%, espera 40 años. El problema matemático: si ahorras el 10% de tu ingreso, necesitas 9 años de trabajo para tener 1 año de ahorro. A los 65 "llegaste".

**La Vía Rápida:** Construye sistemas que generan valor para muchas personas. El dinero trabaja para ti, no al revés.

La mayoría de personas está en el Sin Rumbo *creyendo* que está en la Vía Lenta.

**¿En cuál estás tú?**
''',
  ),

  LessonEntity(
    id: 'w1_l2_bucle',
    title: 'Tu cerebro y el dinero: el bucle secreto',
    slug: 'bucle-habito-dinero',
    source: LessonSource.duhigg,
    category: LessonCategory.habits,
    order: 2,
    readingSeconds: 100,
    keyTakeaway: 'El 40% de tus decisiones financieras no son decisiones — son hábitos.',
    content: '''
## El experimento de las ratas

Charles Duhigg describe un experimento: ratas en un laberinto. La primera vez, su cerebro trabajaba al máximo — procesando todo. Después de repetirlo cientos de veces, su actividad cerebral *bajó casi a cero*. El camino se volvió automático.

Nosotros somos esas ratas.

**El Bucle del Hábito:**
1. **Señal (Cue):** Un disparador — estrés, aburrimiento, llega el pago
2. **Rutina:** La acción automática — comprar, gastar, ignorar
3. **Recompensa:** El alivio, la dopamina, la satisfacción inmediata

El 40% de lo que haces con tu dinero no es una decisión consciente. Es un hábito que se instaló sin que lo notaras.

La buena noticia: **los hábitos se pueden reemplazar**. No eliminar — reemplazar. La señal y la recompensa quedan. La rutina cambia.
''',
  ),

  LessonEntity(
    id: 'w1_l3_sistema',
    title: 'Por qué la fuerza de voluntad no funciona',
    slug: 'fuerza-voluntad-mito',
    source: LessonSource.sethi,
    category: LessonCategory.system,
    order: 3,
    readingSeconds: 85,
    keyTakeaway: 'No necesitas más disciplina. Necesitas un sistema mejor.',
    content: '''
## El error que comete todo el mundo

"Este mes sí voy a controlar mis gastos." — Dura dos semanas.

Ramit Sethi dice algo radical: **la fuerza de voluntad es un recurso finito y agotable**. Usarla para controlar gastos es como usar un balde para vaciar un barco que tiene un hueco.

La solución no es más disciplina. Es un sistema que hace las cosas correctas *automáticamente*, sin que tengas que pensar.

**La diferencia:**
- Sistema malo: "Voy a acordarme de transferir al ahorro este mes"
- Sistema bueno: El ahorro se transfiere *automáticamente* el día del pago, antes de que puedas gastarlo

Starbucks no le pide a sus empleados que "sean amables cuando estén de mal humor". Les enseña una *rutina* específica para esos momentos. El comportamiento correcto se vuelve automático.

Eso es lo que hacemos con ElenaCash.
''',
  ),

  LessonEntity(
    id: 'w1_l4_rich_life',
    title: '¿Qué es una vida rica para TI?',
    slug: 'definir-rich-life',
    source: LessonSource.sethi,
    category: LessonCategory.richLife,
    order: 4,
    readingSeconds: 95,
    keyTakeaway: 'El dinero no es el destino. Es el vehículo. Tú decides a dónde.',
    content: '''
## La pregunta que nadie te hace

Todos los libros de finanzas te dicen *cómo* manejar el dinero. Casi ninguno te pregunta *para qué*.

Ramit Sethi tiene un concepto llamado **Rich Life** — tu vida rica. Y la clave es que es completamente personal.

Para alguien, una vida rica es viajar tres meses al año sin mirar el precio. Para otro, es poder pagar el colegio de sus hijos en el mejor lugar. Para otro, es simplemente llegar a fin de mes sin ansiedad.

**No hay respuesta correcta.** El error es adoptar la definición de riqueza de alguien más.

Las personas en el Sin Rumbo persiguen la riqueza que ven en redes sociales — carros, ropa, viajes para mostrar. Esa riqueza es una trampa.

**La pregunta correcta:** Si el dinero no fuera un problema, ¿cómo sería un martes ordinario de tu vida?

Tu respuesta a esa pregunta es tu Rich Life. Todo lo demás es el camino.
''',
  ),

  LessonEntity(
    id: 'w1_l5_cuatro_cubos',
    title: 'Los 4 cubos: el sistema más simple que existe',
    slug: 'cuatro-cubos-conscious-plan',
    source: LessonSource.sethi,
    category: LessonCategory.system,
    order: 5,
    readingSeconds: 110,
    keyTakeaway: 'Divide tu ingreso en 4 cubos. El sistema hace el resto.',
    content: '''
## El Plan de Gasto Consciente

Ramit Sethi llama a esto el **Conscious Spending Plan**. No es un presupuesto (los presupuestos generan culpa). Es una *arquitectura* de tu dinero.

**Los 4 cubos:**

🏠 **Gastos Fijos (50–60%):** Renta, servicios, seguros, deudas mínimas, mercado, transporte. Todo lo que *debes* pagar.

🏦 **Ahorro (5–10%):** Fondo de emergencia, metas de corto plazo (vacaciones, gadgets, imprevistos).

📈 **Inversiones (5–10%):** Largo plazo. AFORE/pensión voluntaria, fondos, CDTs. Dinero que no tocarás en 10+ años.

🎉 **Gasto Libre (20–35%):** Lo que quieras — restaurantes, ropa, entretenimiento. Sin culpa, sin justificaciones.

**La clave:** los porcentajes se configuran una vez. Luego se automatizan. Luego te olvidas.

El Gasto Libre no es un lujo — es parte del sistema. Si no lo incluyes, el sistema falla porque la privación no es sostenible.
''',
  ),

  // ── Semana 2: El Sistema ─────────────────────────────────────
  LessonEntity(
    id: 'w2_l1_automatizacion',
    title: 'El día que configuras tu sistema para siempre',
    slug: 'automatizacion-financiera',
    source: LessonSource.sethi,
    category: LessonCategory.system,
    order: 6,
    readingSeconds: 120,
    keyTakeaway: 'Configura una vez. El sistema trabaja para siempre.',
    content: '''
## El objetivo es no tener que pensar

Ramit Sethi describe el ideal financiero como un sistema tan bien configurado que *casi no necesitas pensar en dinero*. El dinero fluye solo: entra, se distribuye, trabaja.

**El flujo de automatización:**

```
Quincena → Cuenta principal
     ↓ (automático, mismo día)
 ├── Auto-pago TC y deudas
 ├── Auto-transferencia → Ahorro
 └── Auto-inversión → Fondo
     ↓
  Lo que queda → Gastos del mes
```

**¿Por qué funciona?**

1. Elimina la decisión diaria ("¿transfiero hoy o la próxima quincena?")
2. El ahorro ocurre antes de que puedas gastarlo
3. Las inversiones nunca dependen de si "hay dinero extra"
4. El Gasto Libre está definido — no hay culpa

El objetivo de ElenaCash es ayudarte a configurar este sistema en 20 minutos. Luego solo lo revisas 5 minutos cada quincena.
''',
  ),

  LessonEntity(
    id: 'w2_l2_habito_bisagra',
    title: 'El efecto dominó del hábito correcto',
    slug: 'habito-bisagra-efecto',
    source: LessonSource.duhigg,
    category: LessonCategory.habits,
    order: 7,
    readingSeconds: 95,
    keyTakeaway: 'Un hábito bisagra cambia todo lo demás en cadena.',
    content: '''
## Lisa y el desierto

En el libro El Poder de los Hábitos, Charles Duhigg cuenta la historia de Lisa Allen. Tenía deudas, fumaba, comía mal, sin empleo estable.

Un día decidió cambiar *un solo hábito*: dejar de fumar. Solo eso.

En 12 meses: dejó de fumar, perdió 27 kilos, pagó todas sus deudas, consiguió trabajo estable, empezó un máster.

Los científicos la estudiaron y encontraron algo extraordinario: cambiar ese *un hábito* reorganizó todo lo demás en su cerebro.

**Los hábitos bisagra** son aquellos que, al cambiar, producen una reacción en cadena en otras áreas de la vida.

Para las finanzas, el hábito bisagra universal es simple: **revisar tu sistema cada quincena**. 5 minutos.

Cuando ese hábito se instala, el cerebro empieza a procesar el dinero diferente. Las otras decisiones mejoran solas.
''',
  ),

  LessonEntity(
    id: 'w2_l3_via_lenta_math',
    title: 'Las matemáticas que nadie te enseñó',
    slug: 'matematicas-via-lenta',
    source: LessonSource.demarco,
    category: LessonCategory.fastlane,
    order: 8,
    readingSeconds: 105,
    isPremium: true,
    keyTakeaway: 'La Vía Lenta intercambia tiempo por dinero. No hay escape matemático.',
    content: '''
## El problema con "trabaja duro y ahorra"

DeMarco plantea una ecuación brutal:

Si ganas \$5,000,000 COP/mes y ahorras el 10% = \$500,000/mes de ahorro.

Para acumular \$1,000,000,000 COP (suficiente para retirarse cómodamente): necesitas 2,000 meses = **166 años**.

Incluso con el interés compuesto — con retornos del 8% anual — tardarías **35–40 años**.

**El problema no es el porcentaje de ahorro. Es la fuente del ingreso.**

Si tu ingreso está atado a tu tiempo (empleo), el crecimiento es *lineal*. Solo puedes trabajar X horas al día.

La Vía Rápida rompe esa ecuación: crea sistemas que generan valor para *miles* de personas simultáneamente. El ingreso se vuelve *exponencial*, desligado de tu tiempo.

**ElenaCash Fastlane Score** mide qué porcentaje de tu ingreso ya no depende de tu tiempo. Ese número es tu verdadero indicador de libertad financiera.
''',
  ),

  LessonEntity(
    id: 'w2_l4_arbol_dinero',
    title: 'Planta tu primera rama',
    slug: 'arbol-dinero-primera-rama',
    source: LessonSource.demarco,
    category: LessonCategory.fastlane,
    order: 9,
    isPremium: true,
    readingSeconds: 100,
    keyTakeaway: 'El Árbol del Dinero crece lento. Pero una vez crece, da frutos para siempre.',
    content: '''
## El concepto del Árbol del Dinero

DeMarco usa esta metáfora: tu empleo es el tronco del árbol. Estable, pero limitado por su altura.

Las ramas son fuentes de ingreso que no requieren tu tiempo completo. Pequeñas al principio. Pero cada rama que crece *sin ti* cambia la ecuación.

**Tipos de ramas (del libro):**
- 🎬 **Contenido:** Un video, artículo, o curso que generó ingresos mientras dormías
- 💻 **Software/Apps:** Un producto digital que se vende mil veces sin costo adicional
- 📊 **Inversiones:** Un CDT, fondo, o acción que genera intereses
- 🏠 **Renta:** Una propiedad o producto físico que genera ingresos pasivos
- 🤝 **Freelance:** Proyectos adicionales fuera del empleo principal

La diferencia entre freelance (rama semi-pasiva) e inversión (rama pasiva): el freelance todavía requiere tu tiempo. La inversión no.

La primera rama es la más difícil. La segunda es más fácil. La décima... crece sola.

**¿Cuál podría ser tu primera rama?**
''',
  ),

  LessonEntity(
    id: 'w2_l5_reemplazar_rutina',
    title: 'Cómo reemplazar un hábito malo (sin fuerza de voluntad)',
    slug: 'reemplazar-rutina-habito',
    source: LessonSource.duhigg,
    category: LessonCategory.habits,
    order: 10,
    readingSeconds: 95,
    keyTakeaway: 'Mantén la señal y la recompensa. Solo cambia la rutina.',
    content: '''
## La Regla de Oro del Cambio de Hábitos

Duhigg descubrió algo crucial: **no puedes eliminar un hábito. Solo puedes reemplazarlo**.

La estructura del bucle (Señal → Rutina → Recompensa) no desaparece. Pero la *rutina* sí puede cambiar.

**Ejemplo real:**

❌ **Bucle malo:**
- Señal: Estrés al llegar del trabajo
- Rutina: Abrir app de delivery, pedir comida
- Recompensa: Alivio, comodidad, dopamina

✅ **Bucle nuevo:**
- Señal: Estrés al llegar del trabajo (igual)
- Rutina: Abrir ElenaCash, ver el progreso de tu meta, decidir si usar Gasto Libre
- Recompensa: Alivio + sensación de control + dopamina (igual de real)

La clave: la señal y la recompensa SON LAS MISMAS. Solo cambió la rutina del medio.

**El Modo Pausa de 24h de ElenaCash** usa exactamente este principio: cuando tienes el antojo (señal), pausas la compra impulsiva (rutina vieja) y ves el progreso de tu meta (nueva rutina). La recompensa — sentirte bien — sigue ahí.
''',
  ),
];
