extends SceneTree
## Suite de pruebas headless para OUFW-8 (ataque de veneno, tecla U).
##
## Ejecutar:
##   godot --headless --script res://tests/test_veneno.gd
##
## Criterios de aceptacion:
##   1. Aplica danio por segundo (DoT) al rival durante un tiempo determinado.
##   2. Cambia el indicador textual del HUD a estado "Envenenado".
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const APARICION_Y := -300.0
const SUELO_Y := -32.0
const PASO := 1.0 / 60.0

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-8: Ataque de veneno (tecla U) ===\n")

	_prueba_dot()
	_prueba_precision_de_ticks()
	_prueba_indicador_textual()
	_prueba_reaplicacion()
	_prueba_muerte_por_veneno()
	_prueba_validaciones()
	_prueba_habilidad_por_moveset()
	await _prueba_impacto_real()
	await _prueba_cooldown_y_escalado()
	await _prueba_tecla_u()

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


func _nuevo(tipo: Script = PrincesaChocolatito) -> Personaje:
	var p: Personaje = tipo.new()
	p._ready()
	return p


## Avanza [param segundos] de tiempo de juego en pasos de 1/60 s, llamando directo a la
## fisica del personaje (sin depender del reloj real).
func _avanzar(p: Personaje, segundos: float) -> void:
	var pasos := roundi(segundos / PASO)
	for i in pasos:
		p._physics_process(PASO)


func _pasos(frames: int) -> void:
	for i in frames:
		await physics_frame


# --- Criterio 1: DoT -------------------------------------------------------

func _prueba_dot() -> void:
	print("-- Criterio 1: danio por segundo durante un tiempo --")
	var p := _nuevo()
	_comprobar("aplicar_veneno devuelve true", p.aplicar_veneno(4, 5.0))
	_comprobar("al aplicarlo no hay danio instantaneo", p.current_hp == 100,
		str(p.current_hp))

	_avanzar(p, 0.5)
	_comprobar("a los 0.5 s todavia no cobro nada", p.current_hp == 100, str(p.current_hp))
	_avanzar(p, 0.5)
	_comprobar("a 1 s cobra el primer tick (-4)", p.current_hp == 96, str(p.current_hp))
	_avanzar(p, 1.5)
	_comprobar("a 2.5 s lleva 2 ticks (-8)", p.current_hp == 92, str(p.current_hp))
	_avanzar(p, 2.5)
	_comprobar("a 5 s lleva los 5 ticks (-20)", p.current_hp == 80, str(p.current_hp))
	_comprobar("al acabarse el tiempo el estado vuelve a normal", not p.esta_envenenado())

	_avanzar(p, 10.0)
	_comprobar("pasada la duracion ya no hay mas danio", p.current_hp == 80,
		str(p.current_hp))
	p.free()


func _prueba_precision_de_ticks() -> void:
	print("-- Precision de los ticks --")
	var p := _nuevo()
	p.aplicar_veneno(4, 5.0)
	# Un tiron de frames: 2.5 s de golpe deben cobrar exactamente 2 ticks.
	p._physics_process(2.5)
	_comprobar("un delta de 2.5 s cobra 2 ticks, no 1 ni 3", p.current_hp == 92,
		str(p.current_hp))
	_comprobar("y deja 0.5 s de reloj pendiente", is_equal_approx(p.segundos_veneno_restantes(), 2.5),
		"%.2f s restantes" % p.segundos_veneno_restantes())
	# Un delta enorme no cobra mas de los ticks que quedan.
	p._physics_process(999.0)
	_comprobar("un delta enorme nunca cobra mas de 5 ticks (20 HP en total)",
		p.current_hp == 80, str(p.current_hp))
	p.free()

	# 300 pasos de 1/60 = 5 s con error de coma flotante: deben salir los 5 ticks.
	var q := _nuevo()
	q.aplicar_veneno(1, 5.0)
	_avanzar(q, 5.0)
	_comprobar("5 s en pasos de 1/60 cobran los 5 ticks completos", q.current_hp == 95,
		str(q.current_hp))
	q.free()


