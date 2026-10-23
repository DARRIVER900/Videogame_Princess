extends SceneTree
## Suite de pruebas headless para OUFW-13 (UI de cuadros de dialogo).
##
## Ejecutar:
##   godot --headless --script res://tests/test_dialogo_ui.gd
##
## Carga escenas/dialogo.tscn, arranca el guion real de cap1_intro y comprueba:
## estructura visual, retratos, maquina de escribir, avance con Espacio/clic,
## cierre al terminar y rechazo de archivos invalidos.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const RUTA_UI := "res://escenas/dialogo.tscn"
const RUTA_INTRO := "res://datos/dialogos/cap1_intro.json"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-13: UI de Cuadros de Dialogo ===\n")

	await _prueba_estructura()
	await _prueba_inicio()
	await _prueba_maquina_de_escribir()
	await _prueba_avance_con_espacio()
	await _prueba_avance_con_clic()
	await _prueba_cierre()
	await _prueba_archivo_invalido()
	await _prueba_retratos_del_guion()

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


func _montar() -> DialogoUI:
	var ui := (load(RUTA_UI) as PackedScene).instantiate() as DialogoUI
	root.add_child(ui)
	return ui


func _prueba_estructura() -> void:
	print("-- La escena trae el cuadro completo y nace oculta --")
	var ui := _montar()
	await _pasos(2)
	_comprobar("hay una raiz de UI", ui.get_node_or_null("Raiz") != null)
	_comprobar("hay retrato", ui.get_node_or_null("Raiz/Retrato") is TextureRect)
	_comprobar("hay nombre de hablante", ui.get_node_or_null("Raiz/Nombre") is Label)
	_comprobar("hay cuadro de texto", ui.get_node_or_null("Raiz/Texto") is RichTextLabel)
	_comprobar("hay indicador de avance", ui.get_node_or_null("Raiz/Indicador") != null)
	_comprobar("arranca oculta", not ui.visible)
	_comprobar("arranca inactiva", not ui.esta_activo())
	ui.queue_free()
	await _pasos(1)


func _prueba_inicio() -> void:
	print("-- Cargar el guion muestra la primera linea --")
	var ui := _montar()
	await _pasos(2)
	_comprobar("iniciar() acepta el guion real", ui.iniciar(RUTA_INTRO))
	_comprobar("queda visible", ui.visible)
	_comprobar("queda activa", ui.esta_activo())
	_comprobar("carga todas las lineas", ui.total_lineas() >= 4, str(ui.total_lineas()))
	_comprobar("empieza en la linea 1", ui.indice_actual() == 0, str(ui.indice_actual()))
	_comprobar("muestra al hablante correcto",
		ui.nombre_visible() == "Princesa Dulcecito", ui.nombre_visible())
	_comprobar("asigna un retrato", ui.retrato_actual() != null)
	_comprobar("el texto empieza oculto (maquina de escribir)",
		ui.texto_visible().length() < str(ui.linea_actual().get("text", "")).length(),
		"%d caracteres" % ui.texto_visible().length())
	ui.queue_free()
	await _pasos(1)


func _prueba_maquina_de_escribir() -> void:
	print("-- El texto aparece progresivamente --")
	var ui := _montar()
	await _pasos(2)
	ui.iniciar(RUTA_INTRO)
	var completo := str(ui.linea_actual().get("text", ""))
	var antes := ui.texto_visible().length()
	await _pasos(6)
	var despues := ui.texto_visible().length()
	_comprobar("escribe caracteres con el tiempo", despues > antes,
		"%d -> %d" % [antes, despues])
	_comprobar("aun no muestra la linea entera", not ui.texto_completo())
	ui.queue_free()
	await _pasos(1)


func _prueba_avance_con_espacio() -> void:
	print("-- Espacio completa la linea y luego avanza --")
	var ui := _montar()
	await _pasos(2)
	ui.iniciar(RUTA_INTRO)
	await _pasos(3)

	ui._input(_tecla_espacio())
	_comprobar("el primer Espacio completa la linea", ui.texto_completo(),
		"%d/%d" % [ui.texto_visible().length(), str(ui.linea_actual().get("text", "")).length()])
	_comprobar("sigue en la misma linea", ui.indice_actual() == 0, str(ui.indice_actual()))

	ui._input(_tecla_espacio())
	_comprobar("el segundo Espacio avanza", ui.indice_actual() == 1, str(ui.indice_actual()))
	_comprobar("cambia de hablante",
		ui.nombre_visible() == "Princesa Chocolatito", ui.nombre_visible())
	ui.queue_free()
	await _pasos(1)


func _prueba_avance_con_clic() -> void:
	print("-- Un clic tambien completa y avanza --")
	var ui := _montar()
	await _pasos(2)
	ui.iniciar(RUTA_INTRO)
	await _pasos(3)

	ui._input(_clic_izquierdo())
	_comprobar("el primer clic completa la linea", ui.texto_completo())
	ui._input(_clic_izquierdo())
	_comprobar("el segundo clic avanza", ui.indice_actual() == 1, str(ui.indice_actual()))
	ui.queue_free()
	await _pasos(1)


func _prueba_cierre() -> void:
	print("-- Al acabar la ultima linea se cierra y avisa --")
	var ui := _montar()
	await _pasos(2)
	var avisos := [0]
	ui.terminado.connect(func() -> void: avisos[0] += 1)
	ui.iniciar(RUTA_INTRO)

	var vueltas := 0
	while ui.esta_activo() and vueltas < 100:
		ui.avanzar_linea()
		vueltas += 1

	_comprobar("termina tras recorrer el guion", not ui.esta_activo())
	_comprobar("deja la UI oculta", not ui.visible)
	_comprobar("marca el final", ui.esta_finalizado())
	_comprobar("emite terminado una vez", avisos[0] == 1, str(avisos[0]))
	_comprobar("avanzo por todas las lineas",
		ui.indice_actual() == ui.total_lineas() - 1, str(ui.indice_actual()))
	ui.queue_free()
	await _pasos(1)


func _prueba_archivo_invalido() -> void:
	print("-- Un guion invalido no bloquea la partida --")
	var ui := _montar()
	await _pasos(2)
	_comprobar("iniciar() rechaza una ruta inexistente",
		not ui.iniciar("res://datos/dialogos/no_existe.json"))
	_comprobar("se queda oculta", not ui.visible)
	_comprobar("se queda inactiva", not ui.esta_activo())
	ui.queue_free()
	await _pasos(1)


func _prueba_retratos_del_guion() -> void:
	print("-- Cada linea del guion resuelve una textura --")
	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(RUTA_INTRO))
	_comprobar("el guion es JSON valido", err == OK)
	if err != OK:
		return

	var ui := _montar()
	await _pasos(2)
	ui.iniciar(RUTA_INTRO)
	var faltantes := PackedStringArray()
	var guardia := 0
	while ui.esta_activo() and guardia < 100:
		var clave := str(ui.linea_actual().get("portrait", ""))
		if ui.retrato_actual() == null:
			faltantes.append(clave)
		# Primero completa la maquina de escribir, luego avanza.
		ui.avanzar_linea()
		ui.avanzar_linea()
		guardia += 1
	_comprobar("todas las lineas tienen retrato", faltantes.is_empty(),
		"ok" if faltantes.is_empty() else ", ".join(faltantes))
	ui.queue_free()
	await _pasos(1)


func _tecla_espacio() -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	return ev


func _clic_izquierdo() -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	return ev
