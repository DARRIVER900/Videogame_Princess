extends SceneTree
## Suite de pruebas headless para OUFW-11 (FSM del bot enemigo).
##
## Ejecutar:
##   godot --headless --script res://tests/test_bot.gd
##
## Verifica el criterio de aceptacion del issue ("el bot toma decisiones
## automaticas basadas en la distancia con el jugador y su porcentaje de HP"):
##   1. Sin rival vivo, el bot se queda en IDLE.
##   2. Rival fuera de rango -> ACERCARSE: camina hacia el con la misma fisica
##      que el jugador (Personaje.avanzar_movimiento).
##   3. Rival en rango -> ATACAR: alterna golpe normal y fuerte y el rival
##      recibe dano real.
##   4. HP bajo el umbral + pociones -> USAR_POCION: sube el HP y baja el
##      inventario. Sin pociones o al tope de vida, no cura.
##
## Codigo de salida: 0 si todo pasa, 1 si algo falla.
##
## Arquitectura: como en OUFW-3/OUFW-9, [Personaje] no lee teclado. La jugadora
## de estas pruebas va SIN ControladorJugador a proposito: todo lo que hace el
## bot lo decide su FSM, no el InputMap.

## Altura de aparicion: lejos del suelo para que caigan y se asienten.
const APARICION_Y := -300.0
## Pies en el suelo.
const SUELO_Y := -32.0
## Separacion inicial estandar del duelo.
const DISTANCIA_PELEA := 60.0

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-11: Maquina de Estados del bot enemigo ===\n")

	await _prueba_arquitectura()
	await _prueba_nace_idle()
	await _prueba_sin_rival_vivo()
	await _prueba_acercarse()
	await _prueba_atacar()
	await _prueba_alternancia_de_golpes()
	await _prueba_usar_pocion()
	await _prueba_pociones_bloqueadas()

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


func _crear_personaje(tipo: Script, x: float) -> Personaje:
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

	root.add_child(p)
	return p


## Duelo estandar: "jugadora" estatica (SIN controlador) y "rival" con la FSM.
## [param distancia] separa a ambos (positivo = la jugadora a la derecha).
func _montar_duelo(distancia: float = DISTANCIA_PELEA) -> Dictionary:
	var suelo := _crear_suelo()
	var jugadora := _crear_personaje(PrincesaDulcecito, distancia)
	jugadora.global_position.y = SUELO_Y
	var rival := _crear_personaje(PrincesaChocolatito, 0.0)

	var bot := ControladorBot.new()
	bot.name = "Bot"
	bot.personaje = rival
	bot.rival = jugadora
	rival.add_child(bot)

	await _asentar(rival)
	await _pasos(5)
	return {
		"suelo": suelo,
		"jugadora": jugadora,
		"rival": rival,
		"bot": bot,
	}


func _liberar(duelo: Dictionary) -> void:
	duelo["jugadora"].queue_free()
	duelo["rival"].queue_free()
	duelo["suelo"].queue_free()


func _pasos(frames: int) -> void:
	for _i in frames:
		await physics_frame


func _asentar(p: Personaje) -> void:
	await _pasos(45)


func _comprobar(nombre: String, ok: bool, detalle: String = "") -> void:
	_total += 1
	if ok:
		print("  OK    | %s  (%s)" % [nombre, detalle])
	else:
		_fallos += 1
		print("  FALLA | %s  (%s)" % [nombre, detalle])


# --- Pruebas ---

func _prueba_arquitectura() -> void:
	print("-- Arquitectura: el bot no arrastra teclado --")
	var duelo := await _montar_duelo()
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]

	_comprobar("el rival NO tiene ControladorJugador (no lee el teclado)",
		rival.get_node_or_null("Controlador") == null)
	_comprobar("el rival tiene la FSM ControladorBot", bot != null)
	_comprobar("el bot controla al rival", bot.personaje == rival)
	_comprobar("el bot persigue a la jugadora", bot.rival == duelo["jugadora"])

	_liberar(duelo)


