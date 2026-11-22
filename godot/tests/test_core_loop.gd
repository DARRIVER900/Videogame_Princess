extends SceneTree
## Suite de pruebas headless para OUFW-18 (integracion del core loop).
##
## Ejecutar:
##   godot --headless --script res://tests/test_core_loop.gd
##
## Comprueba que los tres niveles jugables comparten el flujo completo
## Menu -> Nivel 1 -> Nivel 2 -> Nivel 3 -> Fin de Juego, que la seleccion de
## princesa sobrevive a los cambios de escena y que cada victoria apunta al
## siguiente capitulo.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const RUTA_N1 := "res://escenas/nivel_1_frontera.tscn"
const RUTA_N2 := "res://escenas/nivel_2_bosque.tscn"
const RUTA_N3 := "res://escenas/nivel_3_cumbres.tscn"
const RUTA_FIN := "res://escenas/fin_juego.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-18: Integracion del Core Loop Completo ===\n")

	await _prueba_cadena_de_escenas()
	await _prueba_nivel_1()
	await _prueba_nivel_2()
	await _prueba_nivel_3()
	await _prueba_fin_de_juego()

	SeleccionPartida.princesa_jugable = SeleccionPartida.DULCECITO
	SeleccionPartida.partida_iniciada = false
	SeleccionPartida.intro_vista = false
	SeleccionPartida.nivel_actual = 1

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


func _preparar_partida() -> void:
	SeleccionPartida.princesa_jugable = SeleccionPartida.CHOCOLATITO
	SeleccionPartida.partida_iniciada = true
	SeleccionPartida.intro_vista = true
	SeleccionPartida.nivel_actual = 1


func _montar(ruta: String) -> Node:
	var nivel: Node = load(ruta).instantiate()
	root.add_child(nivel)
	return nivel


func _prueba_cadena_de_escenas() -> void:
	print("-- La cadena de escenas del core loop existe --")
	for ruta in [RUTA_N1, RUTA_N2, RUTA_N3, RUTA_FIN]:
		_comprobar("%s existe" % ruta.get_file(), load(ruta) != null)


func _prueba_nivel_1() -> void:
	print("-- Nivel 1: entrada desde el menu y victoria hacia el Nivel 2 --")
	_preparar_partida()
	var nivel := _montar(RUTA_N1)
	await _pasos(3)
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var rival := nivel.get_node("Rival") as Personaje
	var bot := nivel.get_node("Rival/Bot") as ControladorBot
	var gestor: Node = nivel.get_node("GestorCombate")

	_comprobar("es un nivel jugable", nivel is Nivel1Frontera)
	_comprobar("el estado registra el nivel 1", SeleccionPartida.nivel_actual == 1,
		str(SeleccionPartida.nivel_actual))
	_comprobar("la jugadora es la elegida", jugadora.nombre == "Princesa Chocolatito",
		jugadora.nombre)
	_comprobar("el rival es la otra princesa", rival.nombre == "Princesa Dulcecito",
		rival.nombre)
	_comprobar("el bot del rival esta activo", bot.activo)
	_comprobar("el gestor conoce el Nivel 2",
		gestor.get("siguiente_escena") == RUTA_N2, str(gestor.get("siguiente_escena")))
	_comprobar("tiene temporizador", nivel.get_node_or_null("HUD/Temporizador") != null)
	_comprobar("tiene HUD", nivel.get_node_or_null("HUD/Estado") != null)
	_comprobar("tiene dialogo", nivel.get_node_or_null("Dialogo") != null)

	rival.recibir_dano(9999)
	await _pasos(2)
	var titulo := gestor.get_node("Panel/Titulo") as Label
	var boton := gestor.get_node("Panel/BotonReintentar") as Button
	_comprobar("la victoria muestra el panel", gestor.panel_visible())
	_comprobar("el titulo es VICTORIA", titulo.text == "VICTORIA", titulo.text)
	_comprobar("el boton avanza al Nivel 2", boton.text == "Siguiente Nivel", boton.text)

	nivel.queue_free()
	await _pasos(2)


