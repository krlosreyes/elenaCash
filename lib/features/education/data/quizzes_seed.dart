import '../domain/entities/quiz_entity.dart';

/// 3 quizzes semilla — disponibles offline, sin Firestore.
/// Tópicos: presupuesto, inversiones, deudas
const List<QuizEntity> seedQuizzes = [
  // ─────────────────────────────────────────────
  // QUIZ 1: PRESUPUESTO (Plan Consciente / Ramit Sethi)
  // ─────────────────────────────────────────────
  QuizEntity(
    id: 'quiz_presupuesto_01',
    title: 'Plan Consciente',
    description: '¿Sabes cómo distribuir tu dinero inteligentemente?',
    emoji: '💰',
    topic: QuizTopic.presupuesto,
    xpReward: 25,
    questions: [
      QuizQuestion(
        id: 'pp_q1',
        question: 'Según el Plan Consciente de Ramit Sethi, ¿cuál es el porcentaje recomendado para Gastos Fijos?',
        options: ['30–40%', '50–60%', '60–70%', '20–30%'],
        correctIndex: 1,
        explanation:
            'Los gastos fijos (renta, servicios, créditos) deben estar entre el 50–60% de tu ingreso neto. Si superan el 60%, tienes un problema estructural.',
      ),
      QuizQuestion(
        id: 'pp_q2',
        question: '¿Qué es el "Gasto Libre" (Guilt-Free Spending)?',
        options: [
          'Dinero que gastas en emergencias',
          'Dinero asignado a inversiones de riesgo',
          'Dinero para gastar en lo que quieras, sin culpa, porque ya cubriste lo importante',
          'Dinero que le debes al gobierno',
        ],
        correctIndex: 2,
        explanation:
            'El Gasto Libre es el dinero que queda DESPUÉS de cubrir gastos fijos, ahorro e inversiones. Puedes gastarlo en lo que quieras sin culpa — por eso se llama así.',
      ),
      QuizQuestion(
        id: 'pp_q3',
        question: 'Si ganas \$5,000,000/mes netos, ¿cuánto debería ir a ahorro según el plan?',
        options: ['\$150,000', '\$250,000–\$500,000', '\$500,000–\$1,000,000', 'Nada — primero invierte'],
        correctIndex: 2,
        explanation:
            'El 10–20% del ingreso neto debe ir a ahorro (\$500K–\$1M sobre \$5M). Este dinero cubre tu fondo de emergencia y metas a mediano plazo.',
      ),
      QuizQuestion(
        id: 'pp_q4',
        question: '¿Cuál es la mayor ventaja de automatizar tus finanzas?',
        options: [
          'Genera más intereses automáticamente',
          'Elimina la fricción y el "olvido" — el sistema trabaja aunque tú no pienses en él',
          'Te permite gastar más sin culpa',
          'Reduce los impuestos que pagas',
        ],
        correctIndex: 1,
        explanation:
            'La automatización elimina la dependencia de la fuerza de voluntad. Cuando el dinero se mueve solo el día del pago, no tienes que recordarlo ni decidirlo — ya está hecho.',
      ),
      QuizQuestion(
        id: 'pp_q5',
        question: '¿Qué debes hacer PRIMERO cuando recibes tu pago?',
        options: [
          'Pagar deudas de tarjeta',
          'Salir a comer para celebrar',
          'Transferir automáticamente a ahorro e inversión antes de gastar',
          'Pagar los servicios del mes',
        ],
        correctIndex: 2,
        explanation:
            'El principio de "págate a ti primero" (Pay Yourself First): antes de pagar a alguien más, mueve tu ahorro e inversión. Lo que queda es lo que puedes gastar.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────
  // QUIZ 2: INVERSIONES (Fastlane / pasivos)
  // ─────────────────────────────────────────────
  QuizEntity(
    id: 'quiz_inversiones_01',
    title: 'Inversiones Básicas',
    description: 'Aprende a hacer que tu dinero trabaje para ti.',
    emoji: '📈',
    topic: QuizTopic.inversiones,
    xpReward: 25,
    questions: [
      QuizQuestion(
        id: 'inv_q1',
        question: '¿Qué es el interés compuesto?',
        options: [
          'El interés que paga el banco por tu cuenta de nómina',
          'Ganar intereses sobre tus intereses anteriores — tu dinero crece exponencialmente con el tiempo',
          'Un tipo de seguro de inversión',
          'Una tarifa bancaria mensual',
        ],
        correctIndex: 1,
        explanation:
            'Con interés compuesto, los intereses que ganas se suman al capital y también generan intereses. Es el mecanismo más poderoso para crear riqueza a largo plazo.',
      ),
      QuizQuestion(
        id: 'inv_q2',
        question: 'Según la regla del 72, ¿en cuántos años se duplica tu dinero al 8% anual?',
        options: ['5 años', '9 años', '12 años', '15 años'],
        correctIndex: 1,
        explanation:
            'La regla del 72: divide 72 entre la tasa de interés. 72 ÷ 8 = 9 años. Es una forma rápida de estimar cuándo se duplica una inversión.',
      ),
      QuizQuestion(
        id: 'inv_q3',
        question: '¿Qué es un CDT (Certificado de Depósito a Término)?',
        options: [
          'Una acción de bolsa colombiana',
          'Un instrumento donde prestas dinero a un banco por un plazo fijo y recibes una tasa pactada',
          'Una cuenta de ahorro con retiros libres',
          'Un fondo de pensiones obligatorio',
        ],
        correctIndex: 1,
        explanation:
            'El CDT es la inversión más simple en Colombia: depositas dinero en un banco por 30, 60, 90 días o más, y recibes una tasa de interés fija. Es seguro y predecible.',
      ),
      QuizQuestion(
        id: 'inv_q4',
        question: '¿Cuál es la diferencia entre un ingreso activo y uno pasivo?',
        options: [
          'El activo es legal, el pasivo no',
          'El activo requiere tu tiempo cada vez; el pasivo sigue generando dinero aunque no trabajes',
          'El activo es mayor en monto; el pasivo es menor',
          'No hay diferencia real',
        ],
        correctIndex: 1,
        explanation:
            'Ingreso activo: vendes tu tiempo (salario, honorarios). Ingreso pasivo: el activo sigue generando sin tu presencia continua (CDT, dividendos, arriendo, regalías).',
      ),
      QuizQuestion(
        id: 'inv_q5',
        question: '¿Por qué la inflación es un riesgo para el dinero en cuenta de ahorros?',
        options: [
          'El banco puede quebrar',
          'Si la tasa de inflación supera el rendimiento, tu dinero pierde poder adquisitivo real',
          'El gobierno puede congelar la cuenta',
          'No es un riesgo — las cuentas de ahorro siempre ganan más que la inflación',
        ],
        correctIndex: 1,
        explanation:
            'Si la inflación en Colombia es del 8% anual y tu cuenta de ahorros rinde el 3%, en términos reales estás perdiendo el 5% del poder de compra cada año.',
      ),
    ],
  ),

  // ─────────────────────────────────────────────
  // QUIZ 3: DEUDAS (Estrategia de pago)
  // ─────────────────────────────────────────────
  QuizEntity(
    id: 'quiz_deudas_01',
    title: 'Deudas y Crédito',
    description: 'Entiende cómo salir de las deudas más rápido.',
    emoji: '💳',
    topic: QuizTopic.deudas,
    xpReward: 30,
    questions: [
      QuizQuestion(
        id: 'deu_q1',
        question: '¿Cuál es la diferencia entre el método Avalancha y el método Bola de Nieve para pagar deudas?',
        options: [
          'Son exactamente iguales',
          'Avalancha: pagas primero la deuda de mayor tasa. Bola de Nieve: pagas primero la de menor saldo',
          'Bola de Nieve: pagas primero la de mayor tasa. Avalancha: pagas la de menor saldo',
          'Avalancha es para tarjetas; Bola de Nieve para créditos hipotecarios',
        ],
        correctIndex: 1,
        explanation:
            'Avalancha = más eficiente matemáticamente (pagas menos intereses). Bola de Nieve = más motivador psicológicamente (eliminas deudas completas más rápido).',
      ),
      QuizQuestion(
        id: 'deu_q2',
        question: 'Si tienes una tarjeta con tasa del 36% EA y un crédito de consumo al 24% EA, ¿cuál atacas primero con el método Avalancha?',
        options: [
          'El crédito de consumo (24% EA)',
          'La tarjeta de crédito (36% EA)',
          'Ambas por igual',
          'La que tenga menor saldo',
        ],
        correctIndex: 1,
        explanation:
            'Con Avalancha atacas la tasa más alta primero (36% EA = la tarjeta). Cada peso extra que metes ahí te ahorra más intereses a futuro.',
      ),
      QuizQuestion(
        id: 'deu_q3',
        question: '¿Qué es el pago mínimo de una tarjeta de crédito?',
        options: [
          'La cantidad exacta para no generar intereses',
          'El monto mínimo para no caer en mora — pero si solo lo pagas, los intereses acumulan hasta triplicar la deuda original',
          'El 10% del cupo total de la tarjeta',
          'El pago que elimina la deuda en 12 meses',
        ],
        correctIndex: 1,
        explanation:
            'El pago mínimo apenas cubre los intereses del mes. Si solo pagas el mínimo en una tarjeta al 36% EA, una deuda de \$1M puede tardarse 7+ años en pagarse y costar \$3M+ en total.',
      ),
      QuizQuestion(
        id: 'deu_q4',
        question: '¿Qué es una "deuda buena"?',
        options: [
          'Una deuda con tasa menor al 10% EA',
          'Deuda que no te genera intereses',
          'Deuda que financia un activo que genera ingresos mayores al costo del préstamo',
          'Las deudas con el gobierno siempre son buenas',
        ],
        correctIndex: 2,
        explanation:
            'Una deuda buena genera más dinero del que cuesta. Ejemplo: préstamo al 18% EA para un negocio que rinde el 40% EA. La deuda mala financia consumo que no genera retorno.',
      ),
      QuizQuestion(
        id: 'deu_q5',
        question: '¿Cuántos meses de gastos debes tener en un fondo de emergencia ANTES de pagar deudas agresivamente?',
        options: ['0 meses — paga deudas primero', '1 mes', '3–6 meses', 'El fondo no es necesario'],
        correctIndex: 2,
        explanation:
            'Sin un fondo de emergencia de 3–6 meses, cualquier imprevisto te obliga a tomar más deuda. El fondo es el seguro que evita el ciclo de deuda. Primero el colchón, luego el ataque.',
      ),
    ],
  ),
];