# --- Criterio 2: indicador textual -----------------------------------------

func _prueba_indicador_textual() -> void:
	print("-- Criterio 2: indicador textual del HUD --")
	var p := _nuevo()
	var cambios: Array = []
	p.estado_alterado_cambiado.connect(func(e: int) -> void: cambios.append(e))

	_comprobar("sin veneno el texto es \"Normal\"", p.texto_estado() == "Normal",
		p.texto_estado())
	p.aplicar_veneno(4, 3.0)
	_comprobar("envenenado el texto es \"Envenenado\"", p.texto_estado() == "Envenenado",
		p.texto_estado())
	_comprobar("estado_alterado es ENVENENADO",
		p.estado_alterado == Personaje.EstadoAlterado.ENVENENADO)
	_comprobar("la senal avisa del cambio una sola vez",
		cambios == [Personaje.EstadoAlterado.ENVENENADO], str(cambios))

	p.aplicar_veneno(4, 3.0)
	_comprobar("refrescar el veneno NO repite la senal", cambios.size() == 1, str(cambios))

	_avanzar(p, 3.0)
	_comprobar("al terminar vuelve a \"Normal\"", p.texto_estado() == "Normal",
		p.texto_estado())
	_comprobar("y la senal avisa del regreso a NINGUNO",
		cambios == [Personaje.EstadoAlterado.ENVENENADO, Personaje.EstadoAlterado.NINGUNO],
		str(cambios))
	p.free()


# --- Reaplicacion ----------------------------------------------------------

func _prueba_reaplicacion() -> void:
	print("-- Reaplicar el veneno no se apila --")
	var p := _nuevo()
	p.aplicar_veneno(4, 5.0)
	_avanzar(p, 3.0)  # 3 ticks = -12
	p.aplicar_veneno(4, 5.0)
	_comprobar("el dps se queda en 4, no se suma", p.dps_veneno_actual() == 4,
		str(p.dps_veneno_actual()))
	_comprobar("la duracion se refresca a 5 s", is_equal_approx(p.segundos_veneno_restantes(), 5.0),
		"%.2f s" % p.segundos_veneno_restantes())
	_avanzar(p, 5.0)
	_comprobar("en total 3 + 5 ticks = -32 HP (no -40 ni doble dps)", p.current_hp == 68,
		str(p.current_hp))
	p.free()

	var q := _nuevo()
	q.aplicar_veneno(4, 5.0)
	q.aplicar_veneno(6, 2.0)
	_comprobar("un veneno mas fuerte sube el dps a 6", q.dps_veneno_actual() == 6,
		str(q.dps_veneno_actual()))
	_comprobar("un veneno mas corto NO acorta el que ya habia",
		is_equal_approx(q.segundos_veneno_restantes(), 5.0),
		"%.2f s" % q.segundos_veneno_restantes())
	q.free()

	# Reaplicar cada segundo (spam) no debe congelar el reloj: el danio sigue cobrandose.
	var r := _nuevo()
	r.aplicar_veneno(4, 5.0)
	for i in 4:
		_avanzar(r, 1.0)
		r.aplicar_veneno(4, 5.0)
	_comprobar("reaplicar cada segundo no evita el danio (4 ticks = -16)",
		r.current_hp == 84, str(r.current_hp))
	r.free()


# --- Muerte y validaciones -------------------------------------------------

func _prueba_muerte_por_veneno() -> void:
	print("-- Muerte por veneno --")
	var p := _nuevo()
	p.recibir_dano(97)  # quedan 3 HP
	var reg := {"died": 0}
	p.died.connect(func() -> void: reg["died"] += 1)
	p.aplicar_veneno(4, 5.0)
	_avanzar(p, 1.0)
	_comprobar("el primer tick la mata (3 HP - 4)", p.esta_muerto and p.current_hp == 0,
		"hp=%d" % p.current_hp)
	_comprobar("died se emite una sola vez", reg["died"] == 1, str(reg["died"]))
	_comprobar("al morir el estado se limpia", not p.esta_envenenado()
		and p.texto_estado() == "Normal", p.texto_estado())
	_avanzar(p, 5.0)
	_comprobar("el cadaver no sigue recibiendo veneno", p.current_hp == 0 and reg["died"] == 1)
	_comprobar("a un muerto no se le puede aplicar veneno", not p.aplicar_veneno(4, 5.0))
	p.free()


