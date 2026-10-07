extends SceneTree
## Suite de integracion para las escenas de OUFW-2.
##
## Ejecutar:
##   godot --headless --script res://tests/test_escenas.gd
##
## Diferencia con `test_movimiento.gd`: ahi se monta la escena a mano, aqui se
## carga el .tscn del repositorio. Esto es lo que demuestra que los dos cableados
## criticos sobreviven la serializacion:
##   - ControladorJugador.rival -> criterio 3 (flipper segun la posicion del rival)
##   - Personaje.nodo_sprite    -> el volteo necesita encontrar el sprite
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const RUTA_ARENA := "res://escenas/arena_movimiento.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-2: integracion de escenas ===\n")

	await _prueba_escenas_cargan()
	await _prueba_cableado_del_rival()
	await _prueba_juego_completo()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


func _comprobar(nombre: String, ok: bool, detalle: String = "") -> void:
	_total += 1
	if ok:
		print("  OK    | %s  (%s)" % [nombre, detalle])
	else:
		_fallos += 1
		print("  FALLA | %s  (%s)" % [nombre, detalle])


func _pasos(frames: int) -> void:
	for _i in frames:
		await physics_frame


func _soltar_todas() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "salto", "agachar"]:
		Input.action_release(accion)


func _montar_arena() -> Node2D:
	var escena: PackedScene = load(RUTA_ARENA)
	if escena == null:
		return null
	var arena := escena.instantiate() as Node2D
	root.add_child(arena)
	return arena


func _prueba_escenas_cargan() -> void:
	print("-- Las escenas del repositorio cargan --")
	_comprobar("los tres .tscn existen y cargan",
		load(RUTA_ARENA) != null
		and load("res://escenas/princesa_dulcecito.tscn") != null
		and load("res://escenas/princesa_chocolatito.tscn") != null)

	# La textura del placeholder se creo en una pasada previa: si su .import no
	# viaja en el repositorio, el equipo la pierde y el flipper no se veria.
	var sprite_base := Sprite2D.new()
	sprite_base.texture = load("res://recursos/placeholder_dulcecito.png")
	_comprobar("el placeholder viaja importado", sprite_base.texture != null,
		str(sprite_base.texture))
	sprite_base.free()

	_comprobar("la arena es la escena principal",
		ProjectSettings.get_setting("application/run/main_scene", "") == RUTA_ARENA,
		str(ProjectSettings.get_setting("application/run/main_scene", "")))

	var p := load("res://escenas/princesa_dulcecito.tscn").instantiate() as Personaje
	_comprobar("la princesa es un Personaje", p != null, str(p.get_class()))
	_comprobar("su textura esta asignada",
		p.get_node_or_null("Sprite") != null
		and (p.get_node_or_null("Sprite") as Sprite2D).texture != null)
	_comprobar("su colision tiene la altura esperada",
		is_equal_approx((p.get_node_or_null("Colision") as CollisionShape2D).shape.height, 64.0),
		str((p.get_node_or_null("Colision") as CollisionShape2D).shape.height))
	p.free()


func _prueba_cableado_del_rival() -> void:
	print("-- Cableado que sostiene el criterio 3 --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "no se pudo cargar " + RUTA_ARENA)
		return

	var jugadora := arena.get_node_or_null("Jugadora") as Personaje
	var rival := arena.get_node_or_null("Rival") as Personaje
	var ctrl := arena.get_node_or_null("Jugadora/Controlador") as ControladorJugador

	_comprobar("la arena tiene Jugadora, Rival y Controlador",
		jugadora != null and rival != null and ctrl != null)
	if jugadora == null or rival == null or ctrl == null:
		arena.queue_free()
		return

	# Estos dos son el motivo entero de esta suite: si NodePath no se resolviera,
	# el flipper caeria al fallback de mirar hacia el ultimo input.
	_comprobar("ControladorJugador.rival sobrevive la serializacion",
		is_instance_valid(ctrl.rival), str(ctrl.rival))
	_comprobar("ControladorJugador.personaje apunta a la jugadora",
		ctrl.personaje == jugadora)
	_comprobar("Personaje.nodo_sprite resuelve tras cargar",
		jugadora.nodo_sprite != null, str(jugadora.nodo_sprite))
	_comprobar("el rival no tiene ControladorJugador (aun no hay FSM)",
		arena.get_node_or_null("Rival/Controlador") == null)
	_comprobar("hay HUD y camara",
		arena.get_node_or_null("HUD/Estado") != null
		and arena.get_node_or_null("Camara") != null)

	arena.queue_free()


func _prueba_juego_completo() -> void:
	print("-- Juego completo: teclado -> movimiento -> flipper --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "")
		return

	var jugadora := arena.get_node("Jugadora") as Personaje
	var rival := arena.get_node("Rival") as Personaje

	# Deja asentar a las dos: comparten suelo, asi que la posicion relativa en X
	# no cambia y el vector de mirada sigue siendo valido.
	await _pasos(60)
	_comprobar("la jugadora aterriza", jugadora.en_suelo(), "y=%.1f" % jugadora.global_position.y)
	_comprobar("la jugadora mira al rival (a la derecha)",
		jugadora.mirando_a_la_derecha,
		"jugadora.x=%.0f rival.x=%.0f" % [jugadora.global_position.x, rival.global_position.x])

	# Criterio 1: el input mueve al personaje.
	var x0 := jugadora.global_position.x
	Input.action_press("mover_derecha")
	await _pasos(30)
	_comprobar("D mueve a la jugadora", jugadora.global_position.x > x0 + 20.0,
		"avance=%.1f px" % (jugadora.global_position.x - x0))

	# Criterio 3: acercarse al rival NO lo hace girar; manda el rival.
	_comprobar("acercarse al rival no voltea la mirada",
		jugadora.mirando_a_la_derecha)

	# Criterio 2: soltar la tecla frena.
	_soltar_todas()
	await _pasos(45)
	_comprobar("soltar la tecla frena del todo", is_zero_approx(jugadora.velocity.x),
		"vx=%.4f" % jugadora.velocity.x)

	# Voltear al cruzar al otro lado: la prueba end-to-end del criterio 3.
	rival.global_position.x = jugadora.global_position.x - 400.0
	await _pasos(4)
	_comprobar("la mirada sigue al rival al otro lado", not jugadora.mirando_a_la_derecha)
	_comprobar("el sprite se voltea", jugadora.nodo_sprite.flip_h)

	# El HUD de la arena no debe romperse en ningun frame.
	var etiqueta := arena.get_node("HUD/Estado") as Label
	_comprobar("el HUD refleja el estado", not etiqueta.text.is_empty(),
		etiqueta.text.split("\n")[4].strip_edges() if etiqueta.text.split("\n").size() > 5 else "?")

	_soltar_todas()
	arena.queue_free()
