# Viabilidad y Diseño de Interfaz: Lealtad y Sangre

Considerando mi carga académica (Tesis, examen EGEL y un 2do proyecto en equipo), la viabilidad de este desarrollo en solitario depende de mi control de alcance (*scope*) implacable. El diseño se enfocará en sistemas eficientes que requieran poco volumen de recursos artísticos, delegando la carga narrativa y emocional a la interfaz.

---

### 1. Concepto de UI (HUD, canales de información y feedback)

*   **HUD (Estilo Minimalista):** Evitar menús invasivos. En las esquinas inferiores, retratos Pixel-Art de la unidad seleccionada. Para enfatizar la estética *Gore & Cute* y la vulnerabilidad, los retratos de los dragones deben magullarse, sangrar o perder brillo conforme su barra de salud baja.
*   **Canales de Información:** 
    *   *Combate:* Una cuadrícula (grid) limpia. El área de movimiento aliada en azul; el área de amenaza enemiga (rango de ataque o zonas minadas con trampas) en rojo intenso.
    *   *Gestión (Nido):* Interfaz puramente de texto y menús 2D. Sin navegación de avatares en 3D/2D por un campamento.
*   **Feedback:** 
    *   *Visual:* Números de daño claros al golpear y manchas de sangre en las casillas donde una unidad fue herida.
    *   *Auditivo:* Chillidos agudos de las bestias al recibir daño (esencial para forzar la empatía).

### 2. Loop Principal de Interacción

1.  **Fase de Gestión (Menú de Nido):** El jugador distribuye puntos de recursos médicos para curar dragones heridos y lee diálogos breves que avanzan la trama.
2.  **Fase de Despliegue (Mapa de Nodos):** Selección de la siguiente misión. La interfaz muestra un indicador del "Avance del Imperio", forzando una decisión rápida.
3.  **Fase Táctica (Combate):** Interacción por turnos o pausas activas. El jugador selecciona unidades, verifica líneas de visión/trampas y ejecuta comandos de flanqueo o huida.
4.  **Fase de Consecuencia (Pantalla de Resultados):** Un reporte crudo: cuántos recursos se obtuvieron, qué unidades subieron de nivel y, críticamente, quién murió de forma permanente.

### 3. Dinámicas Asociadas y Regulación por la UI

*   **Dinámica de Protección vs. Sacrificio:** El jugador debe sopesar si arriesgar a un dragón para romper la formación enemiga. La UI regula esto mediante la **previsualización de resultados**: antes de confirmar un movimiento, la UI debe mostrar si ese movimiento dejará al dragón dentro del rango de un escorpión o trampa. 
*   **Dinámica de Urgencia:** El reloj de campaña se regula visualmente limitando las opciones del jugador, lo que facilita la decisión y evita la parálisis por análisis. Si el Imperio avanza, ciertos nodos se bloquean visualmente.

### 4. Principal Riesgo del Diseño y Validación

*   **Riesgo Técnico (Desarrollo):** El desarrollo de una IA para enemigos tácticos y el sistema de *pathfinding* (búsqueda de rutas en la cuadrícula) son notorios por absorber meses de programación. Como desarrolladora en solitario con poco tiempo, una IA rota arruinaría la experiencia.
*   **Riesgo de Experiencia:** Que la muerte de un dragón provoque frustración en lugar de empatía, llevando al jugador a cerrar el juego y reiniciar (save-scumming).
*   **Prototipo de Validación (Prueba de Caja Gris):** Antes de dibujar un solo pixel de arte definitivo, debes construir una escena de prueba con cuadrados de colores: 1 cuadrado azul (Dragón) y 2 cuadrados rojos (Imperio) en un grid simple. El objetivo es validar si puedes programar el movimiento, un ataque y la muerte permanente de la unidad. Si este núcleo técnico toma más de dos semanas, el diseño táctico debe simplificarse.

### 5. Trade-Off Explícito

*   **Decisión:** Eliminar las animaciones complejas de ataque en el campo de batalla y la exploración del personaje caminando por el Nido.
*   **A cambio de:** Una resolución de combate a través de destellos (flashes) de pantalla, efectos de sonido y números flotantes, limitando toda la interacción del Nido a pantallas estáticas de interfaz de usuario.
*   **Justificación:** Ahorro masivo de tiempo de desarrollo y arte. Te permite concentrarte en terminar tu tesis y estudiar para el EGEL, asegurando que el juego se termine mediante sistemas robustos en lugar de ahogarte intentando animar un dragón atacando desde ocho direcciones distintas.

### 6. Justificación de Decisiones (Base Teórica)

*   **Empatía y Pérdida:** Mostrar la sangre en los retratos y en el mapa se alinea con el principio de hacer que la muerte importe; no solo eliminas a un personaje mediante una cinemática, sino que retiras una herramienta vital del sistema, generando un impacto psicológico real.
*   **Control Indirecto y Limitación:** Al usar menús estáticos en el Nido en lugar de un área explorable, aplicamos la regla de las restricciones: limitar las opciones reduce la complejidad espacial y dirige al jugador directamente a la meta emocional.
*   **Economía de Atención (Tu contexto):** Al aplicar una interfaz que comunica todo mediante rangos de amenaza (rojo) y retratos claros, mantienes la información comprensible sin saturar el Triángulo de la Extrañeza; las reglas del combate se mantienen normales y predecibles, dejando que la extrañeza recaiga puramente en los personajes.