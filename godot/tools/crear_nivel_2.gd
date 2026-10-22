extends SceneTree
## Genera el escenario del Nivel 2 "Bosque Encantado" (OUFW-14):
##
##   godot --headless --script res://tools/crear_nivel_2.gd
##
## Genera:
##   escenas/nivel_2_bosque.tscn         suelo, paredes, plataformas, camara y princesas
##   escenas/ambientacion_bosque.tscn    solo si NO existe (placeholders)
##
## La ambientacion no se regenera si ya existe, a proposito: es la parte que se edita a
## mano en Godot (sprites de Kenney). Para rehacerla, borrar el .tscn. Las medidas viven en
## scripts/nivel_arena.gd (compartidas) y scripts/nivel_2_bosque.gd (plataformas).
##
## Requiere escenas/princesa_*.tscn (tools/crear_escenas.gd).

const Util := preload("res://tools/utilidades_nivel.gd")
const Nivel := preload("res://scripts/nivel_2_bosque.gd")

const DIR_ESCENAS := "res://escenas"
const RUTA_NIVEL := DIR_ESCENAS + "/nivel_2_bosque.tscn"
const RUTA_AMBIENTACION := DIR_ESCENAS + "/ambientacion_bosque.tscn"

## El Bosque es el Capitulo 2: el rival entra con la dificultad de ese capitulo (OUFW-15).
const CAPITULO := 2

const COLOR_TRONCO := Color("#6b4a2f")
const COLOR_MUSGO := Color("#4fae6a")


func _init() -> void:
	_generar_tarde()


## Se difiere un frame por lo mismo que en crear_nivel_1.gd: set_owner() y make_current()
## exigen que el nodo ya este dentro del arbol.
func _generar_tarde() -> void:
	await process_frame

	if not _crear_ambientacion_si_falta():
		quit(1)
		return
	if not _crear_nivel():
		quit(1)
		return

	print("Nivel 2 generado correctamente.")
	quit(0)


func _crear_ambientacion_si_falta() -> bool:
	if FileAccess.file_exists(RUTA_AMBIENTACION):
		print("  ambientacion ya existe, se respeta: %s" % RUTA_AMBIENTACION)
		return true

	var amb := Node2D.new()
	amb.name = "Ambientacion"
	root.add_child(amb)

	var izq := -Nivel.ANCHO_PANTALLA * 0.5
	var arriba := Nivel.POSICION_CAMARA.y - Nivel.ALTO_PANTALLA * 0.5
	var abajo := Nivel.POSICION_CAMARA.y + Nivel.ALTO_PANTALLA * 0.5
	var ancho := Nivel.ANCHO_PANTALLA

	Util.franja(amb, "Cielo", Rect2(izq, arriba, ancho, -arriba), Color("#27405c"))
	Util.franja(amb, "Bruma", Rect2(izq, -140.0, ancho, 140.0), Color("#3a6a78"))
	# Troncos lejanos: siluetas oscuras que dan profundidad sin estorbar a las plataformas.
	var x_troncos := [-420.0, -230.0, -50.0, 140.0, 330.0]
	for i in x_troncos.size():
		Util.franja(amb, "TroncoLejano%d" % (i + 1),
			Rect2(x_troncos[i], arriba, 36.0, -arriba), Color("#1b3330"))
	Util.franja(amb, "Copas", Rect2(izq, arriba, ancho, 90.0), Color("#1c4d3d"))
	Util.franja(amb, "Tierra", Rect2(izq, 0.0, ancho, abajo), Color("#4a3626"))
	Util.franja(amb, "Musgo", Rect2(izq, 0.0, ancho, 18.0), Color("#3c8d5a"))

	root.remove_child(amb)
	var ok := Util.guardar(amb, RUTA_AMBIENTACION)
	amb.free()
	return ok


