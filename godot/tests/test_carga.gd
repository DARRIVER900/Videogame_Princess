extends SceneTree
## Suite de pruebas headless para OUFW-9 (carga rompe-guardia, tecla `J`).
##
## Ejecutar:
##   godot --headless --script res://tests/test_carga.gd
##
## Verifica los criterios de aceptacion del issue:
##   1. Rompe la defensa/bloqueo enemigo: el golpe carga la marca
##      `Hitbox.rompe_guardia` y la Hurtbox rival emite `guardia_rota`.
##   2. Inflige dano multiplicado: el dano escala con el tiempo de acumulacion,
##      desde `dano_carga` (soltada al instante) hasta `dano_carga x
##      multiplicador_carga_max` (carga llena), con techo en `tiempo_carga_max`.
##   3. Efecto visual de acumulacion: el sprite se "infla" mientras se carga y
##      vuelve a su tamano al soltar.
##
## Ademas cubre las reglas de guardado: cooldown, muerte y cancelacion.
##
## Codigo de salida: 0 si todo pasa, 1 si algo falla.
##
## Importante: `J` vive en el InputMap y lo lee [ControladorJugador] (la fisica
## pertenece a [Personaje], que no toca teclado), igual que en OUFW-3.

## Altura de aparicion del atacante: lejos del suelo para que caiga y se asiente.
const APARICION_Y := -300.0
## Pies en el suelo.
const SUELO_Y := -32.0

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-9: Carga rompe-guardia (tecla J) ===\n")

	await _prueba_input_map()
	await _prueba_carga_arranca()
	await _prueba_carga_inmediata()
	await _prueba_dano_multiplicado()
	await _prueba_tope_de_carga()
	await _prueba_efecto_visual()
	await _prueba_rompe_guardia()
	await _prueba_cooldown()
	await _prueba_cancelaciones()
	await _prueba_end_to_end_teclado()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


# --- Utilidades de arena (mismo patron que test_combate.gd) ---

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


func _montar_combate(distancia: float = 60.0) -> Dictionary:
	var suelo := _crear_suelo()
	var atacante := _crear_personaje(PrincesaDulcecito, 0.0)
	var rival := _crear_personaje(PrincesaChocolatito, distancia, false)
	rival.global_position.y = SUELO_Y
	var ctrl := _controlador_de(atacante)
	ctrl.rival = rival
	await _asentar(atacante)
	return {
		"suelo": suelo,
		"atacante": atacante,
		"rival": rival,
		"ctrl": ctrl,
	}


func _hurtbox_de(p: Personaje) -> Hurtbox:
	return p.get_node_or_null("Hurtbox") as Hurtbox


func _hitbox_de(p: Personaje, indice: int = 0) -> Hitbox:
	return p.get_node_or_null("Hitbox_%d" % indice) as Hitbox


func _controlador_de(p: Personaje) -> ControladorJugador:
	return p.get_node_or_null("Controlador") as ControladorJugador


func _pasos(frames: int) -> void:
	for _i in frames:
		await physics_frame


func _asentar(p: Personaje) -> void:
	await _pasos(45)


func _soltar_todas() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "salto", "agachar",
			"golpe_normal", "golpe_fuerte", "carga_pesada"]:
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
	print("-- InputMap de la carga (J) --")
	_comprobar("accion 'carga_pesada' existe", InputMap.has_action("carga_pesada"))
	if not InputMap.has_action("carga_pesada"):
		return
	var teclas := {}
	for ev: InputEvent in InputMap.action_get_events("carga_pesada"):
		if ev is InputEventKey and ev.physical_keycode != 0:
			teclas[ev.physical_keycode] = true
	_comprobar("'carga_pesada' responde a J", teclas.has(KEY_J), str(teclas.keys()))


