extends SceneTree
## Suite de QA de OUFW-20: usabilidad, controles y bugs de integracion.
##
## Ejecutar:
##   godot --headless --script res://tests/test_qa.gd
##
## Cubre lo que las suites por sistema no ven:
##   - El InputMap generado conserva TODAS las acciones jugables (incluidas E y U).
##   - El HUD explica las teclas que existen de verdad y usa corazones/pociones.
##   - Menu y Fin de Juego caben en el encuadre y tienen foco util.
##   - El timeout congela a AMBOS combatientes y no deja al bot golpeando
##     detras del panel de Game Over.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const RUTA_MENU := "res://escenas/menu_principal.tscn"
const RUTA_FIN := "res://escenas/fin_juego.tscn"
const RUTA_NIVEL := "res://escenas/nivel_1_frontera.tscn"

## Accion -> tecla fisica que debe estar mapeada.
const CONTROLES := {
	"mover_izquierda": KEY_A,
	"mover_derecha": KEY_D,
	"salto": KEY_W,
	"agachar": KEY_S,
	"golpe_normal": KEY_K,
	"golpe_fuerte": KEY_L,
	"carga_pesada": KEY_J,
	"usar_pocion": KEY_E,
	"ataque_veneno": KEY_U,
}

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-20: QA de usabilidad, controles y bugs ===\n")

	_prueba_input_map()
	await _prueba_hud()
	await _prueba_menu()
	await _prueba_fin_juego()
	await _prueba_timeout_congela_todo()

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
		await process_frame


func _tiene_tecla(accion: String, tecla: int) -> bool:
	if not InputMap.has_action(accion):
		return false
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey and (evento as InputEventKey).physical_keycode == tecla:
			return true
	return false


func _prueba_input_map() -> void:
	print("-- InputMap: ninguna accion jugable se pierde al regenerar --")
	var faltantes: Array[String] = []
	for accion: String in CONTROLES:
		if not _tiene_tecla(accion, CONTROLES[accion]):
			faltantes.append("%s=%s" % [accion, OS.get_keycode_string(CONTROLES[accion])])
	_comprobar("las 9 acciones tienen su tecla fisica", faltantes.is_empty(),
		", ".join(faltantes) if not faltantes.is_empty() else "A/D/W/S/K/L/J/E/U")
	_comprobar("las flechas tambien mueven", _tiene_tecla("mover_derecha", KEY_RIGHT)
		and _tiene_tecla("mover_izquierda", KEY_LEFT))


func _prueba_hud() -> void:
	print("-- HUD: la ayuda menciona las teclas reales --")
	var nivel: Node = load(RUTA_NIVEL).instantiate()
	root.add_child(nivel)
	await _pasos(2)
	var texto := (nivel.get_node("HUD/Estado") as Label).text
	for tecla in ["K", "L", "J", "E", "U"]:
		_comprobar("la ayuda del HUD menciona la tecla %s" % tecla, texto.contains(tecla))
	_comprobar("el HUD muestra el temporizador", nivel.get_node_or_null("HUD/Temporizador") != null)
	var hud := nivel.get_node_or_null("HUD/Combate") as HudCombate
	_comprobar("el HUD tiene el panel visual de combate", hud != null)
	if hud != null:
		var jugadora := nivel.get_node("Jugadora") as Personaje
		var rival := nivel.get_node("Rival") as Personaje
		var corazones := hud.get_node("PanelJugador/Corazones")
		_comprobar("la vida se dibuja con un corazon por cada 10 HP",
			corazones.get_child_count() == hud.corazones_para(jugadora.hp_max),
			"%d corazones" % corazones.get_child_count())
		_comprobar("cada corazon usa los sprites lleno/vacio",
			(corazones.get_child(0) as TextureProgressBar).texture_progress != null
			and (corazones.get_child(0) as TextureProgressBar).texture_under != null)
		var pociones := hud.get_node("PanelJugador/Pociones")
		_comprobar("las pociones tienen su sprite y contador",
			(pociones.get_node("Pocion0") as TextureRect).texture != null
			and (pociones.get_node("Cantidad") as Label).text == "x%d" % jugadora.cantidad_pociones)
		var rect_rival := hud.rect_panel_rival()
		_comprobar("el panel rival esta arriba a la derecha",
			rect_rival.position.x > 480.0 and rect_rival.position.y < 120.0
			and rect_rival.end.x <= 960.0,
			"x=%.0f y=%.0f" % [rect_rival.position.x, rect_rival.position.y])
		_comprobar("el panel rival no tapa el temporizador",
			rect_rival.position.x >= 504.0)
		_comprobar("los corazones escalan con la vida del jefe",
			HudCombate.corazones_para(125) == 13 and HudCombate.corazones_para(150) == 15)
		_comprobar("la fila de corazones del rival existe",
			hud.get_node("PanelRival/Corazones").get_child_count()
			== hud.corazones_para(rival.hp_max))
	nivel.queue_free()
	await _pasos(1)


