extends SceneTree
## Suite de pruebas headless para OUFW-2 (controles de navegacion y movimiento).
##
## Ejecutar:
##   godot --headless --script res://tests/test_movimiento.gd
##
## Monta una arena minima (suelo + princesas) y simula pulsaciones reales con
## [method Input.action_press], dejando que la fisica de Godot corra de verdad.
## Codigo de salida: 0 si todo pasa, 1 si algo falla.
##
## IMPORTANTE: [Personaje] no lee el teclado por su cuenta (a proposito, para que el
## bot de OUFW-11 reutilice la misma fisica). Quien lee el InputMap es
## [ControladorJugador], asi que TODA prueba de input necesita ese nodo montado.

## Altura de aparicion: lejos del suelo para que caiga y se asiente antes de medir.
const APARICION_Y := -300.0


var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-2: Controles de navegacion y movimiento ===\n")

	await _prueba_input_map()
	await _prueba_caminata()
	await _prueba_frenado()
	await _prueba_agachado()
	await _prueba_derrape()
	await _prueba_salto()
	await _prueba_salto_diagonal()
	await _prueba_flipper_rival()
	await _prueba_controlador()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


# --- Utilidades de arena ---

func _crear_suelo() -> StaticBody2D:
	var suelo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6000.0, 200.0)
	forma.shape = rect
	forma.position = Vector2(0.0, 100.0)
	suelo.add_child(forma)
	root.add_child(suelo)
	return suelo


## Crea una princesa con su [CollisionShape2D] y su sprite, como en la escena real.
## [param con_controlador] se deja en false para el rival, que todavia no tiene FSM
## (OUFW-11) y por tanto no debe leer el teclado.
func _crear_personaje(tipo: Script, x: float, con_controlador: bool = true) -> Personaje:
	var p: Personaje = tipo.new()
	p.position = Vector2(x, APARICION_Y)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	p.add_child(sprite)

	var colision := CollisionShape2D.new()
	colision.name = "Colision"
	var capsula := CapsuleShape2D.new()
	capsula.height = 64.0
	capsula.radius = 12.0
	colision.shape = capsula
	p.add_child(colision)

	if con_controlador:
		var ctrl := ControladorJugador.new()
		ctrl.name = "Controlador"
		ctrl.personaje = p
		p.add_child(ctrl)

	root.add_child(p)
	return p


func _controlador_de(p: Personaje) -> ControladorJugador:
	return p.get_node_or_null("Controlador") as ControladorJugador


## Avanza [param frames] pasos de fisica reales.
func _pasos(frames: int) -> void:
	for _i in frames:
		await physics_frame


## Deja caer al personaje y esperar a que se asiente en el suelo.
func _asentar(p: Personaje) -> void:
	await _pasos(45)


func _soltar_todas() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "salto", "agachar"]:
		Input.action_release(accion)


func _comprobar(nombre: String, ok: bool, detalle: String = "") -> void:
	_total += 1
	if ok:
		print("  OK    | %s  (%s)" % [nombre, detalle])
	else:
		_fallos += 1
		print("  FALLA | %s  (%s)" % [nombre, detalle])


# --- Pruebas ---

func _prueba_input_map() -> void:
	print("-- InputMap (criterio 1: lectura precisa de inputs) --")
	var esperadas := {
		"mover_izquierda": [KEY_A, KEY_LEFT],
		"mover_derecha": [KEY_D, KEY_RIGHT],
		"salto": [KEY_W, KEY_UP],
		"agachar": [KEY_S, KEY_DOWN],
	}

	for accion: String in esperadas:
		_comprobar("accion '%s' existe" % accion, InputMap.has_action(accion))
		if not InputMap.has_action(accion):
			continue

		var teclas := {}
		for ev: InputEvent in InputMap.action_get_events(accion):
			if ev is InputEventKey and ev.physical_keycode != 0:
				teclas[ev.physical_keycode] = true

		for keycode: int in esperadas[accion]:
			_comprobar("  '%s' responde a %s" % [accion, OS.get_keycode_string(keycode)],
				teclas.has(keycode))

	# El podador de acciones del configurador de InputMap no puede tocar las
	# acciones de motor: si lo hiciera, los menus de OUFW-13/17 perderian el foco.
	for ui in ["ui_accept", "ui_cancel", "ui_left", "ui_right"]:
		_comprobar("accion de motor '%s' intacta" % ui, InputMap.has_action(ui))


