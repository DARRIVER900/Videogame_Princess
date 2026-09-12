# ONCE UPON A FINAL WAR: DOCUMENTO DE DISEÑO DE JUEGO (GDD)

---

## 1. High Concept
Juego de pelea táctica 2D estilo pixel-art gótico (*Dark-Cute*) donde dos princesas rivales libran duelos a muerte tras el misterioso asesinato de sus hermanos. Combina la estética tierna de caramelo con combates medievales sangrientos, violencia explícita y gestión estratégica por turnos y tiempo.

---

## 2. Experiencia Central
El jugador experimenta una constante tensión táctica al equilibrar agresión y supervivencia bajo la presión de un temporizador. Busca transmitir satisfacción visual (*gore* estilizado) al dominar los movimientos, junto con un sentimiento de triunfo real tras superar combates castigadores.

---

## 3. Perfil de Jugador
* **Público Objetivo:** Jugadores de títulos *indie* de acción, peleas 2D y estética retro/gótica.
* **Nivel de Habilidad:** Mid-core a Hardcore. Valoran los retos basados en tiempo de reacción, aprendizaje de patrones y ejecución precisa de comandos.

---

## 4. Core Loop (Ciclo Principal)

* **Paso 1. Narrativa:** Inicia el capítulo y la historia del reino.
* **Paso 2. Duelo:** Comienza la batalla 1v1 contra la rival.
* **Paso 3. Interacción:** Atacas, esquivas o te curas durante tu turno.
* **Paso 4. Resultado:**
  * **En caso de Victoria:** Avanzas de capítulo y sumas puntuación.
  * **En caso de Derrota:** Transición a pantalla "Moriste" y reinicias el capítulo.

---

## 5. Mecánicas Principales y Controles

### Movimiento de Navegación
* **Moverse a la derecha:** Tecla `D` / Flecha Derecha
* **Moverse a la izquierda:** Tecla `A` / Flecha Izquierda

### Acciones de Combate (Ofensivas)
* **Golpe Normal:** Tecla `K`
* **Golpe Fuerte:** Tecla `L`
* **Ataque de Veneno (Rango/Directo):** Tecla `U` (Aplica daño DoT - daño por tiempo)
* **Super Pesado con Carga:** Tecla `J` (Rompe guardia / Daño masivo de alto impacto)

### Acciones de Evasión y Defensa
* **Saltar atrás:** Teclas `W` + `A`
* **Saltar adelante:** Teclas `W` + `D`
* **Agacharse:** Tecla `S`
* **Derrapar:** Teclas `S` + `A` / `D`

### Sustento y Condición de Muerte
* **Curar HP:** Tecla `E` (Consume poción e incrementa +15 HP del inventario)
* **Muerte:** Pérdida total de Puntos de Vida (HP = 0) desencadena la pantalla de derrota y animación *gore*.

---

## 6. Dinámicas Esperadas vs. UI
* **Gestión de Riesgo vs. Recompensa:** Decidir entre ejecutar el ataque pesado con carga (`J`) o asegurar con un golpe rápido (`K`). La UI regula esta tensión mostrando la barra de HP del rival y un temporizador de turno que parpadea en rojo al agotarse.
* **Administración bajo Presión (Supervivencia):** Al quedarse sin vida y con pocas pociones, el jugador entra en preocupación. La UI muestra un contador permanente de pociones en el inventario y aplica un vignette sangriento cuando la salud cae por debajo del 20%.
* **Aprendizaje por Castigo:** Tras perder la batalla, el jugador ideará una nueva estrategia. La pantalla de *Game Over* muestra el motivo exacto de la muerte para permitirle reflexionar sobre qué corregir.

---

## 7. Mundo y Conflicto Narrativo

### Antecedentes
Los reinos de **Candyr** (riqueza comercial) y **Chocolate** (riqueza minera) mantenían prosperidad gracias al compromiso matrimonial de sus herederos. La tragedia ocurrió cuando ambos príncipes aparecieron sin vida en circunstancias no esclarecidas. Ante la falta de culpables, la ira desató una guerra prolongada. Las hermanas menores, convertidas en las nuevas princesas herederas, toman el mando para erradicar al reino vecino y coronarse sobre las ruinas.