func _prueba_validaciones() -> void:
	print("-- Validaciones --")
	var p := _nuevo()
	_comprobar("dps 0 se rechaza", not p.aplicar_veneno(0, 5.0))
	_comprobar("dps negativo se rechaza", not p.aplicar_veneno(-3, 5.0))
	_comprobar("duracion 0 se rechaza", not p.aplicar_veneno(4, 0.0))
	_comprobar("ningun rechazo deja estado alterado", not p.esta_envenenado())
	_comprobar("sin veneno: segundos restantes 0 y dps 0",
		p.segundos_veneno_restantes() == 0.0 and p.dps_veneno_actual() == 0)
	p.aplicar_veneno(4, 0.4)
	_comprobar("una duracion menor a 1 s cobra al menos 1 tick", p.esta_envenenado()
		and p.segundos_veneno_restantes() >= 1.0 - 0.001,
		"%.2f s" % p.segundos_veneno_restantes())
	p.free()


func _prueba_habilidad_por_moveset() -> void:
	print("-- La habilidad es del moveset AGIL_DISTANCIA --")
	var d := _nuevo(PrincesaDulcecito)
	var c := _nuevo(PrincesaChocolatito)
	_comprobar("Dulcecito (AGIL_DISTANCIA) tiene veneno", d.tiene_habilidad_veneno())
	_comprobar("Chocolatito (PESADO_PESA) no lo tiene", not c.tiene_habilidad_veneno())
	d.free()
	c.free()


# --- Integracion real: hitbox -> hurtbox -> estado -------------------------

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


func _crear_personaje(tipo: Script, x: float, con_controlador: bool) -> Personaje:
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


## Atacante (Dulcecito, con controlador) y rival estatico a [param distancia] px.
func _montar(distancia: float) -> Dictionary:
	var suelo := _crear_suelo()
	var atacante := _crear_personaje(PrincesaDulcecito, 0.0, true)
	var rival := _crear_personaje(PrincesaChocolatito, distancia, false)
	rival.global_position.y = SUELO_Y
	var ctrl := atacante.get_node("Controlador") as ControladorJugador
	ctrl.rival = rival
	await _pasos(45)
	return {"suelo": suelo, "atacante": atacante, "rival": rival, "ctrl": ctrl}


func _desmontar(m: Dictionary) -> void:
	for k in ["atacante", "rival", "suelo"]:
		m[k].queue_free()


func _hitbox_de(p: Personaje, indice: int = 0) -> Hitbox:
	return p.get_node_or_null("Hitbox_%d" % indice) as Hitbox


func _prueba_impacto_real() -> void:
	print("-- Impacto real: el hitbox de veneno envenena al rival --")
	var m := await _montar(200.0)  # lejos para el golpe normal (90), cerca para el veneno (260)
	var atacante: Personaje = m["atacante"]
	var rival: Personaje = m["rival"]
	var hp_antes := rival.current_hp

	atacante.ataque_veneno()
	var hb := _hitbox_de(atacante)
	_comprobar("nace un Hitbox de tipo VENENO",
		hb != null and hb.tipo_ataque == Personaje.TipoAtaque.VENENO)
	_comprobar("el golpe no hace danio directo", hb != null and hb.dano == 0,
		str(hb.dano if hb != null else -1))
	_comprobar("lleva el DoT: 4/s durante 5 s",
		hb != null and hb.veneno_dps == 4 and is_equal_approx(hb.veneno_duracion, 5.0))
	await _pasos(4)

	_comprobar("el rival queda Envenenado", rival.esta_envenenado()
		and rival.texto_estado() == "Envenenado", rival.texto_estado())
	_comprobar("sin danio instantaneo ni empuje", rival.current_hp == hp_antes
		and is_zero_approx(rival.velocity.x), "hp=%d vx=%.1f" % [rival.current_hp, rival.velocity.x])
	_comprobar("el atacante NO se envenena a si mismo", not atacante.esta_envenenado())

	# Un segundo de juego real: cobra el primer tick.
	await _pasos(65)
	_comprobar("tras ~1 s de juego real el rival perdio 4 HP",
		rival.current_hp == hp_antes - 4, str(rival.current_hp))
	_desmontar(m)

	# Fuera de alcance: el veneno no llega.
	var lejos := await _montar(500.0)
	var a2: Personaje = lejos["atacante"]
	var r2: Personaje = lejos["rival"]
	a2.ataque_veneno()
	await _pasos(10)
	_comprobar("rival fuera de los 260 px de alcance: no se envenena", not r2.esta_envenenado())
	_desmontar(lejos)


