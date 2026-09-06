# DOCUMENTO DE DISEÑO NARRATIVO Y GAMEPLAY

---

## 1. PROPUESTA NARRATIVA PRINCIPAL

* **Tema:** La corrupción de la inocencia, la traición familiar y el costo destructivo de la ambición desmedida.
* **Mundo:** El Reino Dulce, un imperio medieval que solía ser un paraíso colorido y afable de azúcar y melaza. Tras la devastadora guerra de sucesión, el reino colapsó en un páramo gótico, viscoso y marchito, dominado por pozos de jarabe rancio, púas de caramelo afilado y estructuras de mazapán en ruinas.
* **Conflicto:** La sangrienta rivalidad entre dos potencias vecinas: el *Reino de Chocolate* y el *Reino Pastelito*. Originalmente impulsada por dos príncipes que murieron masacrados en batalla, la guerra ha sido heredada por sus hermanas. Las princesas, antes adorables e inocentes, se han transformado en soberanas oscuras, sangrientas y piadosas solo en apariencia (*Dark-Cute*), luchando a muerte por el trono absoluto del Reino Dulce.
* **Meta del Jugador:** Reclamar la corona real superando los duelos 1 contra 1, ejecutando a cada princesa rival en combate hasta alcanzar la cima de la jerarquía.
* **Obstáculo Principal:** La ferocidad y experiencia creciente de las princesas enemigas, la restricción estricta de tiempo por turno y la gestión limitada de insumos de curación.

---

## 2. TRADUCCIÓN A ESPACIO Y MECÁNICAS (GOTHIC PIXEL-ART 2D)

### Dónde Ocurre
En la **Catedral de Azúcar Quemado** y el **Salón del Trono de Caramelo Acorazado**, escenarios medievales oscuros decorados con vidrieras rotas de caramelo y estandartes manchados de jarabe carmesí.

### 3 Verbos Principales del Juego
1. **Atacar:** Ejecutar golpes tácticos con armamento medieval (ballesta, espada, veneno/pociones ofensivas, mangual, guisarme, hacha o invocación de dragón).
2. **Proteger:** Desplegar el escudo para mitigar o bloquear el impacto del daño entrante.
3. **Esquivar:** Realizar una maniobra evasiva en el momento preciso para evitar un ataque directo.

### 3 Obstáculos Mecánicos
1. **Temporizador de Turno Restringido:** El jugador cuenta con solo unos segundos por turno para decidir entre una acción individual o encadenar un combo táctico.
2. **Sistema de Inventario Racionado:** Cada poción restablece exactamente **15 Puntos de Vida (HP)**, pero solo pueden usarse las unidades recolectadas previamente.
3. **Sin Empates y Penalización Severa:** El combate solo finaliza con la muerte de una contendiente. Perder implica la muerte inmediata, la pérdida de los puntos acumulados en la batalla y la obligación de recomenzar desde cero.

### Escalamiento
A medida que se avanzan los capítulos, las rivales aumentan su velocidad de respuesta en el temporizador, alteran impredeciblemente sus patrones de ataque, combinan armas pesadas e invocan magias de dragón.

---

## 3. ESTRUCTURA NARRATIVA DE 9 PASOS (Pacing y Progresión)

| Paso | Hito Narrativo | Evento / Misión en Juego | Consecuencia y Mecánica |
| :--- | :--- | :--- | :--- |
| **1. El Héroe y el Deseo** | Reclamar el Reino Dulce y vengar la caída de la dinastía. | **Prólogo:** Entrenamiento en los terrenos baldíos de la plaza real. | Establecimiento del *status* base, inventario inicial y controles de combate. |
| **2. El Incidente Incitante** | Muerte de los príncipes en el frente; el reino se torna oscuro y visceral. | **Misión 1:** Recibir el ultimátum de las princesas rivales. | Se desbloquea el mapa de capítulos y la primera arena de duelo 1 vs 1. |
| **3. El Intento Inicial** | La Princesa reta a la primera heredera (Princesa Pastelito Glaseado). | **Misión 2:** Primer duelo formal a muerte en los pasillos de la catedral. | Introducción del temporizador de turnos y uso de ataques a distancia (ballesta). |
| **4. El Fracaso** | La rival utiliza pociones de veneno; la jugadora cae en la emboscada. | **Misión 3:** Sobrevivir a la primera derrota narrativa/mecánica. | Caída de vida crítica; introduce el uso estratégico de pociones de curación (+15 HP). |
| **5. Giro de Fortuna** | Las casas de Chocolate y Pastelito pactan un alto al fuego para eliminar a la jugadora. | **Misión 4:** Batalla contra la guardia de élite acorazada. | Escalada de dificultad: los enemigos tienen mayor defensa y escudos pesados. |
| **6. El Problema Creciente** | La Princesa de Chocolate Amargo despliega armamento pesado y letal. | **Capítulo Avanzado:** Duelo en la Armería de Caramelo. | Obliga al jugador a ejecutar combos combinados (Esquivar + Atacar con Guisarme/Mangual). |
| **7. El Riesgo Máximo** | La rival final invoca el Aliento de Dragón en el Salón del Trono. | **Clímax:** Batalla contra la Princesa Oscura Suprema. | Margen de error cero. Exige timing perfecto de protección y evasión. |
| **8. La Resolución** | Ejecución estilo *gore* en pixel-art sobre la rival final. | **Condición de Victoria:** Reducir la barra de vida enemiga a 0 HP. | Desbloqueo de la secuencia final y consagración como soberana. |
| **9. El Objeto del Deseo** | Coronación sobre un reino en ruinas pero unificado bajo un solo mando. | **Epílogo:** Reclamar la Corona de Azúcar Acorazado. | Cierre narrativo, aumento de *status* máximo y acceso al modo Rejugabilidad/Récords. |

---

## 4. SISTEMA DE RESOLUCIÓN Y CONSECUENCIAS

### Detalle de Resoluciones
* **Resolución de Éxito (Victoria):** Al infligir el golpe final, se activa una animación sangrienta en pixel-art (*Finisher*). Se concede aumento de nivel, títulos reales de *status*, desbloqueo del siguiente capítulo y mantenimiento de las pociones restantes en el inventario.
* **Resolución de Fallo (Derrota):** Al perder todos los HP, la princesa es ejecutada por la rival. La pantalla de *Game Over* permite reiniciar el combate actual inmediatamente, pero se restablecen a cero los puntos y estadísticas acumuladas únicamente dentro de esa batalla.


│   INICIO DE BATALLA 1v1  │
                      └─────────────┬────────────┘
                                    │
                                    ▼
                      ┌──────────────────────────┐
                      │ Selección Táctica/Combo │
                      │  (Tiempo Límite: Secs)   │
                      └─────────────┬────────────┘
                                    │
             ┌──────────────────────┴──────────────────────┐
             ▼                                             ▼
 [ HP Enemigo llega a 0 ]                      [ HP Jugador llega a 0 ]
             │                                             │
             ▼                                             ▼
┌──────────────────────────┐                  ┌──────────────────────────┐
│     PANTALLA DE WIN      │                  │     PANTALLA DE LOSE     │
├──────────────────────────┤                  ├──────────────────────────┤
│ • +Experiencia / Status  │                  │ • Animación Gore (Muerte)│
│ • Desbloqueo de Capítulo │                  │ • Reinicio de la batalla │
│ • Conservación de Ítems  │                  │ • Pérdida de Puntos Bad  │
└──────────────────────────┘                  └──────────────────────────┘

