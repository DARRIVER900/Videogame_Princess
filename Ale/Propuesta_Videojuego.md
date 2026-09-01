# Propuesta de Videojuego: "Case Closed"

---

## 1. Idea General

**Case Closed** es un juego de detectives en tercera persona, ambientado en una ciudad latinoamericana contemporánea (inspirada en Buenos Aires, Ciudad de México o Bogotá). El jugador interpreta a una investigadora privada que acepta casos de personas comunes: desapariciones, fraudes, infidelidades, extorsiones.

Tiene inspiración en el videojuego L.A. Noire, en el tono y la ambientación, pero con un enfoque radicalmente distinto: el caso no se resuelve automáticamente. Si el jugador no conecta las pistas correctamente, el caso queda sin resolver y tiene consecuencias narrativas reales.

---

## 2. Elementos Formales

### Mecánica Principal

**Conexión de Pistas**: El jugador recolecta evidencia en el mundo (fotos, testimonios, objetos, documentos) y debe relacionarlas manualmente en un tablero de investigación. Similar a los tableros de conspiración, el jugador arrastra y conecta pistas para formar hipótesis.

- Cada pista tiene etiquetas (ej: "Lugar", "Persona", "Tiempo", "Objeto", "Motivo")
- Conectar dos pistas crea una deducción: "La víctima fue vista en el bar X (pista A) + el sospechoso trabaja en el bar X (pista B) = el sospechoso y la víctima se conocían"
- Las deducciones correctas abren nuevas líneas de investigación

### Objetivo del Jugador

Cerrar el caso presentando una hipótesis completa. Esto requiere:

1. Conectar todas las pistas clave en una red lógica
2. Identificar al responsable (si aplica)
3. Determinar el móvil y los eventos

El caso se considera "Cerrado" solo si la hipótesis es válida. Si no, el caso queda "Archivado" y el jugador debe vivir con las consecuencias.

### Reglas Básicas

| Regla | Descripción |
|-------|-------------|
| **Sin corrección automática** | El juego no indica si una conexión es correcta hasta que el jugador intenta cerrar el caso. No hay retroalimentación inmediata. |
| **Conexiones falsas** | El jugador puede conectar pistas incorrectamente, formando hipótesis falsas. Estas no se marcan como erróneas hasta el cierre. |
| **Límite de tiempo por caso** | El cliente tiene urgencia. El jugador tiene 3 días (en tiempo de juego) para presentar una hipótesis. Tras eso, el caso se archiva automáticamente. |
| **Sistema de reputación** | Los casos bien cerrados aumentan la reputación, atrayendo clientes más complejos. Los casos archivados la dañan. |
| **Rejugabilidad** | Los casos tienen múltiples resoluciones. Siempre hay una "verdad objetiva", pero el jugador puede cerrar el caso con hipótesis parciales que sean lógicamente consistentes (aunque incompletas). |

---

## 3. Experiencia Buscada

### ¿Qué debe sentir el jugador?

| Emoción | Cómo se genera |
|---------|----------------|
| **Responsabilidad real** | Saber que el caso no se resuelve solo, y que sus errores tienen peso narrativo (PLAY: Agencia). |
| **Satisfacción cognitiva** | El momento "Eureka" al conectar dos pistas aparentemente no relacionadas (PLAY: Descubrimiento). |
| **Incertidumbre productiva** | Dudar sobre la validez de una conexión, revisitar la escena, buscar más evidencia. |
| **Frustración controlada** | La falta de retroalimentación inmediata genera tensión, pero el tablero permite avanzar aunque sea probando conexiones (PLAY: Desafío equilibrado). |
| **Inmersión detectivesca** | El proceso mental de "construir un caso" es la mecánica central, no solo un medio para avanzar en la historia. |

### ¿Por qué esta mecánica genera estas emociones?

- **Conexión de pistas manual** transforma la investigación en un acto activo de construcción, no de recolección pasiva. El jugador no solo encuentra evidencia, sino que la interpreta.
- **La ausencia de feedback inmediato** elimina la "asistencia" que rompe la inmersión. El jugador debe confiar en su propio juicio, como un detective real.
- **El cierre imperfecto** (hipótesis parcialmente válidas) permite que el jugador avance incluso si no entiende todo, pero sin la sensación de que el juego lo "lleva de la mano".
- **La presión temporal y la reputación** añaden un peso real a las decisiones, incentivando la atención y la meticulosidad.

---

## 4. Justificación MDA (Mecánicas - Dinámicas - Estéticas)

### Mecánicas

- Conexión de pistas
- Cierre de caso
- Sistema de reputación
- Límite temporal

### Dinámicas

- **Deducción activa**: El jugador revisa el tablero, busca patrones y forma hipótesis.
- **Evaluación de certeza**: Sin feedback inmediato, el jugador debe juzgar sus propias conclusiones.
- **Priorización**: El sistema de reputación y el tiempo obligan a decidir entre investigar más o cerrar el caso.

### Estéticas

- **Descubrimiento**: Al conectar pistas y ver el caso cobrar forma.
- **Tensión**: Por la presión temporal y la incertidumbre.
- **Responsabilidad**: Por las consecuencias narrativas de cerrar mal un caso.
- **Inmersión**: Porque el jugador piensa y actúa como un investigador real.

### Relación entre capas

| De Mecánicas a Dinámicas | De Dinámicas a Estéticas |
|--------------------------|--------------------------|
| La conexión de pistas genera dinámicas de análisis comparativo y construcción de hipótesis. | La deducción activa produce descubrimiento al conectar piezas aparentemente inconexas. |
| La ausencia de feedback inmediato obliga a evaluar la propia certeza antes de avanzar. | La evaluación constante genera tensión e incertidumbre productiva. |
| El sistema de reputación y el tiempo crean una dinámica de priorización. | La priorización produce responsabilidad: cada decisión tiene peso narrativo. |