func _prueba_nivel_2() -> void:
	print("-- Nivel 2: conserva la seleccion y avanza al Nivel 3 --")
	var nivel := _montar(RUTA_N2)
	await _pasos(3)
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var bot := nivel.get_node("Rival/Bot") as ControladorBot
	var gestor: Node = nivel.get_node("GestorCombate")

	_comprobar("es el Nivel 2", nivel is Nivel2Bosque)
	_comprobar("el estado registra el nivel 2", SeleccionPartida.nivel_actual == 2,
		str(SeleccionPartida.nivel_actual))
	_comprobar("conserva la princesa elegida", jugadora.nombre == "Princesa Chocolatito",
		jugadora.nombre)
	_comprobar("el bot esta activo", bot.activo)
	_comprobar("el gestor conoce el Nivel 3",
		gestor.get("siguiente_escena") == RUTA_N3, str(gestor.get("siguiente_escena")))
	_comprobar("tiene HUD y temporizador",
		nivel.get_node_or_null("HUD/Estado") != null
		and nivel.get_node_or_null("HUD/Temporizador") != null)
	_comprobar("tiene dialogo listo para la cinematica", nivel.get_node_or_null("Dialogo") != null)

	(nivel.get_node("Rival") as Personaje).recibir_dano(9999)
	await _pasos(2)
	var boton := gestor.get_node("Panel/BotonReintentar") as Button
	_comprobar("la victoria avanza al Nivel 3", boton.text == "Siguiente Nivel", boton.text)

	nivel.queue_free()
	await _pasos(2)


func _prueba_nivel_3() -> void:
	print("-- Nivel 3: ultimo combate y salto al Fin de Juego --")
	var nivel := _montar(RUTA_N3)
	await _pasos(3)
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var gestor: Node = nivel.get_node("GestorCombate")

	_comprobar("es el Nivel 3", nivel is Nivel3Cumbres)
	_comprobar("el estado registra el nivel 3", SeleccionPartida.nivel_actual == 3,
		str(SeleccionPartida.nivel_actual))
	_comprobar("conserva la princesa elegida", jugadora.nombre == "Princesa Chocolatito",
		jugadora.nombre)
	_comprobar("el gestor conoce el Fin de Juego",
		gestor.get("siguiente_escena") == RUTA_FIN, str(gestor.get("siguiente_escena")))

	(nivel.get_node("Rival") as Personaje).recibir_dano(9999)
	await _pasos(2)
	var boton := gestor.get_node("Panel/BotonReintentar") as Button
	_comprobar("la victoria final avanza al Fin de Juego",
		boton.text == "Siguiente Nivel", boton.text)

	nivel.queue_free()
	await _pasos(2)


func _prueba_fin_de_juego() -> void:
	print("-- Fin de Juego: conserva la princesa y vuelve al menu --")
	var fin: Control = load(RUTA_FIN).instantiate() as Control
	root.add_child(fin)
	await _pasos(2)
	_comprobar("la pantalla existe", fin != null)
	_comprobar("el titulo es FIN DEL JUEGO",
		(fin.get_node("Panel/Titulo") as Label).text == "FIN DEL JUEGO",
		(fin.get_node("Panel/Titulo") as Label).text)
	_comprobar("el resumen menciona a la princesa elegida",
		"Chocolatito" in (fin.get_node("Panel/Resumen") as Label).text,
		(fin.get_node("Panel/Resumen") as Label).text)
	_comprobar("tiene boton de menu",
		fin.get_node_or_null("Panel/BotonMenu") is Button)
	_comprobar("tiene boton de salir",
		fin.get_node_or_null("Panel/BotonSalir") is Button)
	fin.queue_free()
	await _pasos(1)
