extends SceneTree
## Suite de pruebas headless para OUFW-6 (escenario del Nivel 1).
##
## Ejecutar:
##   godot --headless --script res://tests/test_nivel_1.gd
##
## Carga el .tscn real del repositorio y deja correr la fisica de verdad con
## [method Input.action_press]. Verifica los criterios de aceptacion:
##   1. Capa Ground y Physics Layer Matrix: las princesas detectan el suelo.
##   2. Paredes invisibles: nadie sale del encuadre (ni con derrape ni con salto).
##   3. Ancho de la arena balanceado para las maniobras de evasion.
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const Nivel := preload("res://scripts/nivel_1_frontera.gd")
const RUTA_NIVEL := "res://escenas/nivel_1_frontera.tscn"

## Radio de la capsula de una princesa (ver crear_escenas.gd).
const RADIO_CUERPO := 12.0

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	print("=== OUFW-6: Nivel 1 \"La Frontera Despejada\" ===\n")

	_prueba_capas_con_nombre()
	_prueba_estructura()
	_prueba_suelo_y_paredes()
	await _prueba_camara()
	await _prueba_suelo_detectado()
	await _prueba_suelo_continuo()
	await _prueba_paredes_contienen()
	await _prueba_espacio_de_maniobra()
	await _prueba_combate_en_el_nivel()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


# --- Utilidades ---

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


func _soltar_todas() -> void:
	for accion in ["mover_izquierda", "mover_derecha", "salto", "agachar"]:
		Input.action_release(accion)


func _montar() -> Node2D:
	var escena := load(RUTA_NIVEL) as PackedScene
	if escena == null:
		return null
	var nivel := escena.instantiate() as Node2D
	root.add_child(nivel)
	return nivel


## Se espera un paso de fisica para que el nivel viejo no choque con el nuevo.
func _desmontar(nivel: Node) -> void:
	_soltar_todas()
	nivel.queue_free()
	await physics_frame


## Pone a la princesa con los pies en el suelo, en x, y sin velocidad.
func _colocar(p: Personaje, x: float) -> void:
	p.global_position = Vector2(x, Nivel.Y_APARICION)
	p.velocity = Vector2.ZERO


func _tamano_de(cuerpo: Node) -> Vector2:
	return ((cuerpo.get_node("Colision") as CollisionShape2D).shape as RectangleShape2D).size


# --- Pruebas sin fisica ---

func _prueba_capas_con_nombre() -> void:
	print("-- Physics Layer Matrix --")
	var nombres := {
		1: "Ground", 2: "Hurtbox", 3: "Hitbox", 4: "Personajes",
	}
	for numero: int in nombres:
		var real: String = ProjectSettings.get_setting(
			"layer_names/2d_physics/layer_%d" % numero, "")
		_comprobar("la capa %d se llama %s" % [numero, nombres[numero]],
			real == nombres[numero], "'%s'" % real)

	# Los valores en bruto del codigo tienen que coincidir con esos numeros de capa.
	_comprobar("los valores de Personaje coinciden con la matriz",
		Personaje.CAPA_GROUND == 1 and Personaje.CAPA_HURTBOX == 2
		and Personaje.CAPA_HITBOX == 4 and Personaje.CAPA_PERSONAJE == 8,
		"%d %d %d %d" % [Personaje.CAPA_GROUND, Personaje.CAPA_HURTBOX,
			Personaje.CAPA_HITBOX, Personaje.CAPA_PERSONAJE])


func _prueba_estructura() -> void:
	print("-- El nivel carga y trae todo cableado --")
	var nivel := _montar()
	_comprobar("el .tscn existe y se instancia", nivel != null)
	if nivel == null:
		return

	for ruta in ["Ambientacion", "Suelo", "ParedIzquierda", "ParedDerecha",
			"SpawnJugadora", "SpawnRival", "Jugadora", "Rival",
			"Jugadora/Controlador", "Camara"]:
		_comprobar("existe el nodo %s" % ruta, nivel.get_node_or_null(ruta) != null)

	var ctrl := nivel.get_node_or_null("Jugadora/Controlador") as ControladorJugador
	_comprobar("el controlador sigue cableado al rival",
		ctrl != null and ctrl.rival == nivel.get_node_or_null("Rival"))
	_comprobar("las princesas aparecen en sus spawns",
		(nivel.get_node("Jugadora") as Node2D).position
			== (nivel.get_node("SpawnJugadora") as Node2D).position
		and (nivel.get_node("Rival") as Node2D).position
			== (nivel.get_node("SpawnRival") as Node2D).position)
	nivel.free()