func _prueba_caminata() -> void:
	print("-- Caminata (A / D) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(p)
	_comprobar("aterriza y queda en suelo", p.en_suelo(), "y=%.1f" % p.global_position.y)

	var x_inicial := p.global_position.x
	Input.action_press("mover_derecha")
	await _pasos(30)

	_comprobar("D desplaza a la derecha", p.global_position.x - x_inicial > 20.0,
		"avance=%.1f px" % (p.global_position.x - x_inicial))
	_comprobar("acelera hasta la velocidad de caminar",
		p.velocity.x >= p.velocidad_movimiento - 1.0,
		"vx=%.1f / objetivo=%.1f" % [p.velocity.x, p.velocidad_movimiento])
	_comprobar("sin rival, la mirada sigue al avance", p.mirando_a_la_derecha)

	var x_derecha := p.global_position.x
	Input.action_release("mover_derecha")
	Input.action_press("mover_izquierda")
	await _pasos(30)
	_comprobar("A desplaza a la izquierda", p.global_position.x < x_derecha - 20.0,
		"delta=%.1f px" % (p.global_position.x - x_derecha))
	_comprobar("la mirada se invierte", not p.mirando_a_la_derecha)

	_soltar_todas()
	p.queue_free()
	suelo.queue_free()


func _prueba_frenado() -> void:
	print("-- Frenado en suelo (criterio 2: sin deslizamientos no deseados) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(p)

	Input.action_press("mover_derecha")
	await _pasos(30)
	var v_max := absf(p.velocity.x)

	_soltar_todas()
	await _pasos(1)
	var v_tras_1 := absf(p.velocity.x)
	_comprobar("soltar la tecla frena de inmediato", v_tras_1 < v_max * 0.75,
		"%.0f -> %.0f en un frame" % [v_max, v_tras_1])

	await _pasos(60)
	_comprobar("llega a parar del todo", is_zero_approx(p.velocity.x),
		"vx=%.4f" % p.velocity.x)
	_comprobar("el frenado es mas rapido que la aceleracion",
		p.frenado_suelo > p.aceleracion_suelo,
		"frenado=%.0f > accel=%.0f" % [p.frenado_suelo, p.aceleracion_suelo])

	p.queue_free()
	suelo.queue_free()


func _prueba_agachado() -> void:
	print("-- Agachado (S) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)

	var poses: Array[int] = []
	p.locomocion_cambiada.connect(func(estado: int) -> void: poses.append(estado))

	await _asentar(p)
	Input.action_press("agachar")
	await _pasos(5)

	_comprobar("S activa la pose AGACHADO",
		p.estado_locomocion == Personaje.Locomocion.AGACHADO,
		"locomocion=%d" % p.estado_locomocion)
	_comprobar("el factor de altura baja a la mitad",
		is_equal_approx(p.factor_altura_cuerpo(), 0.5), str(p.factor_altura_cuerpo()))
	_comprobar("emite locomocion_cambiada", poses.has(Personaje.Locomocion.AGACHADO))
	_comprobar("el HUD veria una pose baja", p.esta_agachado())

	var x0 := p.global_position.x
	await _pasos(20)
	_comprobar("agachado sin direccion no se desplaza",
		absf(p.global_position.x - x0) < 1.0, "delta=%.2f px" % (p.global_position.x - x0))

	_soltar_todas()
	await _pasos(5)
	_comprobar("soltar S vuelve a DE_PIE",
		p.estado_locomocion == Personaje.Locomocion.DE_PIE)
	_comprobar("altura restaurada", is_equal_approx(p.factor_altura_cuerpo(), 1.0))

	p.queue_free()
	suelo.queue_free()


func _prueba_derrape() -> void:
	print("-- Derrape (S + A/D) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)

	var dir_derrape := [0]
	var arranques := [0]
	p.derrape_iniciado.connect(func(direccion: int) -> void:
		dir_derrape[0] = direccion
		arranques[0] += 1)

	await _asentar(p)
	var x0 := p.global_position.x
	Input.action_press("agachar")
	Input.action_press("mover_derecha")
	await _pasos(3)

	_comprobar("S + D entra en DERRAPE", p.esta_derrapando(),
		"locomocion=%d" % p.estado_locomocion)
	_comprobar("el derrape va a la derecha", dir_derrape[0] == 1, "dir=%d" % dir_derrape[0])
	_comprobar("el impulso es mas rapido que caminar",
		absf(p.velocity.x) > p.velocidad_movimiento,
		"%.0f > %.0f" % [absf(p.velocity.x), p.velocidad_movimiento])
	_comprobar("la pose de derrape deja la altura a 0.6",
		is_equal_approx(p.factor_altura_cuerpo(), 0.6), str(p.factor_altura_cuerpo()))

	await _pasos(40)
	_comprobar("mantener S + D no reinicia el derrape", arranques[0] == 1,
		"arranques=%d" % arranques[0])
	_comprobar("el derrape caduca por tiempo", not p.esta_derrapando(),
		"locomocion=%d" % p.estado_locomocion)
	_comprobar("no queda patinando", absf(p.velocity.x) < p.velocidad_derrape,
		"vx=%.1f" % p.velocity.x)
	_comprobar("el derrape avanzo", p.global_position.x - x0 > 20.0,
		"delta=%.1f px" % (p.global_position.x - x0))

	_soltar_todas()
	await _pasos(5)

	# Repetir hacia el otro lado, ya con el input soltado en medio.
	Input.action_press("agachar")
	Input.action_press("mover_izquierda")
	await _pasos(3)
	_comprobar("S + A derrapa a la izquierda", dir_derrape[0] == -1,
		"dir=%d" % dir_derrape[0])
	_comprobar("se puede relanzar tras soltar", arranques[0] == 2,
		"arranques=%d" % arranques[0])

	_soltar_todas()
	p.queue_free()
	suelo.queue_free()


func _prueba_salto() -> void:
	print("-- Salto (W) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)

	var saltados := [0]
	p.salto_realizado.connect(func(_dir: int) -> void: saltados[0] += 1)

	await _asentar(p)
	var y_suelo := p.global_position.y

	Input.action_press("salto")
	await _pasos(2)
	_comprobar("W despega del suelo", p.velocity.y < 0.0, "vy=%.1f" % p.velocity.y)
	_comprobar("emite salto_realizado", saltados[0] == 1, "saltos=%d" % saltados[0])

	var altura_min := p.global_position.y
	for _i in 14:
		await physics_frame
		altura_min = minf(altura_min, p.global_position.y)

	_comprobar("gana altura sobre el suelo", altura_min < y_suelo - 20.0,
		"subida=%.1f px" % (y_suelo - altura_min))
	_comprobar("la caida pesa mas que la subida",
		p.multiplicador_gravedad_caida > 1.0,
		"x%.1f" % p.multiplicador_gravedad_caida)

	_soltar_todas()
	await _pasos(60)
	_comprobar("vuelve a caer al suelo", p.en_suelo(), "y=%.1f" % p.global_position.y)
	_comprobar("aterriza a la misma altura", absf(p.global_position.y - y_suelo) < 2.0,
		"y=%.1f vs %.1f" % [p.global_position.y, y_suelo])
	_comprobar("no queda con velocidad vertical residual",
		absf(p.velocity.y) < 1.0, "vy=%.3f" % p.velocity.y)

	p.queue_free()
	suelo.queue_free()


func _prueba_salto_diagonal() -> void:
	print("-- Salto diagonal (W + A/D) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(p)

	# Empujon lateral teorico de W + D.
	var alcance_teorico := p.velocidad_movimiento * p.multiplicador_salto_diagonal

	Input.action_press("mover_derecha")
	Input.action_press("salto")
	await _pasos(2)

	_comprobar("W + D arranca con empuje lateral", p.velocity.x > 0.0,
		"vx=%.1f" % p.velocity.x)

	# El empuse del salto diagonal es una fraccion de la velocidad de caminar
	# (multiplicador_salto_diagonal = 0.6 -> 132 px/s), asi que NO tiene por que
	# superar los 220 px/s de correr: el salto es un arco controlado y el control
	# aereo devuelve la velocidad de carrera despues.
	_comprobar("el empuje vale exactamente el multiplicador configurado",
		absf(p.velocity.x - alcance_teorico) < 1.0,
		"vx=%.1f / teorico=%.1f" % [p.velocity.x, alcance_teorico])

	# Este es el frame critico y el guard de la regresion. Sin saltarlo en
	# avanzar_movimiento(), la aceleracion de suelo arrastraria el empuje hacia la
	# velocidad de caminar (132 -> 175) y multiplicador_salto_diagonal no tendria
	# ningun efecto observable: el valor configurado seria mentira.
	_comprobar("el empuje no lo corrige la aceleracion de suelo del mismo frame",
		p.velocity.x < p.velocidad_movimiento, "vx=%.1f" % p.velocity.x)

	# Y con D mantenido, el control aereo debe devolver la velocidad de carrera.
	await _pasos(20)
	_comprobar("el control aereo recupera la velocidad de caminar",
		p.velocity.x > p.velocidad_movimiento - 20.0,
		"vx=%.1f / caminar=%.1f" % [p.velocity.x, p.velocidad_movimiento])

	_soltar_todas()
	await _pasos(70)
	p.queue_free()

	# Salto hacia atras: mas alcance que hacia adelante, porque es la evasion.
	var q := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(q)
	q.mirar_hacia(Vector2(500.0, 0.0))
	Input.action_press("mover_izquierda")
	Input.action_press("salto")
	await _pasos(2)
	var alcance_atras := absf(q.velocity.x)

	_comprobar("saltar hacia atras da mas alcance que hacia adelante",
		alcance_atras > alcance_teorico,
		"atras=%.1f > adelante=%.1f" % [alcance_atras, alcance_teorico])
	_comprobar("el salto hacia atras aleja del rival", q.velocity.x < 0.0,
		"vx=%.1f" % q.velocity.x)

	_soltar_todas()
	await _pasos(70)
	q.queue_free()
	suelo.queue_free()


func _prueba_flipper_rival() -> void:
	print("-- Sprite flipper segun el rival (criterio 3) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	# El rival no lleva ControladorJugador: todavia no tiene FSM (OUFW-11) y no
	# debe leer el teclado.
	var rival := _crear_personaje(PrincesaChocolatito, 400.0, false)
	var ctrl := _controlador_de(p)
	ctrl.rival = rival

	await _asentar(p)
	_comprobar("mira al rival situado a la derecha", p.mirando_a_la_derecha)
	_comprobar("el sprite no esta volteado", not p.nodo_sprite.flip_h)

	# Caminar hacia la izquierda NO debe voltear la cara: manda el rival.
	Input.action_press("mover_izquierda")
	await _pasos(12)
	_comprobar("caminar hacia atras no voltea la mirada", p.mirando_a_la_derecha,
		"vx=%.1f" % p.velocity.x)
	_comprobar("el sprite sigue sin voltear", not p.nodo_sprite.flip_h)

	# Cuando el rival cruza al otro lado, la mirada se invierte sola.
	rival.global_position.x = p.global_position.x - 400.0
	await _pasos(3)
	_comprobar("la mirada sigue al rival al otro lado", not p.mirando_a_la_derecha)
	_comprobar("el sprite se voltea", p.nodo_sprite.flip_h)

	_soltar_todas()
	p.queue_free()
	rival.queue_free()
	suelo.queue_free()


func _prueba_controlador() -> void:
	print("-- Controlador: congelar, soltar controles y estado muerto --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	var ctrl := _controlador_de(p)
	await _asentar(p)

	Input.action_press("mover_derecha")
	await _pasos(10)
	var antes := p.global_position.x

	ctrl.activo = false
	await _pasos(25)
	_comprobar("con activo=false el personaje no avanza",
		absf(p.global_position.x - antes) < 1.0,
		"delta=%.2f px" % (p.global_position.x - antes))

	# Tecla pegada: elScenario de un menu que vuelve del foco.
	ctrl.soltar_controles()
	_comprobar("soltar_controles limpia el estado del InputMap",
		not Input.is_action_pressed("mover_derecha"))

	ctrl.activo = true
	Input.action_press("mover_derecha")
	await _pasos(30)
	_comprobar("reactivado, vuelve a avanzar", p.global_position.x > antes + 20.0,
		"delta=%.1f px" % (p.global_position.x - antes))

	# Muerto: no responde al input.
	p.recibir_dano(999, Personaje.TipoAtaque.GOLPE_FUERTE)
	_soltar_todas()
	await _pasos(5)
	var x_muerta := p.global_position.x
	Input.action_press("mover_derecha")
	await _pasos(25)
	_comprobar("un personaje muerto ignora el input",
		absf(p.global_position.x - x_muerta) < 1.0,
		"delta=%.2f px" % (p.global_position.x - x_muerta))

	_soltar_todas()
	p.queue_free()
	suelo.queue_free()