### Estructura Narrativa de 9 Pasos
* **Paso 1. Deseo:** Reclamar el Reino Dulce y vengar la caída del príncipe. **Misión:** Entrenamiento en los terrenos baldíos de la plaza real. **Consecuencia:** Establecimiento de status base e inventario inicial.
* **Paso 2. Incidente Incitante:** Muerte misteriosa de los príncipes; estallido de la guerra. **Misión 1:** Recibir el ultimátum de la princesa rival. **Consecuencia:** Desbloqueo del mapa de capítulos y primera arena 1v1.
* **Paso 3. Intento Inicial:** La Princesa reta a la heredera enemiga a duelo formal. **Misión 2:** Primer combate en los pasillos de la catedral. **Consecuencia:** Introducción del temporizador de turnos y ataques de rango.
* **Paso 4. Fracaso:** La rival aplica veneno inesperado; la jugadora cae en emboscada. **Misión 3:** Sobrevivir a la primera penalización. **Consecuencia:** Caída crítica de HP; introduce el uso de pociones (+15 HP).
* **Paso 5. Giro de Fortuna:** La rival despliega guardia acorazada para frenar el avance. **Misión 4:** Batalla contra la guardia de élite. **Consecuencia:** Escalada de dificultad con enemigos de mayor resistencia de escudo.
* **Paso 6. Problema Creciente:** Despliegue de armas pesadas y letales por parte del reino rival. **Misión Avanzada:** Duelo en la Armería. **Consecuencia:** Exige combos de evasión y contraataque con teclas de carga.
* **Paso 7. Riesgo Máximo:** La rival invoca el Aliento de Dragón en el Salón del Trono. **Clímax:** Batalla contra la Princesa Oscura Enemiga. **Consecuencia:** Cero margen de error; exige timing perfecto de evasión (`W+A` / `W+D`).
* **Paso 8. Resolución:** Ejecución estilo *gore* en pixel-art sobre la rival final. **Condición de Victoria:** Reducir la vida enemiga a 0 HP. **Consecuencia:** Desbloqueo de secuencia final y consagración como reina.
* **Paso 9. Objeto del Deseo:** Coronación sobre un reino en ruinas pero unificado. **Epílogo:** Reclamar la Corona de Azúcar Acorazado. **Consecuencia:** Cierre narrativo y acceso al modo Rejugabilidad.

---

## 8. Fichas de Personajes (Atributos POO)

### Princesa Dulcecito (Reino de Candyr)
* **Perfil:** Heredera menor del Reino de Candyr. Pasó de ser una joven ingenua a una estratega fría y despiadada tras la muerte de su hermano.
* **Apariencia:** Estética *Dark-Cute* victoriana. Vestido de tul rosa pálido manchado de jarabe oscuro y corona de caramelo cristalizado.
* **Atributos POO:**
  * `nombre`: `"Princesa Dulcecito"`
  * `idSkinActiva`: `SKIN_CANDYR_DEFAULT`
  * `modsetClase`: `AGIL_DISTANCIA`
  * `puntosVidaMax`: `100`
  * `multiplicadorDanio`: `1.0f`
  * `cantidadPociones`: `3`

### Princesa Chocolatito (Reino de Chocolate)
* **Perfil:** Soberana menor del Reino de Chocolate. Asumió el mando militar directo y expresa su dolor a través de la violencia bruta en batalla.
* **Apariencia:** Armadura ligera gótica en tonos cacao oscuro con detalles dorados de hoja de oro y cofia de encaje negro.
* **Atributos POO:**
  * `nombre`: `"Princesa Chocolatito"`
  * `idSkinActiva`: `SKIN_CHOCOLATE_DEFAULT`
  * `modsetClase`: `PESADO_PESA`
  * `puntosVidaMax`: `100`
  * `multiplicadorDanio`: `1.0f`
  * `cantidadPociones`: `3`

---

## 9. Interfaz Conceptual y HUD
* **HUD Superior:** Barras de vida (HP) de ambas princesas, retratos *Dark-Cute*, indicador de estado actual (*Veneno/Normal*) y temporizador de turno.
* **HUD Inferior:** Indicador de pociones disponibles (Tecla `E`), contador de combos e historial de teclas ejecutadas.
* **Pantallas:** Transición mediante diálogos estilo novela visual en pixel-art y pantalla sangrienta de *Game Over* con el motivo de muerte.

---

## 10. Evaluación de Viabilidad y Matriz de Riesgo
* **Propuesta:** Once Upon a Final War
* **Loop Claro:** Sí (Capítulo $\rightarrow$ Duelo 1v1 $\rightarrow$ Decisión/Comando $\rightarrow$ Win/Lose)
* **Riesgo Alto:** No (Juego 1v1 local, sin multijugador complejo en red)
* **Alcance Realista:** Sí (2D, 2 personajes con el mismo moveset base, enfocado en MVP)
* **Testeable en Greybox:** Sí (Testeable mediante hitboxes simples y prototipo de comandos)

---

## 11. MVP (Producto Mínimo Viable)
* **Personajes Jugables:** 2 Princesas (Chocolatito y Dulcecito) compartiendo el set de ataques base pero con variantes estéticas (skins) y animaciones de modset.
* **Escenario:** 1 Arena de combate 2D (Frontera en ruinas entre reinos).
* **Flujo Mínimo:** 1 Capítulo jugable completo con secuencia de historia inicial, combate funcional con todos los comandos asignados, sistema de HP/Pociones y pantalla de Win/Lose.

---

## 12. Riesgos y Trade-offs

### Riesgo de Diseño (Controles)
Uno de los principales riesgos de diseño es la rigidez del mapeo de botones por defecto (`W,A,S,D` + `U,J,K,L,E`), lo que podría limitar la flexibilidad de aprendizaje si no se permite al usuario reconfigurar las teclas.

### Trade-off
Al ser un juego en 2D estilo pixel-art, el desarrollo de mecánicas y gráficos resulta más sencillo de realizar para un proyecto inicial. Lo malo es que se renuncia al realismo gráfico en 3D para priorizar un desarrollo ágil y mecánicas de combate directas (*atacar, perder vida, curarse, morir*).