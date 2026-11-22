extends SceneTree
## Suite de pruebas headless para OUFW-14 (escenario del Nivel 3 "Cumbres de Azucar").
##
## Ejecutar:
##   godot --headless --script res://tests/test_nivel_3.gd
##
## Carga el .tscn real del repositorio y deja correr la fisica de verdad con
## [method Input.action_press]. Criterio de aceptacion: configuracion de plataformas y
## colisiones. No basta con que existan: hay que poder SUBIR a la cima peldano a peldano,
## pasar por debajo y no salirse del encuadre.
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const Nivel := preload("res://scripts/nivel_3_cumbres.gd")
const RUTA_NIVEL := "res://escenas/nivel_3_cumbres.tscn"

## Mitad de la altura de la capsula de una princesa (ver crear_escenas.gd).
const MITAD_CUERPO := 32.0
## Radio de la capsula de una princesa.
const RADIO_CUERPO := 12.0
## Margen minimo (px) que debe sobrar entre el salto y cada peldano: sin el, subir
## exigiria un salto perfecto.
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
	print("=== OUFW-14: Nivel 3 \"Cumbres de Azucar\" ===\n")

	_prueba_estructura()
	_prueba_plataformas_configuradas()
	_prueba_dificultad_y_camara()
	await _prueba_alcance_del_salto()
	await _prueba_peldanos_desde_el_suelo()
	await _prueba_altos_no_alcanzables_desde_suelo()
	await _prueba_pasar_por_debajo()
	await _prueba_ascenso_completo()
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


## Rect de la plataforma [param nombre] del nivel.
func _rect(nombre: String) -> Rect2:
	return Nivel.rect_plataforma(_datos(nombre))


# --- Pruebas sin fisica ---

