extends SceneTree
## Suite de pruebas headless para OUFW-3 (colisiones de combate: Hitbox/Hurtbox).
##
## Ejecutar:
##   godot --headless --script res://tests/test_combate.gd
##
## Monta una arena minima (suelo + atacante con controlador + rival estatico) y
## verifica los tres criterios de aceptacion de la issue:
##   1. Las Hurtboxes cambian dinamicamente al agacharse (`S`) o derrapar (`S+A/D`).
##   2. Al colisionar un Hitbox activo con la Hurtbox rival, se llama a
##      `recibir_dano()` en el mismo frame, y una sola vez por golpe.
##   3. El cooldown y el consumo del hitbox cortan el multi-hitting indebido.
##
## Codigo de salida: 0 si todo pasa, 1 si algo falla.
##
## IMPORTANTE: [Personaje] no lee el teclado por su cuenta (a proposito, para que el
## bot de OUFW-11 reutilice la misma fisica y el mismo combate). Quien lee el
## InputMap es [ControladorJugador], asi que las pruebas de teclado pasan por el.

## Altura de aparicion del atacante: lejos del suelo para que caiga y se asiente.
const APARICION_Y := -300.0
## Altura a la que se deja al rival ESTATICO: no tiene controlador ni FSM (OUFW-11
## aun no existe), asi que no cae: se lo coloca ya con los pies en el suelo.
const SUELO_Y := -32.0


var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-3: Colisiones de combate (Hitbox/Hurtbox) ===\n")

	await _prueba_input_map()
	await _prueba_hurtbox_nace()
	await _prueba_hurtbox_encoge_agachado()
	await _prueba_hurtbox_encoge_derrape()
	await _prueba_golpe_normal()
	await _prueba_golpe_fuerte_knockback()
	await _prueba_facing_izquierda()
	await _prueba_hitbox_expira()
	await _prueba_cooldown()
	await _prueba_golpe_recibido_una_vez()
	await _prueba_muerto_no_ataca()
	await _prueba_escena_tiene_hurtbox()

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


## Crea una princesa con su [CollisionShape2D] y su sprite. [param con_controlador]
## se deja en false para el rival, que no debe leer el teclado. En el personaje se
## anade tambien la hurtbox, pero eso lo crea [method Personaje._ready] solo.
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


## Arena estandar de combate: atacante con controlador y rival estatico a
## [param distancia] px del atacante (positivo = a la derecha). El controlador del
## atacante queda cableado al rival, para que el flipper y los golpes apunten bien.
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


func _contar_hitboxes(p: Personaje) -> int:
	var n := 0
	for hijo in p.get_children():
		if hijo is Hitbox:
			n += 1
	return n


func _controlador_de(p: Personaje) -> ControladorJugador:
	return p.get_node_or_null("Controlador") as ControladorJugador


func _pasos(frames: int) -> void:
	for _i in frames:
		await physics_frame


func _asentar(p: Personaje) -> void:
	await _pasos(45)