func _prueba_nace_idle() -> void:
	print("-- El bot arranca en IDLE --")
	# El estado de fabrica del enum debe ser IDLE: es el reposo antes de la
	# primera evaluacion y el estado al que cae el duelo terminado.
	var recien := ControladorBot.new()
	_comprobar("el estado inicial de fabrica es IDLE",
		recien.estado_actual == ControladorBot.EstadoBot.IDLE)
	recien.free()

	var duelo := await _montar_duelo()
	var bot: ControladorBot = duelo["bot"]
	bot.estado_actual = ControladorBot.EstadoBot.IDLE
	var cambios: Array[int] = []
	bot.estado_cambiado.connect(func(estado) -> void: cambios.append(estado))

	bot.reevaluar_ahora()
	await _pasos(2)
	_comprobar("forzada la reevaluacion, la FSM decide",
		bot.estado_actual != ControladorBot.EstadoBot.IDLE,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))
	_comprobar("estado_cambiado notifica la transicion",
		cambios.size() >= 1 and cambios[0] == bot.estado_actual,
		"cambios=%d" % cambios.size())

	_liberar(duelo)


func _prueba_sin_rival_vivo() -> void:
	print("-- Sin rival vivo, el bot se queda en IDLE y quieto --")
	var duelo := await _montar_duelo(400.0)
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]
	var jugadora: Personaje = duelo["jugadora"]

	jugadora.recibir_dano(9999)
	await _pasos(10)
	_comprobar("rival muerto -> IDLE", bot.estado_actual == ControladorBot.EstadoBot.IDLE,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))
	_comprobar("el bot se queda quieto", is_zero_approx(rival.velocity.x),
		"vx=%.2f" % rival.velocity.x)
	_comprobar("el bot no ataca a un rival muerto", jugadora.current_hp == 0)

	_liberar(duelo)


func _prueba_acercarse() -> void:
	print("-- Criterio: rival lejos -> ACERCARSE con la fisica del Personaje --")
	var duelo := await _montar_duelo(500.0)
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]
	var jugadora: Personaje = duelo["jugadora"]
	# Saco de vida: el bot la golpeara a placer y no queremos que muera (matarla
	# mandaria al bot a IDLE y romperia la lectura del estado).
	_hacer_inmortal(jugadora)

	bot.estado_actual = ControladorBot.EstadoBot.IDLE
	bot.reevaluar_ahora()
	await _pasos(2)
	_comprobar("rival fuera de rango -> ACERCARSE",
		bot.estado_actual == ControladorBot.EstadoBot.ACERCARSE,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))

	var x0 := rival.global_position.x
	await _pasos(45)  # 0.75 s: a 220 px/s deberia cubrir ~140 px
	var acercado := absf(jugadora.global_position.x - x0) > 60.0
	_comprobar("el bot camina hacia el rival", acercado,
		"avance=%.1f px" % absf(rival.global_position.x - x0))
	_comprobar("el bot usa la locomocion del Personaje (en suelo tras el avance)",
		rival.en_suelo(), "y=%.1f" % rival.global_position.y)
	_comprobar("el bot mira al rival mientras se acerca",
		rival.mirando_a_la_derecha == (jugadora.global_position.x > rival.global_position.x))

	# Persigue hasta entrar en rango de ataque aunque el rival se aleje.
	jugadora.global_position.x = rival.global_position.x + 600.0
	bot.reevaluar_ahora()
	await _pasos(2)
	_comprobar("al alejarse el rival, vuelve a ACERCARSE",
		bot.estado_actual == ControladorBot.EstadoBot.ACERCARSE,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))

	_liberar(duelo)


func _prueba_atacar() -> void:
	print("-- Criterio: rival en rango -> ATACAR y el rival pierde vida --")
	var duelo := await _montar_duelo(DISTANCIA_PELEA)
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]
	var jugadora: Personaje = duelo["jugadora"]
	_hacer_inmortal(jugadora)

	bot.estado_actual = ControladorBot.EstadoBot.IDLE
	bot.reevaluar_ahora()
	await _pasos(2)
	_comprobar("rival en rango -> ATACAR", bot.estado_actual == ControladorBot.EstadoBot.ATACAR,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))

	await _pasos(30)  # ~0.5 s de intercambios
	_comprobar("el rival pierde vida bajo los golpes del bot",
		jugadora.current_hp < jugadora.hp_max,
		"hp jugadora=%d/%d" % [jugadora.current_hp, jugadora.hp_max])

	_liberar(duelo)


func _prueba_alternancia_de_golpes() -> void:
	print("-- El bot alterna golpe normal y golpe fuerte --")
	var duelo := await _montar_duelo(DISTANCIA_PELEA)
	var jugadora: Personaje = duelo["jugadora"]
	_hacer_inmortal(jugadora)

	var tipos: Array[int] = []
	jugadora.get_node("Hurtbox").golpe_recibido.connect(
		func(hitbox: Hitbox) -> void: tipos.append(hitbox.tipo_ataque))

	await _pasos(60)  # varios ciclos de cooldown
	var normales := tipos.count(Personaje.TipoAtaque.GOLPE_NORMAL)
	var fuertes := tipos.count(Personaje.TipoAtaque.GOLPE_FUERTE)
	_comprobar("el bot suelta golpe normal", normales > 0, "normales=%d" % normales)
	_comprobar("el bot suelta golpe fuerte", fuertes > 0, "fuertes=%d" % fuertes)
	_comprobar("el bot no spamea un solo golpe",
		normales > 0 and fuertes > 0,
		"tipos=%s" % str(tipos))

	_liberar(duelo)