func _prueba_carga_arranca() -> void:
	print("-- La carga arranca, acumula y emite sus senales --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]

	var inicios := [0]
	var niveles: Array[float] = []
	atacante.carga_iniciada.connect(func() -> void: inicios[0] += 1)
	atacante.carga_cambiada.connect(func(nivel: float) -> void: niveles.append(nivel))

	_comprobar("sin iniciar, no hay carga", not atacante.esta_cargando())
	atacante.iniciar_carga()
	_comprobar("iniciar_carga enciende el estado cargando", atacante.esta_cargando())
	_comprobar("carga_iniciada se emite una vez", inicios[0] == 1, "inicios=%d" % inicios[0])
	_comprobar("arranca con nivel 0", is_equal_approx(atacante.carga_nivel(), 0.0),
		str(atacante.carga_nivel()))

	await _pasos(18)  # 0.3 s a 60 fps
	_comprobar("mantener la carga acumula nivel", atacante.carga_nivel() > 0.0,
		"nivel=%.2f" % atacante.carga_nivel())
	_comprobar("carga_cambiada notifica niveles crecientes",
		niveles.size() > 1 and niveles[niveles.size() - 1] > niveles[0],
		"primero=%.2f ultimo=%.2f senales=%d" % [
			niveles[0] if niveles.size() > 0 else -1.0,
			niveles[niveles.size() - 1] if niveles.size() > 0 else -1.0,
			niveles.size(),
		])

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_carga_inmediata() -> void:
	print("-- Soltar al instante: golpe minimo con la marca rompe-guardia --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]

	atacante.iniciar_carga()
	atacante.soltar_carga()
	var hitbox := _hitbox_de(atacante, 0)
	_comprobar("soltar la carga despacha un golpe", hitbox != null)
	if hitbox != null:
		_comprobar("el golpe es de tipo SUPER_PESADO_CARGA",
			hitbox.tipo_ataque == Personaje.TipoAtaque.SUPER_PESADO_CARGA)
		_comprobar("con nivel 0 el dano es el base", hitbox.dano == atacante.dano_carga,
			"dano=%d base=%d" % [hitbox.dano, atacante.dano_carga])
		_comprobar("el golpe carga la marca rompe-guardia (criterio 1)", hitbox.rompe_guardia)
		_comprobar("el volumen es el alcance de carga",
			(hitbox.get_node("Colision") as CollisionShape2D).shape.size
			== atacante.alcance_carga)
		_comprobar("lleva el empuje de carga", hitbox.empuje == atacante.empuje_carga,
			"empuje=%.0f" % hitbox.empuje)
	_comprobar("soltar cierra el estado cargando", not atacante.esta_cargando())

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_dano_multiplicado() -> void:
	print("-- Criterio 2: el dano escala con el tiempo de acumulacion --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	# Carga a media potencia (mitad de tiempo_carga_max) y soltar pegando.
	atacante.iniciar_carga()
	await _pasos(int(atacante.tiempo_carga_max * 30.0))  # ~media carga a 60 fps
	var nivel_medio := atacante.carga_nivel()
	atacante.soltar_carga()

	await _pasos(2)
	var vida_tras_media := rival.current_hp
	var dano_medio := 100 - vida_tras_media
	_comprobar("la carga a media potencia golpea", dano_medio > 0, "dano=%d" % dano_medio)
	_comprobar("el dano supera al de la carga minima", dano_medio > atacante.dano_carga,
		"dano=%d minimo=%d" % [dano_medio, atacante.dano_carga])
	_comprobar("el dano no supera al maximo", dano_medio
		<= roundi(atacante.dano_carga * atacante.multiplicador_carga_max)
		and nivel_medio < 1.0,
		"dano=%d tope=%d nivel=%.2f" % [
			dano_medio, roundi(atacante.dano_carga * atacante.multiplicador_carga_max),
			nivel_medio,
		])
	_comprobar("el golpe de carga empuja mas que el fuerte",
		is_equal_approx(rival.velocity.x, atacante.empuje_carga),
		"vx=%.1f" % rival.velocity.x)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_tope_de_carga() -> void:
	print("-- Criterio 2: la carga llena llega a su techo y no lo supera --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	atacante.iniciar_carga()
	await _pasos(int(atacante.tiempo_carga_max * 60.0) + 20)  # holgura sobre el tope
	_comprobar("el nivel se queda en 1.0 con el tiempo agotado",
		is_equal_approx(atacante.carga_nivel(), 1.0), "nivel=%.2f" % atacante.carga_nivel())

	atacante.soltar_carga()
	await _pasos(2)
	var dano_lleno := 100 - rival.current_hp
	var dano_tope := roundi(atacante.dano_carga * atacante.multiplicador_carga_max)
	_comprobar("la carga llena inflige exactamente el dano tope",
		dano_lleno == dano_tope, "dano=%d tope=%d" % [dano_lleno, dano_tope])

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_efecto_visual() -> void:
	print("-- Criterio 3: efecto visual de acumulacion (el sprite se infla) --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]
	var sprite := atacante.nodo_sprite

	_comprobar("el sprite nace a tamano normal", is_equal_approx(sprite.scale.x, 1.0),
		"escala=%.2f" % sprite.scale.x)

	atacante.iniciar_carga()
	await _pasos(int(atacante.tiempo_carga_max * 60.0) + 5)
	_comprobar("con la carga llena el sprite crece",
		sprite.scale.x > 1.0, "escala=%.2f" % sprite.scale.x)
	_comprobar("el crecimiento respeta factor_escala_carga",
		is_equal_approx(sprite.scale.x, 1.0 + atacante.factor_escala_carga),
		"escala=%.2f esperada=%.2f" % [sprite.scale.x, 1.0 + atacante.factor_escala_carga])

	atacante.soltar_carga()
	_comprobar("al soltar vuelve a tamano normal", is_equal_approx(sprite.scale.x, 1.0),
		"escala=%.2f" % sprite.scale.x)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_rompe_guardia() -> void:
	print("-- Criterio 1: la hurtbox rival notifica la rotura de guardia --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]
	var hb := _hurtbox_de(rival)

	var roturas := [0]
	var golpes := [0]
	hb.guardia_rota.connect(func(_hitbox) -> void: roturas[0] += 1)
	hb.golpe_recibido.connect(func(_hitbox) -> void: golpes[0] += 1)

	# Un golpe normal NO rompe guardia: la senal no debe aparecer.
	atacante.ataque_normal()
	await _pasos(2)
	_comprobar("el golpe normal no dispara guardia_rota", roturas[0] == 0,
		"roturas=%d" % roturas[0])
	_comprobar("el golpe normal si cuenta como golpe_recibido", golpes[0] == 1,
		"golpes=%d" % golpes[0])

	# La carga SI la rompe.
	await _pasos(int(atacante.cooldown_golpe_normal * 60.0) + 5)
	atacante.iniciar_carga()
	atacante.soltar_carga()
	await _pasos(2)
	_comprobar("el golpe de carga dispara guardia_rota (criterio 1)", roturas[0] == 1,
		"roturas=%d" % roturas[0])
	_comprobar("y sigue contando como golpe_recibido", golpes[0] == 2,
		"golpes=%d" % golpes[0])

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_cooldown() -> void:
	print("-- Cooldown: no se pueden encadenar cargas --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]

	var lanzados := [0]
	atacante.ataque_ejecutado.connect(func(_tipo) -> void: lanzados[0] += 1)
	atacante.iniciar_carga()
	atacante.soltar_carga()
	atacante.iniciar_carga()
	_comprobar("la segunda carga no arranca en cooldown",
		not atacante.esta_cargando() and lanzados[0] == 1,
		"cargando=%s lanzados=%d" % [str(atacante.esta_cargando()), lanzados[0]])

	await _pasos(int(atacante.cooldown_carga * 60.0) + 5)
	atacante.iniciar_carga()
	_comprobar("terminado el cooldown se puede volver a cargar",
		atacante.esta_cargando())

	_soltar_todas()
	atacante.queue_free()
	arena["suelo"].queue_free()
	arena["rival"].queue_free()


func _prueba_cancelaciones() -> void:
	print("-- Cancelaciones: muerte e interrupciones cierran la carga sin golpear --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]

	atacante.iniciar_carga()
	await _pasos(10)
	atacante.cancelar_carga()
	_comprobar("cancelar_carga apaga el estado", not atacante.esta_cargando())
	_comprobar("cancelar_carga reinicia el nivel", is_equal_approx(atacante.carga_nivel(), 0.0))
	_comprobar("cancelar_carga no despacha golpe", _hitbox_de(atacante, 0) == null)
	_comprobar("cancelar_carga restaura el sprite",
		is_equal_approx(atacante.nodo_sprite.scale.x, 1.0))

	atacante.iniciar_carga()
	await _pasos(10)
	atacante.recibir_dano(9999)
	_comprobar("morrir en mitad de una carga la cancela", not atacante.esta_cargando())
	atacante.iniciar_carga()
	_comprobar("el muerto no inicia cargas", not atacante.esta_cargando())

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_end_to_end_teclado() -> void:
	print("-- End-to-end: J mantenida -> acumular -> soltar -> dano al rival --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	Input.action_press("carga_pesada")
	await _pasos(int(atacante.tiempo_carga_max * 60.0) + 5)
	_comprobar("mantener J acumula la carga por el camino real del InputMap",
		atacante.esta_cargando() and atacante.carga_nivel() > 0.9,
		"cargando=%s nivel=%.2f" % [str(atacante.esta_cargando()), atacante.carga_nivel()])

	Input.action_release("carga_pesada")
	await _pasos(2)
	var dano := 100 - rival.current_hp
	_comprobar("soltar J golpea al rival con el dano de carga llena",
		dano == roundi(atacante.dano_carga * atacante.multiplicador_carga_max),
		"dano=%d" % dano)
	_comprobar("el golpe llego como SUPER_PESADO_CARGA rompe-guardia",
		_hitbox_de(atacante, 0) != null and _hitbox_de(atacante, 0).rompe_guardia)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()
