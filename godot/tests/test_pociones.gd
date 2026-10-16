extends SceneTree
## Suite de pruebas headless para OUFW-10 (consumo de pociones con la tecla E).
##
## Ejecutar:
##   godot --headless --script res://tests/test_pociones.gd
##
## Criterios de aceptacion:
##   1. Recupera +15 HP por uso consumiendo 1 unidad del inventario.
##   2. Bloquea el uso si cantidad_pociones == 0 o si la salud esta al 100%.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-10: Pociones (tecla E) ===\n")

	_prueba_curacion_y_consumo()
	_prueba_bloqueo_sin_pociones()
	_prueba_bloqueo_vida_completa()
	_prueba_tope_de_vida()
	_prueba_muerto()
	_prueba_senales()
	_prueba_ambas_princesas()
	await _prueba_tecla_e()

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


func _nuevo(tipo: Script = PrincesaDulcecito) -> Personaje:
	var p: Personaje = tipo.new()
	p._ready()
	return p


func _prueba_curacion_y_consumo() -> void:
	print("-- Criterio 1: +15 HP y 1 pocion por uso --")
	var p := _nuevo()
	_comprobar("la pocion cura 15 por defecto", p.curacion_pocion == 15,
		str(p.curacion_pocion))

	p.recibir_dano(50)
	var usada := p.usar_pocion()
	_comprobar("usar_pocion devuelve true", usada)
	_comprobar("recupera +15 HP (50 -> 65)", p.current_hp == 65, str(p.current_hp))
	_comprobar("consume 1 pocion (3 -> 2)", p.cantidad_pociones == 2,
		str(p.cantidad_pociones))

	p.usar_pocion()
	p.usar_pocion()
	_comprobar("tres usos curan 45 en total (50 -> 95)", p.current_hp == 95,
		str(p.current_hp))
	_comprobar("tres usos vacian el inventario", p.cantidad_pociones == 0,
		str(p.cantidad_pociones))
	p.free()


func _prueba_bloqueo_sin_pociones() -> void:
	print("-- Criterio 2a: bloqueo con cantidad_pociones == 0 --")
	var p := _nuevo()
	p.recibir_dano(60)
	p.cantidad_pociones = 0
	var hp_antes := p.current_hp

	_comprobar("puede_usar_pocion es false", not p.puede_usar_pocion())
	_comprobar("usar_pocion devuelve false", not p.usar_pocion())
	_comprobar("no cura", p.current_hp == hp_antes, str(p.current_hp))
	_comprobar("el inventario no baja de 0", p.cantidad_pociones == 0,
		str(p.cantidad_pociones))
	_comprobar("el motivo es SIN_POCIONES",
		p.motivo_bloqueo_pocion() == Personaje.MotivoBloqueoPocion.SIN_POCIONES)
	p.free()


func _prueba_bloqueo_vida_completa() -> void:
	print("-- Criterio 2b: bloqueo con la salud al 100% --")
	var p := _nuevo()
	_comprobar("puede_usar_pocion es false a vida completa", not p.puede_usar_pocion())
	_comprobar("usar_pocion devuelve false", not p.usar_pocion())
	_comprobar("NO gasta la pocion", p.cantidad_pociones == 3,
		str(p.cantidad_pociones))
	_comprobar("el motivo es VIDA_COMPLETA",
		p.motivo_bloqueo_pocion() == Personaje.MotivoBloqueoPocion.VIDA_COMPLETA)

	# Tras curarse hasta el tope, la siguiente tambien se bloquea.
	p.recibir_dano(10)
	p.usar_pocion()
	_comprobar("curar hasta el tope deja la vida en hp_max", p.current_hp == p.hp_max,
		str(p.current_hp))
	_comprobar("la siguiente pocion ya se bloquea", not p.usar_pocion())
	_comprobar("solo se gasto 1 pocion (3 -> 2)", p.cantidad_pociones == 2,
		str(p.cantidad_pociones))
	p.free()


func _prueba_tope_de_vida() -> void:
	print("-- La curacion respeta hp_max --")
	var p := _nuevo()
	p.recibir_dano(5)
	p.usar_pocion()
	_comprobar("95 + 15 se queda en 100", p.current_hp == 100, str(p.current_hp))
	_comprobar("la pocion se consume aunque cure menos de 15", p.cantidad_pociones == 2,
		str(p.cantidad_pociones))
	p.free()


