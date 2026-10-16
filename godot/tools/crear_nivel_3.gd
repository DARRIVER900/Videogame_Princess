extends SceneTree
## Genera el escenario del Nivel 3 "Cumbres de Azucar" (OUFW-14):
##
##   godot --headless --script res://tools/crear_nivel_3.gd
##
## Genera:
##   escenas/nivel_3_cumbres.tscn        suelo, paredes, plataformas, camara y princesas
##   escenas/ambientacion_cumbres.tscn   solo si NO existe (placeholders)
##
## La ambientacion no se regenera si ya existe, a proposito: es la parte que se edita a
## mano en Godot (sprites de Kenney). Para rehacerla, borrar el .tscn. Las medidas viven en
## scripts/nivel_arena.gd (compartidas) y scripts/nivel_3_cumbres.gd (plataformas).
##
## Requiere escenas/princesa_*.tscn (tools/crear_escenas.gd).

const Util := preload("res://tools/utilidades_nivel.gd")
const Nivel := preload("res://scripts/nivel_3_cumbres.gd")

const DIR_ESCENAS := "res://escenas"
const RUTA_NIVEL := DIR_ESCENAS + "/nivel_3_cumbres.tscn"
const RUTA_AMBIENTACION := DIR_ESCENAS + "/ambientacion_cumbres.tscn"

## Las Cumbres son el Capitulo 3: el rival entra con la dificultad de ese capitulo (OUFW-15).
const CAPITULO := 3

const COLOR_TERRON := Color("#f08fb5")
const COLOR_GLASEADO := Color("#ffffff")


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

	print("Nivel 3 generado correctamente.")
	quit(0)


func _crear_ambientacion_si_falta() -> bool:
	if FileAccess.file_exists(RUTA_AMBIENTACION):
		print("  ambientacion ya existe, se respeta: %s" % RUTA_AMBIENTACION)
		return true

	var amb := Node2D.new()
	amb.name = "Ambientacion"
	root.add_child(amb)

	var izq := -Nivel.ANCHO_PANTALLA * 0.5
	var der := Nivel.ANCHO_PANTALLA * 0.5
	var arriba := Nivel.POSICION_CAMARA.y - Nivel.ALTO_PANTALLA * 0.5
	var abajo := Nivel.POSICION_CAMARA.y + Nivel.ALTO_PANTALLA * 0.5
	var ancho := Nivel.ANCHO_PANTALLA

	Util.franja(amb, "Cielo", Rect2(izq, arriba, ancho, -arriba), Color("#f7c9e2"))
	Util.franja(amb, "Nubes", Rect2(izq, -230.0, ancho, 60.0), Color("#fde6f1"))
	# Montanas de azucar lejanas (dos planos) para dar profundidad y sensacion de altura.
	# Poligonos SIMPLES (sin cruces ni tramos solapados): Godot los cierra uniendo el ultimo
	# punto con el primero, asi que la silueta va por arriba y la base queda recta.
	Util.poligono(amb, "CumbresLejanas", PackedVector2Array([
		Vector2(izq, -40.0), Vector2(-330.0, -260.0), Vector2(-150.0, -90.0),
		Vector2(100.0, -300.0), Vector2(250.0, -100.0), Vector2(350.0, -230.0),
		Vector2(der, -40.0),
	]), Color("#e8b4d8"))
	Util.poligono(amb, "CumbreCercanaIzquierda", PackedVector2Array([
		Vector2(-430.0, 0.0), Vector2(-300.0, -150.0), Vector2(-170.0, 0.0),
	]), Color("#d98ec0"))
	Util.poligono(amb, "CumbreCercanaDerecha", PackedVector2Array([
		Vector2(150.0, 0.0), Vector2(270.0, -170.0), Vector2(400.0, 0.0),
	]), Color("#d98ec0"))
	Util.franja(amb, "Azucar", Rect2(izq, 0.0, ancho, abajo), Color("#f3d9e6"))
	Util.franja(amb, "Glaseado", Rect2(izq, 0.0, ancho, 18.0), Color("#ffffff"))

	root.remove_child(amb)
	var ok := Util.guardar(amb, RUTA_AMBIENTACION)
	amb.free()
	return ok


func _crear_nivel() -> bool:
	var nivel := Node2D.new()
	nivel.name = "Nivel3"
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
		Util.plataforma_una_via(plataformas, datos["nombre"], Nivel.rect_plataforma(datos),
			COLOR_TERRON, COLOR_GLASEADO, "Terron", "Glaseado")

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