func _crear_nivel() -> bool:
	var nivel := Node2D.new()
	nivel.name = "Nivel2"
	nivel.set_script(Nivel)
	# Construir dentro del arbol, igual que en crear_nivel_1.gd.
	root.add_child(nivel)
	nivel.set("capitulo", CAPITULO)

	# --- Ambientacion: instancia de la escena editable a mano ---
	var amb: Node = (load(RUTA_AMBIENTACION) as PackedScene).instantiate()
	# Detras de las princesas (z 0) y con filtro nearest para el pixel-art.
	amb.z_index = -10
	amb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nivel.add_child(amb)
	amb.owner = nivel

	# --- Fisica: suelo continuo y paredes invisibles (capa Ground) ---
	var mitad := Nivel.ANCHO_JUGABLE * 0.5
	Util.cuerpo_estatico(nivel, "Suelo",
		Vector2(Nivel.ANCHO_PANTALLA + 2.0 * Nivel.GROSOR_PARED, Nivel.GROSOR_SUELO),
		Vector2(0.0, Nivel.GROSOR_SUELO * 0.5))

	var tam_pared := Vector2(Nivel.GROSOR_PARED, Nivel.ALTO_PARED)
	var y_pared := Nivel.GROSOR_SUELO - Nivel.ALTO_PARED * 0.5
	var x_pared := mitad + Nivel.GROSOR_PARED * 0.5
	Util.cuerpo_estatico(nivel, "ParedIzquierda", tam_pared, Vector2(-x_pared, y_pared))
	Util.cuerpo_estatico(nivel, "ParedDerecha", tam_pared, Vector2(x_pared, y_pared))

	# --- Plataformas de un solo sentido (capa Ground), cada una con su visual ---
	var plataformas := Node2D.new()
	plataformas.name = "Plataformas"
	nivel.add_child(plataformas)
	plataformas.owner = nivel
	for datos: Dictionary in Nivel.PLATAFORMAS:
		_crear_plataforma(plataformas, datos)

	# --- Puntos de aparicion ---
	var pos_jugadora := Vector2(-Nivel.X_APARICION, Nivel.Y_APARICION)
	var pos_rival := Vector2(Nivel.X_APARICION, Nivel.Y_APARICION)
	Util.marcador(nivel, "SpawnJugadora", pos_jugadora)
	Util.marcador(nivel, "SpawnRival", pos_rival)

	# --- Princesas ---
	var jugadora: Personaje = load("%s/princesa_dulcecito.tscn" % DIR_ESCENAS).instantiate()
	jugadora.name = "Jugadora"
	jugadora.position = pos_jugadora
	nivel.add_child(jugadora)
	jugadora.owner = nivel

	var rival: Personaje = load("%s/princesa_chocolatito.tscn" % DIR_ESCENAS).instantiate()
	rival.name = "Rival"
	rival.position = pos_rival
	nivel.add_child(rival)
	rival.owner = nivel

	# `rival` cableado: el flipper mira al rival y no al ultimo input.
	var ctrl := ControladorJugador.new()
	ctrl.name = "Controlador"
	ctrl.personaje = jugadora
	ctrl.rival = rival
	jugadora.add_child(ctrl)
	ctrl.owner = nivel

	# --- Camara: sus limites son el encuadre del nivel ---
	var camara := Camera2D.new()
	camara.name = "Camara"
	camara.position = Nivel.POSICION_CAMARA
	camara.limit_left = int(-Nivel.ANCHO_PANTALLA * 0.5)
	camara.limit_right = int(Nivel.ANCHO_PANTALLA * 0.5)
	camara.limit_top = int(Nivel.POSICION_CAMARA.y - Nivel.ALTO_PANTALLA * 0.5)
	camara.limit_bottom = int(Nivel.POSICION_CAMARA.y + Nivel.ALTO_PANTALLA * 0.5)
	nivel.add_child(camara)
	camara.make_current()
	camara.owner = nivel

	root.remove_child(nivel)
	var ok := Util.guardar(nivel, RUTA_NIVEL)
	nivel.free()
	return ok


## Una plataforma del Bosque: un tronco con una franja de musgo encima.
func _crear_plataforma(padre: Node, datos: Dictionary) -> void:
	Util.plataforma_una_via(padre, datos["nombre"], Nivel.rect_plataforma(datos),
		COLOR_TRONCO, COLOR_MUSGO, "Tronco", "Musgo")