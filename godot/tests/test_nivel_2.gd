extends SceneTree
## Suite de pruebas headless para OUFW-14 (escenario del Nivel 2 "Bosque Encantado").
##
## Ejecutar:
##   godot --headless --script res://tests/test_nivel_2.gd
##
## Carga el .tscn real del repositorio y deja correr la fisica de verdad con
## [method Input.action_press]. Criterio de aceptacion: configuracion de plataformas y
## colisiones. No basta con que existan: hay que poder SUBIR a ellas, pasar por debajo y
## no salirse del encuadre.
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const Nivel := preload("res://scripts/nivel_2_bosque.gd")
const RUTA_NIVEL := "res://escenas/nivel_2_bosque.tscn"

## Mitad de la altura de la capsula de una princesa (ver crear_escenas.gd).
const MITAD_CUERPO := 32.0
## Margen minimo (px) que debe sobrar entre el salto y la altura de una plataforma: sin
## el, subir exigiria un salto perfecto.
const HOLGURA_SALTO := 15.0

var _fallos: int = 0
var _total: int = 0
## Altura maxima del salto, medida en _prueba_alcance_del_salto.
var _altura_salto: float = 0.0


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	# Un frame para que el arbol este vivo y los _ready (dificultad incluida) corran.
	await process_frame
	print("=== OUFW-14: Nivel 2 \"Bosque Encantado\" ===\n")

	_prueba_estructura()
	_prueba_plataformas_configuradas()
	_prueba_dificultad_y_camara()
	await _prueba_alcance_del_salto()
	await _prueba_subir_a_tronco()
	await _prueba_pasar_por_debajo()
	await _prueba_rama_no_alcanzable_desde_suelo()
	await _prueba_tronco_a_rama()
	await _prueba_paredes_siguen_conteniendo()

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


func _desmontar(nivel: Node) -> void:
	_soltar_todas()
	nivel.queue_free()
	await physics_frame


func _datos(nombre: String) -> Dictionary:
	for d: Dictionary in Nivel.PLATAFORMAS:
		if d["nombre"] == nombre:
			return d
	return {}


## Pone a la princesa con el centro en (x, y), sin velocidad, y espera a que se asiente.
func _colocar(p: Personaje, x: float, y: float) -> void:
	p.global_position = Vector2(x, y)
	p.velocity = Vector2.ZERO
	await _pasos(25)


## Y del centro de una princesa de pie sobre una superficie en [param y_superficie].
func _y_centro(y_superficie: float) -> float:
	return y_superficie - MITAD_CUERPO


func _de_pie_en(p: Personaje, y_superficie: float) -> bool:
	return absf(p.global_position.y - _y_centro(y_superficie)) < 1.5 and p.en_suelo()


## Salta una vez (pulsacion corta) con la direccion indicada: -1, 0 o 1.
func _saltar(direccion: int) -> void:
	match direccion:
		1: Input.action_press("mover_derecha")
		-1: Input.action_press("mover_izquierda")
	Input.action_press("salto")
	await _pasos(3)
	Input.action_release("salto")


## Espera a que la princesa vuelva a pisar algo tras un salto y SUELTA las teclas en ese
## instante: si siguiera caminando cruzaria la plataforma y se caeria por el otro lado.
func _esperar_aterrizaje(p: Personaje, max_frames: int) -> void:
	await _pasos(8)  # que despegue antes de empezar a vigilar el aterrizaje
	for _i in max_frames:
		if p.en_suelo():
			break
		await physics_frame
	_soltar_todas()
	await _pasos(10)


# --- Pruebas sin fisica ---

