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
2. Abre `godot/project.godot` en el editor y pulsa ▶, o corre desde terminal (desde la raíz del repo):

   ```bash
   godot --path godot
   ```

La escena principal es `escenas/menu_principal.tscn` (OUFW-17): desde ahí eliges princesa (Dulcecito / Chocolatito) y pulsas **Jugar**. La partida completa es **menú → intro de novela visual → Nivel 1 (La Frontera) → Nivel 2 (Bosque Encantado) → Nivel 3 (Cumbres de Azúcar) → Fin de Juego** (OUFW-18). La arena `escenas/arena_movimiento.tscn` es la **arena mínima para probar los controles** (OUFW-2), el combate (OUFW-3), la carga (OUFW-9) y la FSM del rival (OUFW-11), no un nivel de producción.

Cada combate tiene un temporizador de 99 s (OUFW-12); si llega a cero es **Game Over**. Al morir cualquiera de las dos princesas se despliega la pantalla de **Victoria** o **Game Over** (OUFW-16): al ganar, **Siguiente Nivel** avanza el capítulo; al perder, **Reintentar** repite el nivel actual.

**Controles:** `A` / `D` moverse · `W + A` / `W + D` salto diagonal · `S` agachar · `S + A` / `S + D` derrape · `K` golpe normal · `L` golpe fuerte · `J` carga pesada (mantener para acumular, soltar para golpear y romper guardia) · `E` poción · `U` veneno.

### 🧪 Pruebas

Las suites corren sin editor y sin gráficos:

```bash
godot --headless --import --path godot                # una vez por clon, ver nota abajo
godot --headless --path godot --script res://tests/test_personaje.gd    # OUFW-1
godot --headless --path godot --script res://tests/test_movimiento.gd   # OUFW-2
godot --headless --path godot --script res://tests/test_combate.gd      # OUFW-3
godot --headless --path godot --script res://tests/test_carga.gd        # OUFW-9
godot --headless --path godot --script res://tests/test_bot.gd          # OUFW-11
godot --headless --path godot --script res://tests/test_menu.gd         # OUFW-17
godot --headless --path godot --script res://tests/test_fin_combate.gd  # OUFW-16
godot --headless --path godot --script res://tests/test_temporizador.gd # OUFW-12
godot --headless --path godot --script res://tests/test_core_loop.gd    # OUFW-18
godot --headless --path godot --script res://tests/test_balance.gd      # OUFW-19
godot --headless --path godot --script res://tests/test_qa.gd           # OUFW-20
godot --headless --path godot --script res://tests/test_escenas.gd      # integración
```

Código de salida `0` = todo en verde.

> ⚠️ El `--import` es **obligatorio tras un clon nuevo**. Regenera `.godot/` (que está en `.gitignore`) y sin él no se resuelven las clases globales: los scripts fallan con *"Could not find type Personaje"*.

### 🧱 Herramientas

`escenas/*.tscn` y el `InputMap` se **generan con código**, para que ningún nodo ni tecla quede duplicado a mano:

```bash
godot --headless --path godot --script res://tools/crear_escenas.gd
godot --headless --path godot --script res://tools/configurar_input_map.gd
```

**No edites `escenas/*.tscn` ni la sección `[input]` de `project.godot` a mano:** se sobrescriben. Si hace falta cambiar un nodo o una tecla, se cambia en el script de `tools/`.

### 📦 Build final

El build usa `godot/export_presets.cfg` y los *export templates* oficiales de Godot 4.7.2. Desde la raíz del repo:

```bash
godot --headless --path godot --export-release "Linux/X11" ../build/linux/OnceUponAFinalWar.x86_64
godot --headless --path godot --export-release "Windows Desktop" ../build/windows/OnceUponAFinalWar.exe
godot --headless --path godot --export-release "Web" ../build/web/index.html
```

Los binarios llevan el `.pck` embebido (un solo archivo, sin dependencias del proyecto). El build web se sirve con cualquier servidor HTTP estático; por seguridad de WebGL no abre `index.html` con `file://`.

---

### 💗 Hecho con creatividad, código y muchas ganas de crear algo nuestro.

**Bárbara Daría Rivera Anguiano, Carla Jazmín Ríos Martínez & Alejandro Rodríguez**  
*Ingeniería de Software — Facultad de Telemática*  
*Universidad de Colima* 🎓💻
