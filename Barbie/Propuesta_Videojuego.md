# Propuesta de Videojuego: (Pixel-Art Gore & Cute)

**Elaborado por:** Bárbara Daria Rivera Anguiano  
**Tema:** Concepto, mecánicas principales y experiencia de usuario para videojuego de combate retro  

---

## 1. Visión General y Estética del Juego

La propuesta consiste en el desarrollo de un **videojuego de combate retro en 2D (estilo pixel-art)** con una ambientación gótica, oscura y *gore*, que genera un contraste único al ser protagonizado por **princesas**. 

La trama se centra en una guerra de sucesión real: para definir quién gobernará el reino en el futuro, las princesas aspirantes deben librar batallas a muerte entre sí (combates 1 vs 1).

* **Estética visual:** Inspirada en la época medieval (escenografía, armas ilustres y ambientación sangrienta) combinada con el aspecto *cute* o tierno de los avatares de las princesas.
* **Tono del juego:** Acción bélica, violencia explícita/gore estilizada en pixel-art y temática de fantasía medieval oscura.

---

## 2. Acciones Principales y Ciclo de Juego (Game Loop)

### Acciones del Jugador
Durante los combates, cada princesa puede ejecutar un conjunto de acciones tácticas:

* **Atacar:** Uso de armamento variado de época como ballesta, espada, veneno/pociones ofensivas, mangual, guisarme, hacha o invocación de ataque de dragón.
* **Proteger:** Despliegue de escudo para mitigar el impacto recibido.
* **Esquivar:** Maniobra evasiva para evitar el daño directo del rival.
* **Restablecer vida:** Consumo de pociones sanadoras guardadas en el inventario.
* **Morir:** Pantalla de derrota al perder la totalidad de los puntos de salud.
* **Reiniciar:** Opción para reiniciar el enfrentamiento o la situación actual.

### Ciclo de Juego (Game Loop)
La mecánica de supervivencia y progreso se estructura de forma directa:

$$\text{Historia} \longrightarrow \text{Misión} \longrightarrow \text{Batalla} \longrightarrow \text{Atacar / Recibir impacto} \longrightarrow \text{Sanar} \longrightarrow \text{Ganar / Perder}$$

---

## 3. Modo Historia y Sistema de Progreso

El objetivo principal es ganar cada combate hasta alcanzar la cima y coronarse como reina.

1. **Estructura de Capítulos:** A medida que la historia avanza, se van desbloqueando capítulos. El jugador puede volver a acceder a ellos las veces que sea necesario para practicar o cumplir nuevas misiones.
2. **Escalamiento de Dificultad:** Ganar batallas otorga mayor *status*, nivel y experiencia. Las enemigas posteriores se vuelven progresivamente más difíciles, hábiles y experimentadas.
3. **Enfrentamiento Final:** El avance culmina en la batalla definitiva contra la princesa enemiga más poderosa del reino por el control de la corona.

---

## 4. Reglas Básicas y Sistema de Combate

* **Turnos Temporizados:** En cada turno, el jugador dispone de un tiempo límite (de unos pocos segundos) para decidir si lanza un solo ataque o combina varias acciones para ejecutar un combo.
* **Sin Empates:** El sistema de juego no permite empates: o gana una princesa o no gana ninguna.
* **Penalización por Derrota:** Perder una batalla implica recomenzar el combate desde cero y perder los puntos que se hayan acumulado dentro de esa batalla específica.
* **Sistema de Inventario y Curación:**
  * Cada botella/poción de salud restablece exactamente **15 puntos de vida**.
  * Solo se pueden consumir las pociones que se hayan recolectado previamente en el inventario.
* **Estadísticas de Armas y Protección:** Cada arma y escudo posee valores únicos de ataque y defensa, permitiendo adaptar la estrategia según la enemiga en turno.

---

## 5. Experiencia del Jugador (Feeling & UX)

El juego busca evocar un conjunto específico de emociones e impresiones en el usuario:

* **Sensación de Victoria:** Reconocimiento y satisfacción inmediata al completar misiones y desbloquear capítulos.
* **Sensación de Aprendizaje:** Dominio progresivo de las técnicas de combate y combinaciones de ataque.
* **Satisfacción Visual y Táctica:** Disfrute de la acción sangrienta y la eliminación exitosa de los rivales.
* **Frustración Controlada (Rango Sano):** La derrota penaliza al jugador, pero dentro de un rango justo que motiva a reintentar y aprender, evitando la desmotivación o la frustración excesiva.

---

*Nota de diseño: Todas las mecánicas (daño, salud, interfaz de Win/Lose y elecciones tácticas) están interconectadas para ofrecer una experiencia medieval realista dentro del contexto retro del juego.*