func _prueba_suelo_y_paredes() -> void:
	print("-- Suelo continuo y paredes invisibles --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return

	var suelo := nivel.get_node("Suelo") as StaticBody2D
	var tam_suelo := _tamano_de(suelo)
	var superficie := suelo.position.y - tam_suelo.y * 0.5
	_comprobar("la superficie del suelo esta en y = 0", is_zero_approx(superficie),
		"y=%.1f" % superficie)
	_comprobar("el suelo esta en la capa Ground", suelo.collision_layer == Personaje.CAPA_GROUND,
		str(suelo.collision_layer))
	_comprobar("el suelo no detecta nada (mascara 0)", suelo.collision_mask == 0,
		str(suelo.collision_mask))

	# Continuo y limpio: un solo suelo + dos paredes, sin obstaculos sueltos.
	var cuerpos := 0
	for hijo in nivel.get_children():
		if hijo is StaticBody2D:
			cuerpos += 1
	_comprobar("solo hay suelo y dos paredes, sin obstaculos", cuerpos == 3, str(cuerpos))

	for nombre in ["ParedIzquierda", "ParedDerecha"]:
		var pared := nivel.get_node(nombre) as StaticBody2D
		_comprobar("%s esta en la capa Ground" % nombre,
			pared.collision_layer == Personaje.CAPA_GROUND, str(pared.collision_layer))

		var solo_colision := true
		for hijo in pared.get_children():
			if not hijo is CollisionShape2D:
				solo_colision = false
		_comprobar("%s es invisible (solo colision)" % nombre, solo_colision)

		var borde_exterior := absf(pared.position.x) + _tamano_de(pared).x * 0.5
		_comprobar("el suelo cubre hasta bajo %s" % nombre,
			borde_exterior <= tam_suelo.x * 0.5,
			"pared hasta %.0f, suelo hasta %.0f" % [borde_exterior, tam_suelo.x * 0.5])
		_comprobar("%s es mas alta que cualquier salto" % nombre,
			_tamano_de(pared).y >= 400.0, "%.0f px" % _tamano_de(pared).y)

	# La cara interior de cada pared coincide con las medidas del nivel.
	var izq := nivel.get_node("ParedIzquierda") as StaticBody2D
	var der := nivel.get_node("ParedDerecha") as StaticBody2D
	var cara_izq := izq.position.x + _tamano_de(izq).x * 0.5
	var cara_der := der.position.x - _tamano_de(der).x * 0.5
	_comprobar("las caras interiores dejan el ancho jugable",
		is_equal_approx(cara_der - cara_izq, Nivel.ANCHO_JUGABLE),
		"%.0f px" % (cara_der - cara_izq))

	# La ambientacion es solo decoracion: no debe poder bloquear a nadie.
	var amb := nivel.get_node("Ambientacion")
	var colisionables := 0
	for nodo in amb.find_children("*", "CollisionObject2D", true, false):
		colisionables += 1
	_comprobar("la ambientacion no tiene colisiones", colisionables == 0, str(colisionables))
	nivel.free()


func _prueba_camara() -> void:
	print("-- Limites de camara --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	# La camara se registra como activa un frame despues de entrar al arbol.
	await physics_frame

	var camara := nivel.get_node("Camara") as Camera2D
	var mitad_ancho := Nivel.ANCHO_PANTALLA * 0.5
	_comprobar("limites izquierdo y derecho = encuadre",
		camara.limit_left == int(-mitad_ancho) and camara.limit_right == int(mitad_ancho),
		"%d..%d" % [camara.limit_left, camara.limit_right])
	_comprobar("la camara del nivel es la activa", camara.enabled and camara.is_current())

	# Un sprite pegado a la pared (centro + medio sprite) sigue dentro del encuadre.
	var borde_sprite: float = nivel.limite_derecho() - RADIO_CUERPO + Nivel.MARGEN_PARED
	_comprobar("un sprite pegado a la pared no se sale del encuadre",
		borde_sprite <= mitad_ancho, "borde=%.0f, encuadre=%.0f" % [borde_sprite, mitad_ancho])
	nivel.free()


# --- Pruebas con fisica ---

func _prueba_suelo_detectado() -> void:
	print("-- IsGrounded: las princesas detectan el suelo --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var rival := nivel.get_node("Rival") as Personaje

	await _pasos(60)
	_comprobar("la jugadora detecta el suelo", jugadora.en_suelo(),
		"y=%.1f" % jugadora.global_position.y)
	# El rival aun no tiene FSM (OUFW-11): sin nadie que llame move_and_slide,
	# is_on_floor() no se actualiza. Se le conduce por la API de Personaje.
	_comprobar("el rival aparece con los pies sobre el suelo",
		is_equal_approx(rival.global_position.y, Nivel.Y_APARICION),
		"y=%.1f" % rival.global_position.y)
	for _i in 30:
		rival.avanzar_movimiento(1.0 / Engine.physics_ticks_per_second, 0.0)
		await physics_frame
	_comprobar("el rival detecta el suelo (conducido por la API)", rival.en_suelo(),
		"y=%.1f" % rival.global_position.y)
	_comprobar("se asientan con los pies en y = 0",
		absf(jugadora.global_position.y - Nivel.Y_APARICION) < 1.5,
		"y=%.1f" % jugadora.global_position.y)
	_comprobar("la jugadora vive en la capa Personajes",
		jugadora.collision_layer == Personaje.CAPA_PERSONAJE, str(jugadora.collision_layer))
	_comprobar("su mascara incluye Ground",
		(jugadora.collision_mask & Personaje.CAPA_GROUND) != 0, str(jugadora.collision_mask))

	await _desmontar(nivel)

	# Contraprueba: sin Ground en la mascara el suelo no existe para la princesa.
	nivel = _montar()
	jugadora = nivel.get_node("Jugadora") as Personaje
	jugadora.collision_mask = Personaje.CAPA_PERSONAJE
	await _pasos(90)
	_comprobar("sin Ground en la mascara la jugadora atraviesa el suelo",
		not jugadora.en_suelo() and jugadora.global_position.y > 100.0,
		"y=%.0f" % jugadora.global_position.y)

	await _desmontar(nivel)


## Camina de pared a pared y cuenta los frames en que perdio el suelo: un hueco
## o una junta en la colision se veria aqui como frames sin suelo.
func _barrido(p: Personaje, accion: String, frames: int) -> int:
	var sin_suelo := 0
	Input.action_press(accion)
	for _i in frames:
		await physics_frame
		if not p.en_suelo():
			sin_suelo += 1
	Input.action_release(accion)
	return sin_suelo


func _prueba_suelo_continuo() -> void:
	print("-- El suelo es continuo de pared a pared --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var rival := nivel.get_node("Rival") as Personaje
	var tope: float = nivel.limite_derecho() - RADIO_CUERPO
	await _pasos(20)

	# Tramo izquierdo: del spawn a la pared izquierda.
	var sin_suelo := await _barrido(jugadora, "mover_izquierda", 240)
	_comprobar("tramo izquierdo: llega a la pared sin perder el suelo",
		sin_suelo == 0 and absf(jugadora.global_position.x + tope) < 1.5,
		"x=%.1f, frames sin suelo=%d" % [jugadora.global_position.x, sin_suelo])

	# Tramo completo hacia la derecha: se aparta al rival para que no estorbe.
	rival.global_position.x = -tope
	_colocar(jugadora, -300.0)
	await _pasos(20)
	sin_suelo = await _barrido(jugadora, "mover_derecha", 260)
	_comprobar("tramo derecho: cruza hasta la otra pared sin perder el suelo",
		sin_suelo == 0 and absf(jugadora.global_position.x - tope) < 1.5,
		"x=%.1f, frames sin suelo=%d" % [jugadora.global_position.x, sin_suelo])

	await _desmontar(nivel)


func _prueba_paredes_contienen() -> void:
	print("-- Las paredes contienen a la princesa --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var tope: float = nivel.limite_derecho() - RADIO_CUERPO
	var mitad_pantalla := Nivel.ANCHO_PANTALLA * 0.5
	await _pasos(30)

	# Caminar hasta la pared izquierda.
	Input.action_press("mover_izquierda")
	await _pasos(150)
	_soltar_todas()
	var x := jugadora.global_position.x
	_comprobar("camina hasta la pared izquierda y se detiene",
		absf(x + tope) < 1.5, "x=%.1f (tope %.1f)" % [x, -tope])
	_comprobar("su sprite no se sale por la izquierda",
		x - Nivel.MARGEN_PARED >= -mitad_pantalla, "borde=%.1f" % (x - Nivel.MARGEN_PARED))

	# Caminar hasta la pared derecha (se parte a la derecha del rival para no chocar con el).
	_colocar(jugadora, 300.0)
	await _pasos(10)
	Input.action_press("mover_derecha")
	await _pasos(150)
	_soltar_todas()
	x = jugadora.global_position.x
	_comprobar("camina hasta la pared derecha y se detiene",
		absf(x - tope) < 1.5, "x=%.1f (tope %.1f)" % [x, tope])
	_comprobar("su sprite no se sale por la derecha",
		x + Nivel.MARGEN_PARED <= mitad_pantalla, "borde=%.1f" % (x + Nivel.MARGEN_PARED))

	# Derrape contra la pared: el impulso no la atraviesa.
	_colocar(jugadora, 400.0)
	await _pasos(10)
	Input.action_press("agachar")
	Input.action_press("mover_derecha")
	var x_max := -INF
	for _i in 40:
		await physics_frame
		x_max = maxf(x_max, jugadora.global_position.x)
	_soltar_todas()
	_comprobar("el derrape no atraviesa la pared", x_max <= tope + 0.5,
		"x max=%.1f (tope %.1f)" % [x_max, tope])

	# Salto contra la pared (hacia atras respecto al rival, el mas largo).
	await _pasos(20)
	_colocar(jugadora, 400.0)
	await _pasos(10)
	Input.action_press("salto")
	Input.action_press("mover_derecha")
	x_max = -INF
	for _i in 60:
		await physics_frame
		x_max = maxf(x_max, jugadora.global_position.x)
	_soltar_todas()
	_comprobar("el salto no atraviesa la pared", x_max <= tope + 0.5,
		"x max=%.1f (tope %.1f)" % [x_max, tope])

	await _desmontar(nivel)


func _prueba_espacio_de_maniobra() -> void:
	print("-- Ancho de la arena vs. maniobras de evasion --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	var jugadora := nivel.get_node("Jugadora") as Personaje
	await _pasos(30)
	var x0 := jugadora.global_position.x

	# Derrape alejandose del rival: distancia mientras dura el impulso.
	Input.action_press("agachar")
	Input.action_press("mover_izquierda")
	var derrapando := false
	var distancia_derrape := 0.0
	for _i in 60:
		await physics_frame
		if jugadora.esta_derrapando():
			derrapando = true
			distancia_derrape = absf(jugadora.global_position.x - x0)
		elif derrapando:
			break
	_soltar_todas()
	await _pasos(30)

	# Salto hacia atras manteniendo la tecla hasta aterrizar.
	_colocar(jugadora, x0)
	await _pasos(10)
	Input.action_press("salto")
	Input.action_press("mover_izquierda")
	var en_el_aire := false
	var distancia_salto := 0.0
	for _i in 90:
		await physics_frame
		if not jugadora.en_suelo():
			en_el_aire = true
		elif en_el_aire:
			distancia_salto = absf(jugadora.global_position.x - x0)
			break
	_soltar_todas()

	var espacio_atras: float = (x0 - nivel.limite_izquierdo()) - RADIO_CUERPO
	var alcance_fuerte := jugadora.alcance_golpe_fuerte.x + 8.0
	var separacion := Nivel.X_APARICION * 2.0 - RADIO_CUERPO

	_comprobar("el derrape se midio", derrapando and distancia_derrape > 50.0,
		"%.0f px" % distancia_derrape)
	_comprobar("el salto hacia atras se midio", en_el_aire and distancia_salto > 50.0,
		"%.0f px" % distancia_salto)
	_comprobar("nadie alcanza al otro al aparecer (golpe fuerte)",
		separacion > alcance_fuerte,
		"separacion %.0f > alcance %.0f" % [separacion, alcance_fuerte])
	_comprobar("hay sitio para un derrape y un salto atras sin tocar la pared",
		espacio_atras >= distancia_derrape + distancia_salto,
		"%.0f px de espacio >= %.0f + %.0f" % [espacio_atras, distancia_derrape, distancia_salto])
	_comprobar("la arena cabe en el encuadre", Nivel.ANCHO_JUGABLE <= Nivel.ANCHO_PANTALLA,
		"%.0f <= %.0f" % [Nivel.ANCHO_JUGABLE, Nivel.ANCHO_PANTALLA])

	await _desmontar(nivel)


func _prueba_combate_en_el_nivel() -> void:
	print("-- El combate sigue funcionando con la nueva matriz --")
	var nivel := _montar()
	if nivel == null:
		_comprobar("el nivel se instancia", false)
		return
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var rival := nivel.get_node("Rival") as Personaje
	await _pasos(30)

	_colocar(jugadora, rival.global_position.x - 80.0)
	await _pasos(5)
	jugadora.ataque_normal()
	await _pasos(6)
	_comprobar("el golpe normal conecta con el rival",
		rival.current_hp == rival.hp_max - jugadora.dano_golpe_normal,
		"hp rival=%d" % rival.current_hp)
	_comprobar("el golpe no dania a quien lo lanza", jugadora.current_hp == jugadora.hp_max,
		"hp jugadora=%d" % jugadora.current_hp)

	await _desmontar(nivel)