func _prueba_muerto() -> void:
	print("-- Un personaje muerto no usa pociones --")
	var p := _nuevo()
	p.recibir_dano(9999)
	_comprobar("usar_pocion devuelve false", not p.usar_pocion())
	_comprobar("sigue en 0 HP y muerto", p.current_hp == 0 and p.esta_muerto)
	_comprobar("no gasta pociones", p.cantidad_pociones == 3,
		str(p.cantidad_pociones))
	_comprobar("el motivo es MUERTO",
		p.motivo_bloqueo_pocion() == Personaje.MotivoBloqueoPocion.MUERTO)
	p.free()


func _prueba_senales() -> void:
	print("-- Senales para el HUD (OUFW-5) --")
	var p := _nuevo()
	var reg := {"hp": [], "usada": [], "bloqueada": []}
	p.health_changed.connect(func(hp: int, _m: int) -> void: reg["hp"].append(hp))
	p.pocion_usada.connect(
		func(rest: int, rec: int) -> void: reg["usada"].append([rest, rec]))
	p.pocion_bloqueada.connect(func(motivo: int) -> void: reg["bloqueada"].append(motivo))

	p.usar_pocion()
	_comprobar("bloqueada por vida completa emite pocion_bloqueada",
		reg["bloqueada"] == [Personaje.MotivoBloqueoPocion.VIDA_COMPLETA]
		and reg["usada"].is_empty() and reg["hp"].is_empty(), str(reg["bloqueada"]))

	p.recibir_dano(40)
	p.usar_pocion()
	_comprobar("un uso valido emite pocion_usada(2, 15)",
		reg["usada"] == [[2, 15]], str(reg["usada"]))
	_comprobar("y health_changed con la vida nueva (60 -> 75)",
		reg["hp"] == [60, 75], str(reg["hp"]))
	p.free()


func _prueba_ambas_princesas() -> void:
	print("-- Ambas princesas comparten la API --")
	for tipo: Script in [PrincesaDulcecito, PrincesaChocolatito]:
		var p := _nuevo(tipo)
		p.recibir_dano(30)
		p.usar_pocion()
		_comprobar("%s: 70 + 15 = 85 y 2 pociones" % p.nombre,
			p.current_hp == 85 and p.cantidad_pociones == 2,
			"hp=%d pociones=%d" % [p.current_hp, p.cantidad_pociones])
		p.free()


## Camino real: InputMap -> ControladorJugador -> Personaje.usar_pocion.
func _prueba_tecla_e() -> void:
	print("-- Tecla E por el InputMap real --")
	_comprobar("la accion usar_pocion existe", InputMap.has_action("usar_pocion"))
	var tiene_e := false
	if InputMap.has_action("usar_pocion"):
		for ev in InputMap.action_get_events("usar_pocion"):
			if ev is InputEventKey and ev.physical_keycode == KEY_E:
				tiene_e = true
	_comprobar("esta ligada a la tecla E", tiene_e)

	var p: Personaje = PrincesaDulcecito.new()
	var ctrl := ControladorJugador.new()
	ctrl.name = "Controlador"
	ctrl.personaje = p
	p.add_child(ctrl)
	root.add_child(p)
	await physics_frame
	p.recibir_dano(50)

	Input.action_press("usar_pocion")
	await physics_frame
	await physics_frame
	_comprobar("E cura +15 y gasta 1 pocion",
		p.current_hp == 65 and p.cantidad_pociones == 2,
		"hp=%d pociones=%d" % [p.current_hp, p.cantidad_pociones])

	# Mantener E no encadena usos: hay que soltar y volver a pulsar.
	for i in 5:
		await physics_frame
	_comprobar("mantener E no gasta mas pociones", p.cantidad_pociones == 2,
		str(p.cantidad_pociones))

	Input.action_release("usar_pocion")
	await physics_frame
	Input.action_press("usar_pocion")
	await physics_frame
	await physics_frame
	_comprobar("soltar y pulsar de nuevo usa otra (80 HP, 1 pocion)",
		p.current_hp == 80 and p.cantidad_pociones == 1,
		"hp=%d pociones=%d" % [p.current_hp, p.cantidad_pociones])
	Input.action_release("usar_pocion")

	# Controles congelados (pausa, menus): E no hace nada.
	ctrl.activo = false
	p.recibir_dano(30)
	Input.action_press("usar_pocion")
	await physics_frame
	await physics_frame
	_comprobar("con el controlador inactivo E no hace nada",
		p.current_hp == 50 and p.cantidad_pociones == 1,
		"hp=%d pociones=%d" % [p.current_hp, p.cantidad_pociones])
	Input.action_release("usar_pocion")
	p.free()