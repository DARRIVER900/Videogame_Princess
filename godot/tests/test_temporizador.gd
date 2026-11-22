extends SceneTree
## Suite de pruebas headless para OUFW-12 (temporizador de combate).
##
## Ejecutar:
##   godot --headless --script res://tests/test_temporizador.gd
##
## Verifica la cuenta regresiva, el cambio a rojo en los ultimos 5 segundos, el
## aviso unico al llegar a cero y su integracion con el HUD y el Game Over.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const RUTA_NIVEL := "res://escenas/nivel_1_frontera.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-12: Temporizador de Turno y Alerta en HUD ===\n")

	await _prueba_cuenta_regresiva()
	await _prueba_alerta_roja()
	await _prueba_aviso_unico()
	await _prueba_reinicio()
	await _prueba_hud_del_nivel()
	await _prueba_tiempo_agotado_termina_combate()

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


func _temporizador() -> TemporizadorCombate:
	var t := TemporizadorCombate.new()
	root.add_child(t)
	return t


func _prueba_cuenta_regresiva() -> void:
	print("-- Cuenta atras y formato de dos digitos --")
	var t := _temporizador()
	await _pasos(1)
	_comprobar("arranca cerca de 99", t.tiempo_restante <= 99.0 and t.tiempo_restante > 98.0,
		"%.2f" % t.tiempo_restante)
	_comprobar("el texto muestra 99", t.text == "99", t.text)
	_comprobar("empieza activo", t.activo)

	t.iniciar(10.0)
	t.avanzar(1.0)
	_comprobar("descuenta el tiempo", is_equal_approx(t.tiempo_restante, 9.0),
		"%.1f" % t.tiempo_restante)
	_comprobar("se muestra con dos digitos", t.text == "09", t.text)
	t.queue_free()
	await _pasos(1)


func _prueba_alerta_roja() -> void:
	print("-- Alerta roja en los ultimos 5 segundos --")
	var t := _temporizador()
	await _pasos(1)
	t.iniciar(10.0)
	t.avanzar(4.0)
	_comprobar("con 6 s aun no esta en alerta", not t.en_alerta(),
		"%.1f" % t.tiempo_restante)
	_comprobar("con 6 s el texto es normal",
		t.get_theme_color("font_color") == TemporizadorCombate.COLOR_NORMAL)

	t.avanzar(1.5)
	_comprobar("con 4.5 s entra en alerta", t.en_alerta(),
		"%.1f" % t.tiempo_restante)
	_comprobar("el texto se vuelve rojo",
		t.get_theme_color("font_color") == TemporizadorCombate.COLOR_ALERTA,
		str(t.get_theme_color("font_color")))
	_comprobar("muestra 05 o menos", t.text == "05" or t.text == "04", t.text)
	t.queue_free()
	await _pasos(1)


func _prueba_aviso_unico() -> void:
	print("-- Aviso unico al llegar a cero --")
	var t := _temporizador()
	await _pasos(1)
	var avisos := [0]
	t.tiempo_agotado.connect(func() -> void: avisos[0] += 1)
	t.iniciar(2.0)
	t.avanzar(1.0)
	_comprobar("no avisa antes de cero", avisos[0] == 0, str(avisos[0]))
	t.avanzar(1.0)
	_comprobar("avisa al llegar a cero", avisos[0] == 1, str(avisos[0]))
	_comprobar("queda en cero", is_zero_approx(t.tiempo_restante))
	_comprobar("se detiene solo", not t.activo)
	t.avanzar(5.0)
	_comprobar("no repite el aviso", avisos[0] == 1, str(avisos[0]))
	_comprobar("no baja de cero", is_zero_approx(t.tiempo_restante))
	t.queue_free()
	await _pasos(1)


func _prueba_reinicio() -> void:
	print("-- Reiniciar vuelve al tiempo completo --")
	var t := _temporizador()
	await _pasos(1)
	t.iniciar(10.0)
	t.avanzar(10.0)
	t.iniciar()
	_comprobar("vuelve a 10 s", is_equal_approx(t.tiempo_restante, 10.0),
		"%.1f" % t.tiempo_restante)
	_comprobar("vuelve a estar activo", t.activo)
	_comprobar("vuelve a color normal",
		t.get_theme_color("font_color") == TemporizadorCombate.COLOR_NORMAL)
	t.queue_free()
	await _pasos(1)


func _prueba_hud_del_nivel() -> void:
	print("-- El temporizador viaja en el HUD del nivel --")
	var nivel: Node = load(RUTA_NIVEL).instantiate()
	root.add_child(nivel)
	await _pasos(3)
	var t := nivel.get_node_or_null("HUD/Temporizador") as TemporizadorCombate
	_comprobar("el HUD tiene Temporizador", t != null)
	_comprobar("es del tipo TemporizadorCombate", t is TemporizadorCombate)
	_comprobar("arranca cerca de 99",
		t != null and t.tiempo_restante <= 99.0 and t.tiempo_restante > 98.0,
		"%.2f" % (t.tiempo_restante if t != null else -1.0))
	nivel.queue_free()
	await _pasos(1)


func _prueba_tiempo_agotado_termina_combate() -> void:
	print("-- Tiempo agotado = Game Over automatico --")
	var nivel: Node = load(RUTA_NIVEL).instantiate()
	root.add_child(nivel)
	await _pasos(3)
	var t := nivel.get_node("HUD/Temporizador") as TemporizadorCombate
	var gestor: Node = nivel.get_node("GestorCombate")
	t.tiempo_restante = 0.01
	t.avanzar(0.02)
	await _pasos(2)
	var titulo := gestor.get_node("Panel/Titulo") as Label
	_comprobar("el combate termina", gestor.combate_terminado())
	_comprobar("se muestra el panel", gestor.panel_visible())
	_comprobar("el titulo es GAME OVER", titulo.text == "GAME OVER", titulo.text)
	_comprobar("el temporizador queda detenido", not t.activo)
	nivel.queue_free()
	await _pasos(1)