func _soltar_todas() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "salto", "agachar",
			"golpe_normal", "golpe_fuerte"]:
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
	print("-- InputMap de combate (K / L) --")
	var esperadas := {
		"golpe_normal": [KEY_K],
		"golpe_fuerte": [KEY_L],
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


func _prueba_hurtbox_nace() -> void:
	print("-- La Hurtbox nace con todo Personaje (criterio 1: sus capas) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _pasos(1)

	var hb := _hurtbox_de(p)
	_comprobar("el personaje tiene Hurtbox propia", hb != null)
	if hb == null:
		p.queue_free()
		suelo.queue_free()
		return

	_comprobar("esta en la capa de hurtbox y detecta hitboxes",
		hb.collision_layer == Personaje.CAPA_HURTBOX
		and hb.collision_mask == Personaje.CAPA_HITBOX,
		"layer=%d mask=%d" % [hb.collision_layer, hb.collision_mask])
	_comprobar("nace de pie con la altura del cuerpo", is_equal_approx(hb.altura_actual(), 64.0),
		str(hb.altura_actual()))

	p.queue_free()
	suelo.queue_free()


func _prueba_hurtbox_encoge_agachado() -> void:
	print("-- Criterio 1: encoger la Hurtbox al agacharse (S) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(p)
	var hb := _hurtbox_de(p)

	Input.action_press("agachar")
	await _pasos(3)
	_comprobar("S activa la pose AGACHADO",
		p.estado_locomocion == Personaje.Locomocion.AGACHADO)
	_comprobar("la hurtbox encoge a la mitad",
		is_equal_approx(hb.altura_actual(), p.factor_altura_cuerpo() * 64.0)
		and is_equal_approx(hb.altura_actual(), 32.0), "altura=%.1f" % hb.altura_actual())
	_comprobar("los pies quedan anclados al suelo",
		is_equal_approx(hb.posicion_forma().y + hb.altura_actual() * 0.5, 32.0),
		"borde bajo=%.1f" % (hb.posicion_forma().y + hb.altura_actual() * 0.5))

	_soltar_todas()
	await _pasos(3)
	_comprobar("al volver de pie la hurtbox se restaura",
		is_equal_approx(hb.altura_actual(), 64.0), str(hb.altura_actual()))

	p.queue_free()
	suelo.queue_free()


func _prueba_hurtbox_encoge_derrape() -> void:
	print("-- Criterio 1: encoger la Hurtbox al derrapar (S + A/D) --")
	var suelo := _crear_suelo()
	var p := _crear_personaje(PrincesaDulcecito, 0.0)
	await _asentar(p)
	var hb := _hurtbox_de(p)

	Input.action_press("agachar")
	Input.action_press("mover_derecha")
	await _pasos(3)
	_comprobar("S + D entra en DERRAPE", p.esta_derrapando(),
		"locomocion=%d" % p.estado_locomocion)
	_comprobar("la hurtbox encoge al factor de derrape (0.6)",
		is_equal_approx(hb.altura_actual(), 64.0 * p.factor_altura_derrape),
		"altura=%.1f" % hb.altura_actual())
	_comprobar("los pies siguen anclados",
		is_equal_approx(hb.posicion_forma().y + hb.altura_actual() * 0.5, 32.0),
		"borde bajo=%.1f" % (hb.posicion_forma().y + hb.altura_actual() * 0.5))

	_soltar_todas()
	p.queue_free()
	suelo.queue_free()


func _prueba_golpe_normal() -> void:
	print("-- Golpe normal (K): alcance frontal, dano y un solo impacto --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	atacante.ataque_normal()
	var hitbox := _hitbox_de(atacante, 0)
	_comprobar("genera un Hitbox frontal", hitbox != null)
	if hitbox != null:
		_comprobar("el hitbox nace delante de la mirada", hitbox.position.x > 0.0,
			"x=%.1f" % hitbox.position.x)
		_comprobar("lleva el dano del golpe normal",
			hitbox.dano == atacante.dano_golpe_normal, "dano=%d" % hitbox.dano)
		_comprobar("lleva el tipo de ataque correcto",
			hitbox.tipo_ataque == Personaje.TipoAtaque.GOLPE_NORMAL)
		_comprobar("su volumen es el alcance configurado",
			(hitbox.get_node("Colision") as CollisionShape2D).shape.size
			== atacante.alcance_golpe_normal)

	await _pasos(2)
	_comprobar("el rival recibe el dano en el mismo frame (criterio 2)",
		rival.current_hp == 100 - atacante.dano_golpe_normal,
		"hp rival=%d" % rival.current_hp)
	_comprobar("el golpe no hiere al atacante (no self-hit)",
		atacante.current_hp == atacante.hp_max)

	# Longitud de la pelea: el golpe ya se consumio, nadie vuelve a ser golpeado.
	await _pasos(10)
	_comprobar("mantener el roce no multi-pega (criterio 3)",
		rival.current_hp == 100 - atacante.dano_golpe_normal,
		"hp rival=%d" % rival.current_hp)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_golpe_fuerte_knockback() -> void:
	print("-- Golpe fuerte (L): mas dano, mas alcance y empuje --")
	var arena := await _montar_combate(50.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	atacante.ataque_fuerte()
	var hitbox := _hitbox_de(atacante, 0)
	_comprobar("genera un Hitbox de area extendida", hitbox != null)
	if hitbox != null:
		_comprobar("el volumen es mas grande que el del golpe normal",
			(hitbox.get_node("Colision") as CollisionShape2D).shape.size
			== atacante.alcance_golpe_fuerte)
		_comprobar("lleva el empuje configurado", hitbox.empuje == atacante.empuje_golpe_fuerte,
			"empuje=%.0f" % hitbox.empuje)

	await _pasos(2)
	_comprobar("el rival recibe el dano fuerte",
		rival.current_hp == 100 - atacante.dano_golpe_fuerte,
		"hp rival=%d" % rival.current_hp)
	_comprobar("el golpe fuerte empuja al rival en la direccion de la mirada",
		is_equal_approx(rival.velocity.x, atacante.empuje_golpe_fuerte),
		"vx=%.1f" % rival.velocity.x)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_facing_izquierda() -> void:
	print("-- El golpe nace hacia el lado al que mira la princesa --")
	var arena := await _montar_combate(-60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]

	_comprobar("mirando al rival de la izquierda, la princesa mira a la izquierda",
		not atacante.mirando_a_la_derecha)

	atacante.ataque_normal()
	var hitbox := _hitbox_de(atacante, 0)
	_comprobar("el hitbox nace a la izquierda", hitbox != null and hitbox.position.x < 0.0,
		"x=%.1f" % (hitbox.position.x if hitbox else -999.0))

	await _pasos(2)
	_comprobar("el rival de la izquierda recibe el dano",
		rival.current_hp == 100 - atacante.dano_golpe_normal, "hp rival=%d" % rival.current_hp)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_hitbox_expira() -> void:
	print("-- La ventana activa del hitbox se agota sola --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]

	atacante.ataque_normal()
	var antes := _contar_hitboxes(atacante)
	_comprobar("el golpe nace vivo", antes == 1, "hitboxes=%d" % antes)

	await _pasos(12)  # 0.12 s de duracion => ~7-8 frames, con margen
	_comprobar("sin impactar, el hitbox se destruye solo",
		_contar_hitboxes(atacante) == 0, "hitboxes=%d" % _contar_hitboxes(atacante))

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_cooldown() -> void:
	print("-- Cooldown: el spam de tecla no encadena golpes --")
	var arena := await _montar_combate(1000.0)
	var atacante: Personaje = arena["atacante"]
	var lanzados := [0]
	atacante.ataque_ejecutado.connect(func(_tipo) -> void: lanzados[0] += 1)

	atacante.ataque_normal()
	atacante.ataque_normal()
	atacante.ataque_normal()
	_comprobar("tres pulsaciones en el mismo frame == un solo golpe",
		lanzados[0] == 1 and _contar_hitboxes(atacante) == 1,
		"lanzados=%d hitboxes=%d" % [lanzados[0], _contar_hitboxes(atacante)])

	await _pasos(11)  # cooldown_golpe_normal = 0.15 s => ~9 frames
	atacante.ataque_normal()
	_comprobar("terminado el cooldown se puede volver a golpear",
		lanzados[0] == 2, "lanzados=%d" % lanzados[0])

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_golpe_recibido_una_vez() -> void:
	print("-- End-to-end con teclado: K -> hitbox -> hurtbox -> recibir_dano --")
	var arena := await _montar_combate(60.0)
	var rival: Personaje = arena["rival"]
	var golpes := [0]
	var hb := _hurtbox_de(rival)
	hb.golpe_recibido.connect(func(_hitbox) -> void: golpes[0] += 1)

	Input.action_press("golpe_normal")
	await _pasos(2)
	_comprobar("K golpea al rival por el camino real del InputMap",
		rival.current_hp == 90, "hp rival=%d" % rival.current_hp)
	_comprobar("la hurtbox emitio golpe_recibido una sola vez", golpes[0] == 1,
		"golpes=%d" % golpes[0])

	await _pasos(10)
	_comprobar("el golpe consumido no vuelve a activarse (criterio 3)",
		rival.current_hp == 90 and golpes[0] == 1,
		"hp=%d golpes=%d" % [rival.current_hp, golpes[0]])

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_muerto_no_ataca() -> void:
	print("-- Un personaje muerto no ataca ni recibe mas dano --")
	var arena := await _montar_combate(60.0)
	var atacante: Personaje = arena["atacante"]
	var rival: Personaje = arena["rival"]
	var lanzados := [0]
	atacante.ataque_ejecutado.connect(func(_tipo) -> void: lanzados[0] += 1)

	atacante.recibir_dano(9999)
	_comprobar("el atacante muere al vaciarle la vida", atacante.esta_muerto)

	atacante.ataque_normal()
	_comprobar("el muerto no suelta golpes",
		lanzados[0] == 0 and _contar_hitboxes(atacante) == 0,
		"lanzados=%d" % lanzados[0])
	await _pasos(2)
	_comprobar("el rival no recibe dano de un muerto", rival.current_hp == 100)
	_comprobar("el muerto no revive con el dano", atacante.current_hp == 0
		and atacante.esta_muerto)

	_soltar_todas()
	arena["atacante"].queue_free()
	arena["rival"].queue_free()
	arena["suelo"].queue_free()


func _prueba_escena_tiene_hurtbox() -> void:
	print("-- Las escenas del repositorio heredan la Hurtbox sin cableado --")
	var escena: PackedScene = load("res://escenas/princesa_dulcecito.tscn")
	var p := escena.instantiate() as Personaje
	root.add_child(p)
	await _pasos(1)
	var hb := _hurtbox_de(p)
	_comprobar("la princesa de la escena tiene Hurtbox", hb != null)
	_comprobar("su hurtbox nace de pie", hb != null and is_equal_approx(hb.altura_actual(), 64.0),
		str(hb.altura_actual()) if hb else "no hay hurtbox")
	p.queue_free()