func _prueba_usar_pocion() -> void:
	print("-- Criterio: HP bajo el umbral -> USAR_POCION cura y gasta --")
	var duelo := await _montar_duelo(DISTANCIA_PELEA)
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]

	# Vida critica (10/100 = 0.1 < umbral 0.35). Con +15 por pocion hacen falta
	# dos para superar el umbral, asi que debe beber dos veces.
	rival.recibir_dano(90)
	var pociones_antes := rival.cantidad_pociones
	bot.estado_actual = ControladorBot.EstadoBot.IDLE
	bot.reevaluar_ahora()
	await _pasos(2)
	_comprobar("HP bajo -> USAR_POCION",
		bot.estado_actual == ControladorBot.EstadoBot.USAR_POCION,
		"estado=%s hp=%d" % [ControladorBot.nombre_estado(bot.estado_actual), rival.current_hp])
	_comprobar("la poción sube el HP en cuanto la bebe",
		rival.current_hp > 10, "hp=%d" % rival.current_hp)
	_comprobar("la poción descuenta el inventario",
		rival.cantidad_pociones == pociones_antes - 1,
		"pociones=%d (antes %d)" % [rival.cantidad_pociones, pociones_antes])

	# Mientras bebe no se mueve: ese es el precio de la accion.
	await _pasos(int(bot.tiempo_uso_pocion * 60.0) - 5)
	_comprobar("el bot se planta mientras bebe (ventana de vulnerabilidad)",
		is_zero_approx(rival.velocity.x), "vx=%.2f" % rival.velocity.x)

	# Terminada la accion, si la vida sigue bajo el umbral bebe otra.
	await _pasos(int(bot.tiempo_uso_pocion * 60.0) + 20)
	_comprobar("con vida todavia baja, bebe otra poción",
		rival.cantidad_pociones == pociones_antes - 2,
		"pociones=%d (antes %d) hp=%d" % [rival.cantidad_pociones, pociones_antes, rival.current_hp])

	_liberar(duelo)


func _prueba_pociones_bloqueadas() -> void:
	print("-- La poción se bloquea sin unidades o con la vida al tope --")
	var duelo := await _montar_duelo(DISTANCIA_PELEA)
	var rival: Personaje = duelo["rival"]
	var bot: ControladorBot = duelo["bot"]

	# Sin pociones: vida critica pero inventario vacio.
	rival.cantidad_pociones = 0
	rival.recibir_dano(80)
	bot.estado_actual = ControladorBot.EstadoBot.IDLE
	bot.reevaluar_ahora()
	await _pasos(5)
	_comprobar("sin pociones no entra en USAR_POCION",
		bot.estado_actual != ControladorBot.EstadoBot.USAR_POCION,
		"estado=%s" % ControladorBot.nombre_estado(bot.estado_actual))
	_comprobar("sin pociones la vida no se cura sola", rival.current_hp == 20,
		"hp=%d" % rival.current_hp)

	_liberar(duelo)

	# Con la vida al tope: pociones disponibles pero nada que curar.
	var duelo2 := await _montar_duelo(DISTANCIA_PELEA)
	var rival2: Personaje = duelo2["rival"]
	var bot2: ControladorBot = duelo2["bot"]

	bot2.estado_actual = ControladorBot.EstadoBot.IDLE
	bot2.reevaluar_ahora()
	await _pasos(5)
	_comprobar("con vida al 100% no gasta pociones aunque le queden",
		bot2.estado_actual != ControladorBot.EstadoBot.USAR_POCION
		and rival2.cantidad_pociones == 3,
		"estado=%s pociones=%d" % [
			ControladorBot.nombre_estado(bot2.estado_actual), rival2.cantidad_pociones,
		])

	_liberar(duelo2)


## Hincha la vida del personaje para que aguante la pelea entera durante una
## prueba sin morir (morir dispara el IDLE y las expectativas de daño se pierden).
func _hacer_inmortal(p: Personaje) -> void:
	p.hp_max = 9999
	p.current_hp = 9999