func _prueba_menu() -> void:
	print("-- Menu: seleccion visible y boton Jugar enfocado --")
	var menu: Control = load(RUTA_MENU).instantiate()
	root.add_child(menu)
	await _pasos(3)

	var dulce := menu.get_node("Panel/BotonDulcecito") as Button
	var choco := menu.get_node("Panel/BotonChocolatito") as Button
	var jugar := menu.get_node("Panel/BotonJugar") as Button
	_comprobar("los botones de princesa son toggle",
		dulce.toggle_mode and choco.toggle_mode)
	_comprobar("la seleccion inicial esta marcada", dulce.button_pressed)
	_comprobar("Jugar arranca con el foco", jugar.has_focus())
	choco.pressed.emit()
	await _pasos(1)
	_comprobar("elegir Chocolatito actualiza el estado",
		SeleccionPartida.princesa_jugable == SeleccionPartida.CHOCOLATITO,
		SeleccionPartida.princesa_jugable)
	_comprobar("el boton elegido queda marcado y el otro no",
		choco.button_pressed and not dulce.button_pressed)
	_comprobar("la etiqueta nombra a la jugable y a la rival",
		(menu.get_node("Panel/EtiquetaSeleccion") as Label).text.contains("Chocolatito")
		and (menu.get_node("Panel/EtiquetaSeleccion") as Label).text.contains("Dulcecito"))
	_comprobar("el panel del menu cabe en el encuadre de 540 px",
		(menu.get_node("Panel") as Control).position.y
		+ (menu.get_node("Panel") as Control).size.y <= 540.0,
		"%.0f px" % ((menu.get_node("Panel") as Control).position.y
			+ (menu.get_node("Panel") as Control).size.y))
	menu.queue_free()
	await _pasos(1)
	SeleccionPartida.princesa_jugable = SeleccionPartida.DULCECITO


func _prueba_fin_juego() -> void:
	print("-- Fin de Juego: resumen y botones utiles --")
	SeleccionPartida.princesa_jugable = SeleccionPartida.CHOCOLATITO
	var fin: Control = load(RUTA_FIN).instantiate()
	root.add_child(fin)
	await _pasos(2)
	var resumen := fin.get_node("Panel/Resumen") as Label
	var menu := fin.get_node("Panel/BotonMenu") as Button
	var salir := fin.get_node("Panel/BotonSalir") as Button
	_comprobar("el resumen conserva la princesa elegida",
		resumen.text.contains("Chocolatito"), resumen.text)
	_comprobar("los dos botones existen y caben en pantalla",
		menu != null and salir != null
		and (fin.get_node("Panel") as Control).position.y
			+ (fin.get_node("Panel") as Control).size.y <= 540.0)
	_comprobar("el boton de menu tiene el foco", menu.has_focus())
	fin.queue_free()
	await _pasos(1)
	SeleccionPartida.princesa_jugable = SeleccionPartida.DULCECITO


func _prueba_timeout_congela_todo() -> void:
	print("-- Timeout: Game Over congela jugadora y bot --")
	SeleccionPartida.princesa_jugable = SeleccionPartida.DULCECITO
	SeleccionPartida.partida_iniciada = true
	SeleccionPartida.intro_vista = true
	SeleccionPartida.nivel_actual = 1

	var nivel: Node = load(RUTA_NIVEL).instantiate()
	root.add_child(nivel)
	await _pasos(2)

	var jugadora := nivel.get_node("Jugadora") as Personaje
	var bot := nivel.get_node("Rival/Bot") as ControladorBot
	var ctrl := nivel.get_node("Jugadora/Controlador") as ControladorJugador
	var gestor := nivel.get_node("GestorCombate")
	var timer := nivel.get_node("HUD/Temporizador") as TemporizadorCombate

	_comprobar("al entrar desde el menu el bot esta activo", bot.activo)
	var hp0 := jugadora.current_hp
	var x_bot := (nivel.get_node("Rival") as Personaje).global_position.x

	timer.avanzar(timer.duracion)
	await _pasos(3)

	_comprobar("el tiempo agotado abre Game Over",
		gestor.combate_terminado() and gestor.panel_visible())
	_comprobar("el panel dice GAME OVER",
		(nivel.get_node("GestorCombate/Panel/Titulo") as Label).text == "GAME OVER")
	_comprobar("el temporizador queda detenido", not timer.activo)
	_comprobar("el controlador de la jugadora queda inactivo", not ctrl.activo)
	_comprobar("la FSM del bot queda inactiva", not bot.activo)
	_comprobar("la jugadora se queda quieta", is_zero_approx(jugadora.velocity.x),
		"vx=%.2f" % jugadora.velocity.x)

	await _pasos(45)
	_comprobar("el bot no sigue golpeando detras del panel",
		jugadora.current_hp == hp0, "hp=%d (antes %d)" % [jugadora.current_hp, hp0])
	_comprobar("el bot no se mueve detras del panel",
		is_equal_approx((nivel.get_node("Rival") as Personaje).global_position.x, x_bot),
		"dx=%.2f" % ((nivel.get_node("Rival") as Personaje).global_position.x - x_bot))

	nivel.queue_free()
	await _pasos(1)
	SeleccionPartida.partida_iniciada = false
