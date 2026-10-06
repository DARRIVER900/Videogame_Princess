# ⚔️✨ Once Upon a Final War

> 🌸 **La fantasía, la supervivencia y el poder femenino se encuentran en un mundo donde las princesas también saben luchar.** 👑⚔️

## 💕 Sobre el proyecto

Somos un equipo de **tres estudiantes de Ingeniería de Software** que pronto crearemos nuestro propio videojuego como parte de la materia **Creación de Videojuegos**.

Este proyecto es una colaboración entre:

- 👩🏻‍💻 **Bárbara Daría Rivera Anguiano**
- 👩🏻‍💻 **Carla Jazmín Ríos Martínez**
- 👨🏻‍💻 **Alejandro Rodríguez**

Somos estudiantes de **7.º semestre de Ingeniería de Software** en la **Facultad de Telemática de la Universidad de Colima**. 🎓💻

## 🌷 Nuestra inspiración

Este videojuego nace de una combinación de **fantasía, creatividad femenina y nuestro amor por los juegos de supervivencia**. 💗🎮

Nos hemos inspirado en experiencias jugando títulos de diferentes géneros, desde juegos de supervivencia y terror como **Resident Evil** 🧟‍♀️, hasta juegos de guerra y acción como **Call of Duty** 🔫.

También tomamos inspiración de personajes y elementos que nos encantan, como:

🐉 Dragones  
🩷 Princesa Peach  
💙 Stitch  
👑 Princesas y personajes fantásticos  
⚔️ Guerreras y mundos de fantasía

## 👑 ¿Qué queremos crear?

No queremos hacer simplemente otro juego de lucha.

Queremos darle nuestro propio estilo: una combinación de **acción, supervivencia, fantasía y un toque cute**. 🌸⚔️✨

Nuestra intención es crear una experiencia donde los personajes femeninos puedan ser **valientes, fuertes y capaces de luchar por su propia supervivencia**, sin dejar de lado una estética divertida y adorable.

Queremos que tanto chicas como chicos puedan disfrutarlo y llevarse un pequeño mensaje:

> 💪👑 **Las chicas también podemos ser valientes guerreras.**

## 🎮 Concepto

En este mundo de fantasía, las princesas no esperan ser rescatadas...

**Ellas luchan por sobrevivir.** ⚔️🔥

El juego combinará elementos de:

- ⚔️ Combate
- 🏹 Supervivencia
- 🐉 Fantasía
- 👑 Personajes femeninos
- 🌸 Estética cute
- 🎭 Creatividad y narrativa

## 🛠️ Estado del proyecto

🚧 **En desarrollo**

Este repositorio documentará nuestro proceso de creación, desde la conceptualización y diseño hasta el desarrollo del videojuego.

## 🕹️ Cómo correrlo

1. Instala [Godot 4.7.2](https://godotengine.org/download/windows/) — basta con el binario, no hay nada más que instalar.
2. Abre el proyecto en el editor y pulsa ▶, o corre desde terminal:

   ```bash
   godot --path .
   ```

La escena principal es `escenas/arena_movimiento.tscn`: una **arena mínima para probar los controles** (OUFW-2), no el nivel del juego. Ese es OUFW-6.

**Controles:** `A` / `D` moverse · `W + A` / `W + D` salto diagonal · `S` agachar · `S + A` / `S + D` derrape.

### 🧪 Pruebas

Las suites corren sin editor y sin gráficos:

```bash
godot --headless --import --path .                # una vez por clon, ver nota abajo
godot --headless --path . --script res://tests/test_personaje.gd    # OUFW-1
godot --headless --path . --script res://tests/test_movimiento.gd   # OUFW-2
godot --headless --path . --script res://tests/test_escenas.gd      # integración
```

Código de salida `0` = todo en verde.

> ⚠️ El `--import` es **obligatorio tras un clon nuevo**. Regenera `.godot/` (que está en `.gitignore`) y sin él no se resuelven las clases globales: los scripts fallan con *"Could not find type Personaje"*.

### 🧱 Herramientas

`escenas/*.tscn` y el `InputMap` se **generan con código**, para que ningún nodo ni tecla quede duplicado a mano:

```bash
godot --headless --path . --script res://tools/crear_escenas.gd
godot --headless --path . --script res://tools/configurar_input_map.gd
```

**No edites `escenas/*.tscn` ni la sección `[input]` de `project.godot` a mano:** se sobrescriben. Si hace falta cambiar un nodo o una tecla, se cambia en el script de `tools/`.

---

### 💗 Hecho con creatividad, código y muchas ganas de crear algo nuestro.

**Bárbara Daría Rivera Anguiano, Carla Jazmín Ríos Martínez & Alejandro Rodríguez**  
*Ingeniería de Software — Facultad de Telemática*  
*Universidad de Colima* 🎓💻
