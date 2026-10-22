extends SceneTree
## Suite de pruebas headless para OUFW-16 (pantallas de Victoria y Game Over).
##
## Ejecutar:
##   godot --headless --script res://tests/test_fin_combate.gd
##
## Verifica el criterio de aceptacion de la issue: "se despliega automaticamente al
## morir el jugador o la IA". Monta la arena real (con el GestorCombate que genera
## crear_escenas.gd), mata a un combatiente por el camino de dano real y comprueba
## que el panel se despliega solo, que el input se congela y que los botones llevan
## a Reintentar y al Menu Principal.
##
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const RUTA_ARENA := "res://escenas/arena_movimiento.tscn"
const RUTA_MENU := "res://escenas/menu_principal.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-16: Pantallas de Victoria y Game Over ===\n")

	await _prueba_gestor_existe()
	await _prueba_game_over_al_morir_jugadora()
	await _prueba_victoria_al_morir_ia()
	await _prueba_input_congelado()
	await _prueba_botones()

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


func _montar_arena() -> Node2D:
	var escena: PackedScene = load(RUTA_ARENA)
	if escena == null:
		return null
	var arena := escena.instantiate() as Node2D
	root.add_child(arena)
	return arena


func _gestor(arena: Node2D) -> CanvasLayer:
	return arena.get_node_or_null("GestorCombate") as CanvasLayer


func _panel(arena: Node2D) -> Control:
	var g := _gestor(arena)
	return g.get_node_or_null("Panel") as Control if g != null else null


func _prueba_gestor_existe() -> void:
	print("-- El gestor de fin de combate viaja en la escena --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, RUTA_ARENA)
		return

	var gestor := _gestor(arena)
	_comprobar("la arena tiene GestorCombate", gestor != null)
	_comprobar("el gestor arranca sin panel visible",
		_panel(arena) != null and not _panel(arena).visible)
	_comprobar("tiene los botones Reintentar y Menu Principal",
		gestor.get_node_or_null("Panel/BotonReintentar") != null
		and gestor.get_node_or_null("Panel/BotonMenu") != null)

	arena.queue_free()


func _prueba_game_over_al_morir_jugadora() -> void:
	print("-- Criterio: Game Over se despliega solo al morir el jugador --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "")
		return

	await _pasos(60)
	var jugadora := arena.get_node("Jugadora") as Personaje
	var gestor := _gestor(arena)

	_comprobar("arranca sin combate terminado", not gestor.combate_terminado())
	jugadora.recibir_dano(9999)
	await _pasos(2)

	_comprobar("la jugadora murio", jugadora.esta_muerto)
	_comprobar("el combate se marca terminado", gestor.combate_terminado())
	_comprobar("el panel de fin se despliega automaticamente", gestor.panel_visible())
	var titulo := gestor.get_node("Panel/Titulo") as Label
	_comprobar("el titulo dice GAME OVER", titulo.text == "GAME OVER", titulo.text)

	arena.queue_free()


func _prueba_victoria_al_morir_ia() -> void:
	print("-- Criterio: Victoria se despliega solo al morir la IA --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "")
		return

	await _pasos(60)
	var rival := arena.get_node("Rival") as Personaje
	var gestor := _gestor(arena)

	rival.recibir_dano(9999)
	await _pasos(2)

	_comprobar("la IA murio", rival.esta_muerto)
	_comprobar("el combate se marca terminado", gestor.combate_terminado())
	var titulo := gestor.get_node("Panel/Titulo") as Label
	_comprobar("el titulo dice VICTORIA", titulo.text == "VICTORIA", titulo.text)

	arena.queue_free()


func _prueba_input_congelado() -> void:
	print("-- Al terminar, el input del jugador se congela --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "")
		return

	await _pasos(60)
	var jugadora := arena.get_node("Jugadora") as Personaje
	var ctrl := arena.get_node("Jugadora/Controlador") as ControladorJugador
	var x0 := jugadora.global_position.x

	jugadora.recibir_dano(9999)
	await _pasos(2)

	Input.action_press("mover_derecha")
	await _pasos(30)
	Input.action_release("mover_derecha")

	_comprobar("el controlador queda inactivo", not ctrl.activo)
	_comprobar("un muerto no se mueve al pulsar D",
		absf(jugadora.global_position.x - x0) < 1.0,
		"dx=%.2f" % (jugadora.global_position.x - x0))

	arena.queue_free()


func _prueba_botones() -> void:
	print("-- Los botones Reintentar y Menu existen y son pulsables --")
	var arena := _montar_arena()
	if arena == null:
		_comprobar("la arena se instancia", false, "")
		return

	await _pasos(60)
	arena.get_node("Jugadora").recibir_dano(9999)
	await _pasos(2)

	var gestor := _gestor(arena)
	var reintentar := gestor.get_node("Panel/BotonReintentar") as Button
	var menu := gestor.get_node("Panel/BotonMenu") as Button

	_comprobar("el boton Reintentar esta conectado",
		reintentar.pressed.get_connections().size() > 0)
	_comprobar("el boton Menu Principal esta conectado",
		menu.pressed.get_connections().size() > 0)
	_comprobar("el boton Reintentar tiene el foco",
		reintentar.has_focus())

	arena.queue_free()