func _prueba_estructura() -> void:
	print("-- El nivel carga y trae todo cableado --")
	var nivel := _montar()
	_comprobar("la escena carga", nivel != null)
	if nivel == null:
		return

	_comprobar("hereda de NivelArena y usa el script de las Cumbres",
		nivel is NivelArena and nivel is Nivel3Cumbres)
	_comprobar("es el Capitulo 3", (nivel as NivelArena).capitulo == 3,
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
	_comprobar("hay una plataforma por cada entrada de PLATAFORMAS (5)",
		contenedor.get_child_count() == Nivel.PLATAFORMAS.size()
		and Nivel.PLATAFORMAS.size() == 5,
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
		var terron := cuerpo.get_node_or_null("Terron") as ColorRect
		_comprobar("%s: visual alineado con la colision" % nombre,
			terron != null and terron.size.is_equal_approx(tam)
			and terron.position.is_equal_approx(-tam * 0.5))

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

	# Simetria: el reparto es justo, cada plataforma tiene su espejo (o es la del centro).
	var simetrica := true
	for datos: Dictionary in Nivel.PLATAFORMAS:
		var espejo_ok := false
		for otra: Dictionary in Nivel.PLATAFORMAS:
			if is_equal_approx(float(otra["centro_x"]), -float(datos["centro_x"])) \
					and is_equal_approx(float(otra["altura"]), float(datos["altura"])) \
					and is_equal_approx(float(otra["ancho"]), float(datos["ancho"])):
				espejo_ok = true
		simetrica = simetrica and espejo_ok
	_comprobar("la arena es simetrica: ningun lado tiene ventaja", simetrica)

	# Los spawns quedan bajo los terrones medios, pero el cuerpo de pie no toca ninguno.
	var spawns_libres := true
	for nombre_spawn in ["SpawnJugadora", "SpawnRival"]:
		var x := (nivel.get_node(nombre_spawn) as Marker2D).position.x
		var cuerpo := Rect2(x - RADIO_CUERPO, -2.0 * MITAD_CUERPO, 2.0 * RADIO_CUERPO,
			2.0 * MITAD_CUERPO)
		for r in rects:
			if cuerpo.intersects(r):
				spawns_libres = false
	_comprobar("el cuerpo de pie en cada spawn no toca ninguna plataforma", spawns_libres)

	# La cima queda dentro del encuadre de la camara con la princesa encima.
	var cam := nivel.get_node("Camara") as Camera2D
	var cabeza_en_cima := -float(_datos("TerronCima")["altura"]) - 2.0 * MITAD_CUERPO
	_comprobar("la princesa sobre la cima cabe en el encuadre de la camara",
		cabeza_en_cima > float(cam.limit_top), "cabeza=%.0f limite=%d" % [cabeza_en_cima, cam.limit_top])
	nivel.free()


func _prueba_dificultad_y_camara() -> void:
	print("-- Dificultad del Capitulo 3 y camara --")
	var nivel := _montar()
	var rival := nivel.get_node("Rival") as Personaje
	var jugadora := nivel.get_node("Jugadora") as Personaje
	_comprobar("el rival entra con la dificultad del Cap 3 (150 HP, dano x1.35)",
		rival.hp_max == 150 and is_equal_approx(rival.multiplicador_dano, 1.35)
		and rival.current_hp == 150,
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

## Mide cuanto sube de verdad un salto desde el suelo (en un tramo sin plataforma encima) y
## comprueba que CADA peldano de la escalera cabe en el con holgura.
func _prueba_alcance_del_salto() -> void:
	print("-- Alcance real del salto --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	await _colocar(jugadora, -440.0, Nivel.Y_APARICION)

	var y_inicio := jugadora.global_position.y
	var y_min := y_inicio
	await _saltar(0)
	for _i in 70:
		await physics_frame
		y_min = minf(y_min, jugadora.global_position.y)
	_altura_salto = y_inicio - y_min
	_comprobar("el salto sube entre 70 y 100 px", _altura_salto > 70.0 and _altura_salto < 100.0,
		"%.1f px" % _altura_salto)

	var bajo := float(_datos("TerronBajoIzquierdo")["altura"])
	var medio := float(_datos("TerronMedioIzquierdo")["altura"])
	var cima := float(_datos("TerronCima")["altura"])
	_comprobar("suelo -> bajo cabe en el salto con holgura (>= %.0f px)" % HOLGURA_SALTO,
		bajo <= _altura_salto - HOLGURA_SALTO, "peldano=%.0f salto=%.1f" % [bajo, _altura_salto])
	_comprobar("bajo -> medio cabe en el salto con holgura",
		medio - bajo <= _altura_salto - HOLGURA_SALTO,
		"peldano=%.0f salto=%.1f" % [medio - bajo, _altura_salto])
	_comprobar("medio -> cima cabe en el salto con holgura",
		cima - medio <= _altura_salto - HOLGURA_SALTO,
		"peldano=%.0f salto=%.1f" % [cima - medio, _altura_salto])
	_comprobar("el terron medio NO se alcanza desde el suelo", medio > _altura_salto,
		"altura=%.0f salto=%.1f" % [medio, _altura_salto])
	_comprobar("la cima NO se alcanza desde el suelo", cima > _altura_salto,
		"altura=%.0f salto=%.1f" % [cima, _altura_salto])
	await _desmontar(nivel)


## Saltando justo debajo de un terron bajo se atraviesa por abajo y se aterriza encima.
func _prueba_peldanos_desde_el_suelo() -> void:
	print("-- Subir a un terron bajo desde el suelo --")
	for nombre in ["TerronBajoIzquierdo", "TerronBajoDerecho"]:
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


## Bajo un terron medio (donde nacen las princesas) o bajo la cima, un salto desde el suelo
## sube un poco y se cae: los peldanos altos hay que ganarselos subiendo.
func _prueba_altos_no_alcanzables_desde_suelo() -> void:
	print("-- Los terrones altos no se alcanzan desde el suelo --")
	for nombre in ["TerronMedioIzquierdo", "TerronMedioDerecho", "TerronCima"]:
		var nivel := _montar()
		var jugadora := nivel.get_node("Jugadora") as Personaje
		await _colocar(jugadora, float(_datos(nombre)["centro_x"]), Nivel.Y_APARICION)
		await _saltar(0)
		await _pasos(70)
		_comprobar("%s: tras saltar bajo el vuelve al suelo" % nombre,
			_de_pie_en(jugadora, 0.0), "y=%.1f" % jugadora.global_position.y)
		await _desmontar(nivel)


## Caminando por el suelo desde la pared izquierda, ni los terrones bajos ni los medios
## frenan a la princesa (de lado se atraviesan).
func _prueba_pasar_por_debajo() -> void:
	print("-- Cruzar la arena por el suelo, bajo los terrones --")
	var nivel := _montar()
	var jugadora := nivel.get_node("Jugadora") as Personaje
	var medio := _rect("TerronMedioIzquierdo")
	await _colocar(jugadora, nivel.limite_izquierdo() + 20.0, Nivel.Y_APARICION)

	Input.action_press("mover_derecha")
	await _pasos(120)  # ~2 s a 220 px/s: cruza bajo y medio y llega al centro de la arena
	Input.action_release("mover_derecha")

	_comprobar("cruza bajo los terrones bajos y medios sin frenarse",
		jugadora.global_position.x > medio.end.x + 20.0,
		"x=%.1f (el terron medio termina en %.0f)" % [jugadora.global_position.x, medio.end.x])
	_comprobar("y sigue en el suelo, no la sube a ningun terron",
		_de_pie_en(jugadora, 0.0), "y=%.1f" % jugadora.global_position.y)
	await _desmontar(nivel)


## El recorrido completo por cada lado: suelo -> bajo -> medio -> cima.
func _prueba_ascenso_completo() -> void:
	print("-- Ascenso completo a la cima por cada lado --")
	for lado in [-1, 1]:
		var sufijo := "Izquierdo" if lado < 0 else "Derecho"
		var etiqueta := "izq" if lado < 0 else "der"
		var nivel := _montar()
		var jugadora := nivel.get_node("Jugadora") as Personaje
		var bajo_d := _datos("TerronBajo" + sufijo)
		var medio_d := _datos("TerronMedio" + sufijo)
		var cima_d := _datos("TerronCima")
		var bajo := Nivel.rect_plataforma(bajo_d)
		var medio := Nivel.rect_plataforma(medio_d)
		var cima := Nivel.rect_plataforma(cima_d)

		# 1) Suelo -> terron bajo: salto vertical justo debajo.
		await _colocar(jugadora, float(bajo_d["centro_x"]), Nivel.Y_APARICION)
		await _saltar(0)
		await _pasos(60)
		_comprobar("%s: del suelo al terron bajo" % etiqueta,
			_de_pie_en(jugadora, Nivel.y_superficie(bajo_d)),
			"y=%.1f" % jugadora.global_position.y)

		# 2) Terron bajo -> medio: a 10 px del borde interior, saltando hacia el centro.
		var borde_bajo := bajo.end.x if lado < 0 else bajo.position.x
		await _colocar(jugadora, borde_bajo + 10.0 * lado, _y_centro(bajo.position.y) - 2.0)
		await _saltar(-lado)
		await _esperar_aterrizaje(jugadora, 120)
		_comprobar("%s: del terron bajo al medio" % etiqueta,
			_de_pie_en(jugadora, Nivel.y_superficie(medio_d))
			and jugadora.global_position.x > medio.position.x
			and jugadora.global_position.x < medio.end.x,
			"x=%.1f y=%.1f" % [jugadora.global_position.x, jugadora.global_position.y])

		# 3) Terron medio -> cima: a 10 px del borde interior, saltando hacia el centro.
		var borde_medio := medio.end.x if lado < 0 else medio.position.x
		await _colocar(jugadora, borde_medio + 10.0 * lado, _y_centro(medio.position.y) - 2.0)
		await _saltar(-lado)
		await _esperar_aterrizaje(jugadora, 120)
		_comprobar("%s: del terron medio a la cima" % etiqueta,
			_de_pie_en(jugadora, Nivel.y_superficie(cima_d))
			and jugadora.global_position.x > cima.position.x
			and jugadora.global_position.x < cima.end.x,
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
		jugadora.global_position.x <= nivel.limite_derecho() - RADIO_CUERPO + 1.0,
		"x=%.1f limite=%.1f" % [jugadora.global_position.x, nivel.limite_derecho()])
	await _desmontar(nivel)