func _prueba_cooldown_y_escalado() -> void:
	print("-- Cooldown y escalado por dificultad --")
	var m := await _montar(200.0)
	var atacante: Personaje = m["atacante"]
	atacante.ataque_veneno()
	atacante.ataque_veneno()
	_comprobar("dos U seguidas lanzan un solo ataque (cooldown 1.2 s)",
		_hitbox_de(atacante, 1) == null and _hitbox_de(atacante, 0) != null)
	await _pasos(80)  # > 1.2 s
	atacante.ataque_veneno()
	_comprobar("pasado el cooldown vuelve a poder lanzarse", _hitbox_de(atacante, 1) != null)
	_desmontar(m)

	# El multiplicador de dano (dificultad de OUFW-15) escala el DoT.
	var n := await _montar(200.0)
	var bot: Personaje = n["atacante"]
	bot.aplicar_multiplicadores_dificultad(1.0, 1.5)
	bot.ataque_veneno()
	var hb := _hitbox_de(bot)
	_comprobar("con multiplicador de dano x1.5 el DoT sube de 4 a 6",
		hb != null and hb.veneno_dps == 6, str(hb.veneno_dps if hb != null else -1))
	_desmontar(n)

	# Un personaje sin la habilidad no crea nada.
	var k := await _montar(200.0)
	var chocolatito: Personaje = k["rival"]
	chocolatito.ataque_veneno()
	var hijos := 0
	for h in chocolatito.get_children():
		if h is Hitbox:
			hijos += 1
	_comprobar("Chocolatito pulsando veneno no lanza ningun golpe", hijos == 0, str(hijos))
	_desmontar(k)


# --- Tecla U por el InputMap real ------------------------------------------

func _prueba_tecla_u() -> void:
	print("-- Tecla U por el InputMap real --")
	_comprobar("la accion ataque_veneno existe", InputMap.has_action("ataque_veneno"))
	var tiene_u := false
	if InputMap.has_action("ataque_veneno"):
		for ev in InputMap.action_get_events("ataque_veneno"):
			if ev is InputEventKey and ev.physical_keycode == KEY_U:
				tiene_u = true
	_comprobar("esta ligada a la tecla U", tiene_u)

	var m := await _montar(200.0)
	var atacante: Personaje = m["atacante"]
	var rival: Personaje = m["rival"]

	Input.action_press("ataque_veneno")
	await _pasos(8)
	_comprobar("U lanza el veneno y el rival queda Envenenado", rival.esta_envenenado(),
		rival.texto_estado())

	# Mantener U no encadena ataques: just_pressed.
	await _pasos(100)
	_comprobar("mantener U no lanza un segundo ataque", _hitbox_de(atacante, 1) == null)
	Input.action_release("ataque_veneno")
	_desmontar(m)

	# Controles congelados: U no hace nada.
	var n := await _montar(200.0)
	var a2: Personaje = n["atacante"]
	var r2: Personaje = n["rival"]
	(n["ctrl"] as ControladorJugador).activo = false
	Input.action_press("ataque_veneno")
	await _pasos(8)
	_comprobar("con el controlador inactivo U no hace nada", not r2.esta_envenenado()
		and _hitbox_de(a2) == null)
	Input.action_release("ataque_veneno")
	_desmontar(n)