func _prueba_estructura() -> void:
	print("-- El nivel carga y trae todo cableado --")
	var nivel := _montar()
	_comprobar("la escena carga", nivel != null)
	if nivel == null:
		return

	_comprobar("hereda de NivelArena y usa el script del Bosque",
		nivel is NivelArena and nivel is Nivel2Bosque)
	_comprobar("es el Capitulo 2", (nivel as NivelArena).capitulo == 2,
		str((nivel as NivelArena).capitulo))
	for nombre in ["Ambientacion", "Suelo", "ParedIzquierda", "ParedDerecha", "Plataformas",
			"SpawnJugadora", "SpawnRival", "Jugadora", "Rival", "Camara"]:
		_comprobar("existe el nodo %s" % nombre, nivel.get_node_or_null(nombre) != null)

	var amb := nivel.get_node("Ambientacion") as CanvasItem
	_comprobar("la ambientacion va detras de las princesas (z -10)", amb.z_index == -10,
		str(amb.z_index))

	var ctrl := nivel.get_node("Jugadora/Controlador") as ControladorJugador
	_comprobar("el controlador de la jugadora apunta al rival",
		ctrl != null and ctrl.rival == nivel.get_node("Rival"))
	nivel.free()


func _prueba_plataformas_configuradas() -> void:
	print("-- Configuracion de plataformas y colisiones --")
	var nivel := _montar()
	var contenedor := nivel.get_node("Plataformas")
	_comprobar("hay una plataforma por cada entrada de PLATAFORMAS (3)",
		contenedor.get_child_count() == Nivel.PLATAFORMAS.size()
		and Nivel.PLATAFORMAS.size() == 3,
		"%d" % contenedor.get_child_count())

	var rects: Array[Rect2] = []
	for datos: Dictionary in Nivel.PLATAFORMAS:
		var nombre: String = datos["nombre"]
		var cuerpo := contenedor.get_node_or_null(nombre) as StaticBody2D
		_comprobar("%s es un StaticBody2D" % nombre, cuerpo != null)
		if cuerpo == null:
			continue
		var forma := cuerpo.get_node("Colision") as CollisionShape2D
		var tam := (forma.shape as RectangleShape2D).size
		var esperado := Nivel.rect_plataforma(datos)

		_comprobar("%s: capa Ground y sin mascara" % nombre,
			cuerpo.collision_layer == Personaje.CAPA_GROUND and cuerpo.collision_mask == 0,
			"layer=%d mask=%d" % [cuerpo.collision_layer, cuerpo.collision_mask])
		_comprobar("%s: colision de UN SOLO SENTIDO" % nombre, forma.one_way_collision)
		_comprobar("%s: tamano de colision = datos" % nombre, tam.is_equal_approx(esperado.size),
			str(tam))
		_comprobar("%s: la superficie esta a %.0f px del suelo" % [nombre, datos["altura"]],
			is_equal_approx(cuerpo.position.y - tam.y * 0.5, -float(datos["altura"])),
			"y_sup=%.1f" % (cuerpo.position.y - tam.y * 0.5))
		_comprobar("%s: centrada en x=%.0f" % [nombre, datos["centro_x"]],
			is_equal_approx(cuerpo.position.x, float(datos["centro_x"])),
			"x=%.1f" % cuerpo.position.x)

		# El visual sale del mismo rect: no puede quedar desfasado de la colision.
		var tronco := cuerpo.get_node_or_null("Tronco") as ColorRect
		_comprobar("%s: visual alineado con la colision" % nombre,
			tronco != null and tronco.size.is_equal_approx(tam)
			and tronco.position.is_equal_approx(-tam * 0.5))

		_comprobar("%s: queda dentro de las paredes" % nombre,
			esperado.position.x >= nivel.limite_izquierdo()
			and esperado.end.x <= nivel.limite_derecho(),
			"%.0f..%.0f" % [esperado.position.x, esperado.end.x])
		rects.append(esperado)

	var sin_solape := true
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				sin_solape = false
	_comprobar("ninguna plataforma se solapa con otra", sin_solape)

	# Los spawns salen en el suelo: nada encima que estorbe el primer salto.
	var spawns_libres := true
	for nombre_spawn in ["SpawnJugadora", "SpawnRival"]:
		var x := (nivel.get_node(nombre_spawn) as Marker2D).position.x
		for r in rects:
			if x + 12.0 > r.position.x and x - 12.0 < r.end.x:
				spawns_libres = false
	_comprobar("los spawns no quedan bajo ninguna plataforma", spawns_libres)
	nivel.free()


