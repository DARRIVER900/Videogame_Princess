extends SceneTree
## Suite de pruebas headless para OUFW-17 (Menu Principal y Seleccion de Personajes).
##
## Ejecutar:
##   godot --headless --script res://tests/test_menu.gd
##
## Verifica el criterio de aceptacion de la issue: "carga limpia de escenas entre
## menu y niveles". Comprueba que el menu carga, que la seleccion se guarda en el
## autoload [SeleccionPartida] y que la arena instaladas las princesas elegidas sin
## dejar la escena del menu viva.
##
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const RUTA_MENU := "res://escenas/menu_principal.tscn"
const RUTA_ARENA := "res://escenas/arena_movimiento.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-17: Menu Principal y Seleccion de Personajes ===\n")

	await _prueba_autoload()
	await _prueba_menu_carga()
	await _prueba_seleccion_guarda()
	await _prueba_escena_correcta_por_clave()
	await _prueba_rival_es_la_contraria()
	await _prueba_arena_instala_jugadora()

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


func _prueba_autoload() -> void:
	print("-- La clase de seleccion es global y arranca valida --")
	_comprobar("SeleccionPartida resuelve como clase global",
		SeleccionPartida != null)
	_comprobar("arranca con una seleccion valida",
		SeleccionPartida.es_clave_valida(SeleccionPartida.princesa_jugable),
		str(SeleccionPartida.princesa_jugable))


func _prueba_menu_carga() -> void:
	print("-- El menu carga con sus botones --")
	SeleccionPartida.princesa_jugable = "dulcecito"
	var escena: PackedScene = load(RUTA_MENU)
	_comprobar("la escena del menu existe", escena != null)
	if escena == null:
		return

	var menu := escena.instantiate() as Control
	root.add_child(menu)
	await _pasos(2)

	_comprobar("tiene boton Jugar", menu.get_node_or_null("Panel/BotonJugar") != null)
	_comprobar("tiene boton Dulcecito", menu.get_node_or_null("Panel/BotonDulcecito") != null)
	_comprobar("tiene boton Chocolatito", menu.get_node_or_null("Panel/BotonChocolatito") != null)

	# El boton de la princesa por defecto arranca marcado.
	var boton_activo := menu.get_node("Panel/BotonDulcecito") as Button
	_comprobar("el boton de la princesa por defecto esta marcado",
		boton_activo.button_pressed)

	menu.queue_free()


func _prueba_seleccion_guarda() -> void:
	print("-- Pulsar un boton guarda la seleccion --")
	SeleccionPartida.princesa_jugable = "dulcecito"
	var menu := load(RUTA_MENU).instantiate() as Control
	root.add_child(menu)
	await _pasos(2)

	menu.get_node("Panel/BotonChocolatito").pressed.emit()
	await _pasos(1)
	_comprobar("elegir Chocolatito se guarda",
		SeleccionPartida.princesa_jugable == "chocolatito",
		SeleccionPartida.princesa_jugable)

	menu.get_node("Panel/BotonDulcecito").pressed.emit()
	await _pasos(1)
	_comprobar("elegir Dulcecito se guarda",
		SeleccionPartida.princesa_jugable == "dulcecito",
		SeleccionPartida.princesa_jugable)

	menu.queue_free()


func _prueba_escena_correcta_por_clave() -> void:
	print("-- Cada clave apunta a su escena --")
	_comprobar("dulcecito -> princesa_dulcecito.tscn",
		SeleccionPartida.ruta_de("dulcecito") == "res://escenas/princesa_dulcecito.tscn",
		SeleccionPartida.ruta_de("dulcecito"))
	_comprobar("chocolatito -> princesa_chocolatito.tscn",
		SeleccionPartida.ruta_de("chocolatito") == "res://escenas/princesa_chocolatito.tscn",
		SeleccionPartida.ruta_de("chocolatito"))
	_comprobar("ambas escenas existen",
		load(SeleccionPartida.ruta_de("dulcecito")) != null
		and load(SeleccionPartida.ruta_de("chocolatito")) != null)


func _prueba_rival_es_la_contraria() -> void:
	print("-- El rival es siempre la princesa no elegida --")
	SeleccionPartida.princesa_jugable = "dulcecito"
	_comprobar("jugable dulcecito -> rival chocolatito",
		SeleccionPartida.clave_rival() == "chocolatito",
		SeleccionPartida.clave_rival())
	SeleccionPartida.princesa_jugable = "chocolatito"
	_comprobar("jugable chocolatito -> rival dulcecito",
		SeleccionPartida.clave_rival() == "dulcecito",
		SeleccionPartida.clave_rival())


func _prueba_arena_instala_jugadora() -> void:
	print("-- La arena instala la princesa elegida (carga limpia) --")
	SeleccionPartida.princesa_jugable = "chocolatito"

	var arena := load(RUTA_ARENA).instantiate() as Node2D
	root.add_child(arena)
	await _pasos(2)

	var jugadora := arena.get_node_or_null("Jugadora") as Personaje
	var rival := arena.get_node_or_null("Rival") as Personaje
	_comprobar("la jugadora es Chocolatito",
		jugadora != null and jugadora.nombre == "Princesa Chocolatito",
		jugadora.nombre if jugadora != null else "sin jugadora")
	_comprobar("el rival es Dulcecito",
		rival != null and rival.nombre == "Princesa Dulcecito",
		rival.nombre if rival != null else "sin rival")
	_comprobar("el controlador apunta a la princesa nueva",
		(arena.get_node("Jugadora/Controlador") as ControladorJugador).personaje == jugadora)
	_comprobar("el controlador mira al rival",
		(arena.get_node("Jugadora/Controlador") as ControladorJugador).rival == rival)
	_comprobar("solo hay una Jugadora (sin restos de la vieja)",
		arena.get_node_or_null("Jugadora_anterior") == null)

	arena.queue_free()
	SeleccionPartida.princesa_jugable = "dulcecito"
