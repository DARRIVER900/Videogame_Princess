# AGENTS.md

## Repository layout
- Playable project: `godot/` (Godot 4.7.2, GL Compatibility). Run all commands from the repo root.
- Root docs are coursework/design material: `README.md`, `Pract_1.md` (GDD), `Ale/`, `Barbie/`, `Carlita/`.
- Main scene: `res://escenas/menu_principal.tscn` → selection menu → `nivel_1_frontera.tscn` (intro de dialogo + combate).
- `arena_movimiento.tscn` is the test harness for movement/combat/bot issues (OUFW-2/3/9/11/16/17), **not** the production chapter level (that is OUFW-6).

## Commands
```bash
godot --headless --import --path godot   # mandatory once after a fresh clone; regenerates ignored .godot/
godot --path godot                       # run the game
godot --headless --path godot --script res://tests/test_<suite>.gd
```
- Test suites are standalone `SceneTree` scripts in `godot/tests/` (`test_personaje`, `test_movimiento`, `test_combate`, `test_carga`, `test_bot`, `test_pociones`, `test_veneno`, `test_dificultad`, `test_menu`, `test_fin_combate`, `test_escenas`, `test_nivel_1`, `test_nivel_2`, `test_nivel_3`, `test_dialogos`, `test_dialogo_ui`, `test_temporizador`, `test_core_loop`). There is no test runner framework; run the suite matching the issue you touched. Exit code `0` means pass.
- No CI, linter, formatter, or separate typechecker exists. The headless suites are the verification step.
- Without the initial `--import`, class references fail with `Could not find type Personaje`.

## Generated files: edit sources, not outputs
`escenas/*.tscn` and the `[input]` section of `project.godot` are generated. Manual edits are overwritten.

```bash
godot --headless --path godot --script res://tools/crear_escenas.gd
godot --headless --path godot --script res://tools/configurar_input_map.gd
```
- Change scenes/nodes in `godot/tools/crear_escenas.gd`; change key bindings in `godot/tools/configurar_input_map.gd`.
- `crear_escenas.gd` exits with code `2` when newly created PNGs are not imported yet. Run `--import` again, then rerun the tool.
- `.godot/` is ignored; `.import` and `.uid` files are committed. Keep them.

## Architecture constraints
- `godot/scripts/personaje/personaje.gd` (`Personaje`) owns physics, combat, charge, and health; it deliberately does **not** read input. `ControladorJugador` reads the InputMap, while `ControladorBot` runs the FSM through the same `Personaje` API. Preserve this split so the bot and headless tests keep exercising real gameplay.
- `Hitbox`/`Hurtbox` are created at runtime as children of `Personaje`; they are not wired in `.tscn` files.
- `SeleccionPartida` is a **static class, not an autoload**. This is intentional: `godot --headless --script` does not load autoloads. Do not move it into `[autoload]`.
- `GestorCombate` resolves combatants by hardcoded node names `Jugadora`, `Rival`, and `Jugadora/Controlador`. The arena swaps princesses at runtime and calls `reiniciar_escucha()`; renaming those nodes breaks Victoria/Game Over.
- Code, identifiers, comments, and test output are in Spanish. Keep the `OUFW-<n>` issue references when editing related code or commit messages.