func _prueba_dificultad_y_camara() -> void:
	print("-- Dificultad del Capitulo 2 y camara --")
	var nivel := _montar()
	var rival := nivel.get_node("Rival") as Personaje
	var jugadora := nivel.get_node("Jugadora") as Personaje
	_comprobar("el rival entra con la dificultad del Cap 2 (130 HP, dano x1.10)",
		rival.hp_max == 130 and is_equal_approx(rival.multiplicador_dano, 1.1)
		and rival.current_hp == 130,
		"hp=%d/%d dano=%.2f" % [rival.current_hp, rival.hp_max, rival.multiplicador_dano])
	_comprobar("la jugadora no se toca (100 HP, dano x1.0)",
		jugadora.hp_max == 100 and is_equal_approx(jugadora.multiplicador_dano, 1.0))

	var cam := nivel.get_node("Camara") as Camera2D
	_comprobar("la camara encuadra la arena entera",
		cam.limit_left == -480 and cam.limit_right == 480
		and cam.position.is_equal_approx(Nivel.POSICION_CAMARA),
		"%d..%d" % [cam.limit_left, cam.limit_right])
	nivel.free()


# --- Pruebas con fisica real ---

## Mide cuanto sube de verdad un salto desde el suelo (en un tramo sin plataforma encima).
func _prueba_alcance_del_salto() -> void:
	print("-- Alcance real del salto --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	await _colocar(jugadora, -400.0, Nivel.Y_APARICION)

	var y_inicio := jugadora.global_position.y
	var y_min := y_inicio
	await _saltar(0)
	for _i in 70:
		await physics_frame
		y_min = minf(y_min, jugadora.global_position.y)
	_altura_salto = y_inicio - y_min
	_comprobar("el salto sube entre 70 y 100 px", _altura_salto > 70.0 and _altura_salto < 100.0,
		"%.1f px" % _altura_salto)

	var tronco: Dictionary = _datos("TroncoIzquierdo")
	var rama: Dictionary = _datos("RamaCentral")
	_comprobar("los troncos se alcanzan desde el suelo con holgura (>= %.0f px)" % HOLGURA_SALTO,
		float(tronco["altura"]) <= _altura_salto - HOLGURA_SALTO,
		"altura=%.0f salto=%.1f" % [tronco["altura"], _altura_salto])
	_comprobar("la rama NO se alcanza desde el suelo",
		float(rama["altura"]) > _altura_salto,
		"altura=%.0f salto=%.1f" % [rama["altura"], _altura_salto])
	_comprobar("la rama se alcanza desde un tronco con holgura",
		float(rama["altura"]) - float(tronco["altura"]) <= _altura_salto - HOLGURA_SALTO,
		"desnivel=%.0f salto=%.1f" % [float(rama["altura"]) - float(tronco["altura"]), _altura_salto])
	await _desmontar(nivel)


## Saltando justo debajo del tronco se atraviesa por abajo y se aterriza encima.
func _prueba_subir_a_tronco() -> void:
	print("-- Subir a un tronco desde el suelo --")
	for nombre in ["TroncoIzquierdo", "TroncoDerecho"]:
		var nivel := _montar()
		var jugadora := nivel.get_node("Jugadora") as Personaje
		var datos := _datos(nombre)
		await _colocar(jugadora, float(datos["centro_x"]), Nivel.Y_APARICION)
		await _saltar(0)
		await _pasos(60)
		_comprobar("%s: la princesa acaba de pie encima" % nombre,
			_de_pie_en(jugadora, Nivel.y_superficie(datos)),
			"y=%.1f esperado=%.1f" % [jugadora.global_position.y,
				_y_centro(Nivel.y_superficie(datos))])
		await _desmontar(nivel)


## Caminando por el suelo bajo un tronco no se choca con el (de lado se atraviesa).
func _prueba_pasar_por_debajo() -> void:
	print("-- Pasar por debajo de un tronco --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var tronco := Nivel.rect_plataforma(_datos("TroncoIzquierdo"))
	await _colocar(jugadora, tronco.position.x - 40.0, Nivel.Y_APARICION)

	Input.action_press("mover_derecha")
	await _pasos(90)  # ~1.5 s a 220 px/s: cruza los 160 px del tronco con margen
	Input.action_release("mover_derecha")

	_comprobar("cruza de lado sin que el tronco la frene",
		jugadora.global_position.x > tronco.end.x + 20.0,
		"x=%.1f (tronco termina en %.0f)" % [jugadora.global_position.x, tronco.end.x])
	_comprobar("y sigue en el suelo, no la sube al tronco",
		_de_pie_en(jugadora, 0.0), "y=%.1f" % jugadora.global_position.y)
	await _desmontar(nivel)


## Bajo el centro, la rama (120 px) queda fuera del salto: se sube un poco y se cae.
func _prueba_rama_no_alcanzable_desde_suelo() -> void:
	print("-- La rama no se alcanza desde el suelo --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	await _colocar(jugadora, 0.0, Nivel.Y_APARICION)
	await _saltar(0)
	await _pasos(70)
	_comprobar("tras saltar bajo la rama vuelve al suelo",
		_de_pie_en(jugadora, 0.0), "y=%.1f" % jugadora.global_position.y)
	await _desmontar(nivel)


## El recorrido completo: desde el tronco se salta hasta la rama, la posicion alta.
func _prueba_tronco_a_rama() -> void:
	print("-- Del tronco a la rama --")
	for lado in [-1, 1]:
		var nivel := _montar()
		var jugadora := nivel.get_node("Jugadora") as Personaje
		var tronco := Nivel.rect_plataforma(_datos("TroncoIzquierdo" if lado < 0 else "TroncoDerecho"))
		var rama := _datos("RamaCentral")
		var borde_interior := tronco.end.x if lado < 0 else tronco.position.x
		var nombre_lado := "izq" if lado < 0 else "der"

		# De pie sobre el tronco, a 10 px de su borde interior (el mas cercano a la rama).
		await _colocar(jugadora, borde_interior + 10.0 * lado,
			_y_centro(tronco.position.y) - 2.0)
		_comprobar("%s: arranca de pie sobre el tronco" % nombre_lado,
			_de_pie_en(jugadora, tronco.position.y),
			"y=%.1f" % jugadora.global_position.y)

		await _saltar(-lado)  # hacia la rama, que esta en el centro
		await _esperar_aterrizaje(jugadora, 120)
		var rect_rama := Nivel.rect_plataforma(rama)
		_comprobar("%s: aterriza de pie sobre la rama" % nombre_lado,
			_de_pie_en(jugadora, Nivel.y_superficie(rama))
			and jugadora.global_position.x > rect_rama.position.x
			and jugadora.global_position.x < rect_rama.end.x,
			"x=%.1f y=%.1f" % [jugadora.global_position.x, jugadora.global_position.y])
		await _desmontar(nivel)


## Con plataformas en juego, las paredes siguen conteniendo: nadie sale del encuadre.
func _prueba_paredes_siguen_conteniendo() -> void:
	print("-- Las paredes siguen conteniendo --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	await _colocar(jugadora, nivel.limite_derecho() - 60.0, Nivel.Y_APARICION)
	Input.action_press("mover_derecha")
	await _pasos(60)
	Input.action_release("mover_derecha")
	_comprobar("contra la pared derecha no sale del encuadre",
		jugadora.global_position.x <= nivel.limite_derecho() - 12.0 + 1.0,
		"x=%.1f limite=%.1f" % [jugadora.global_position.x, nivel.limite_derecho()])
	await _desmontar(nivel)
