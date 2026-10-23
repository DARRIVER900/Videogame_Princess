extends SceneTree
## Genera el escenario del Nivel 1 "La Frontera Despejada" (OUFW-6):
##
##   godot --headless --script res://tools/crear_nivel_1.gd
##
## Genera:
##   escenas/nivel_1_frontera.tscn       suelo, paredes, camara y princesas
##   escenas/ambientacion_frontera.tscn  solo si NO existe (placeholders)
##
## La ambientacion no se regenera si ya existe, a proposito: es la parte que se
## edita a mano en Godot (sprites de Kenney). Para rehacerla, borrar el .tscn.
## Las medidas viven en scripts/nivel_1_frontera.gd.
##
## Requiere escenas/princesa_*.tscn (tools/crear_escenas.gd).

const Nivel := preload("res://scripts/nivel_1_frontera.gd")

const DIR_ESCENAS := "res://escenas"
const RUTA_NIVEL := DIR_ESCENAS + "/nivel_1_frontera.tscn"
const RUTA_AMBIENTACION := DIR_ESCENAS + "/ambientacion_frontera.tscn"


func _init() -> void:
	_generar_tarde()


## Se difiere un frame por lo mismo que en crear_escenas.gd: set_owner() y
## make_current() exigen que el nodo ya este dentro del arbol.
func _generar_tarde() -> void:
	await process_frame

	if not _crear_ambientacion_si_falta():
		quit(1)
		return
	if not _crear_nivel():
		quit(1)
		return

	print("Nivel 1 generado correctamente.")
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

	_franja(amb, "Cielo", Rect2(izq, arriba, ancho, -arriba), Color("#9bd7ee"))
	_franja(amb, "Pradera", Rect2(izq, -60.0, ancho, 60.0), Color("#8ccf6f"))
	_franja(amb, "Tierra", Rect2(izq, 0.0, ancho, abajo), Color("#8a5a3b"))
	_franja(amb, "Pasto", Rect2(izq, 0.0, ancho, 18.0), Color("#4fae4a"))

	root.remove_child(amb)
	var ok := _guardar(amb, RUTA_AMBIENTACION)
	amb.free()
	return ok


func _franja(padre: Node2D, nombre: String, rect: Rect2, color: Color) -> void:
	var franja := ColorRect.new()
	franja.name = nombre
	franja.position = rect.position
	franja.size = rect.size
	franja.color = color
	padre.add_child(franja)
	franja.owner = padre


func _crear_nivel() -> bool:
	var nivel := Node2D.new()
	nivel.name = "Nivel1"
	nivel.set_script(Nivel)
	# Construir dentro del arbol, igual que en crear_escenas.gd.
	root.add_child(nivel)

	# --- Ambientacion: instancia de la escena editable a mano ---
	var amb: Node = (load(RUTA_AMBIENTACION) as PackedScene).instantiate()
	# Detras de las princesas (z 0) y con filtro nearest para el pixel-art. Se fija
	# aqui y no en la ambientacion para que editarla a mano no choque con esto.
	amb.z_index = -10
	amb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nivel.add_child(amb)
	amb.owner = nivel

	# --- Fisica: suelo continuo y paredes invisibles (capa Ground) ---
	var mitad := Nivel.ANCHO_JUGABLE * 0.5
	_cuerpo_estatico(nivel, "Suelo",
		Vector2(Nivel.ANCHO_PANTALLA + 2.0 * Nivel.GROSOR_PARED, Nivel.GROSOR_SUELO),
		Vector2(0.0, Nivel.GROSOR_SUELO * 0.5))

	var tam_pared := Vector2(Nivel.GROSOR_PARED, Nivel.ALTO_PARED)
	var y_pared := Nivel.GROSOR_SUELO - Nivel.ALTO_PARED * 0.5
	var x_pared := mitad + Nivel.GROSOR_PARED * 0.5
	_cuerpo_estatico(nivel, "ParedIzquierda", tam_pared, Vector2(-x_pared, y_pared))
	_cuerpo_estatico(nivel, "ParedDerecha", tam_pared, Vector2(x_pared, y_pared))

	# --- Puntos de aparicion ---
	var pos_jugadora := Vector2(-Nivel.X_APARICION, Nivel.Y_APARICION)
	var pos_rival := Vector2(Nivel.X_APARICION, Nivel.Y_APARICION)
	_marcador(nivel, "SpawnJugadora", pos_jugadora)
	_marcador(nivel, "SpawnRival", pos_rival)

	# --- Princesas ---
	var jugadora: Personaje = load("%s/princesa_dulcecito.tscn" % DIR_ESCENAS).instantiate()
	jugadora.name = "Jugadora"
	jugadora.position = pos_jugadora
	jugadora.collision_layer = Personaje.CAPA_PERSONAJE
	jugadora.collision_mask = Personaje.CAPA_GROUND | Personaje.CAPA_PERSONAJE
	nivel.add_child(jugadora)
	jugadora.owner = nivel

	var rival: Personaje = load("%s/princesa_chocolatito.tscn" % DIR_ESCENAS).instantiate()
	rival.name = "Rival"
	rival.position = pos_rival
	rival.collision_layer = Personaje.CAPA_PERSONAJE
	rival.collision_mask = Personaje.CAPA_GROUND | Personaje.CAPA_PERSONAJE
	nivel.add_child(rival)
	rival.owner = nivel

	# `rival` cableado: el flipper mira al rival y no al ultimo input.
	var ctrl := ControladorJugador.new()
	ctrl.name = "Controlador"
	ctrl.personaje = jugadora
	ctrl.rival = rival
	jugadora.add_child(ctrl)
	ctrl.owner = nivel

	# --- FSM del rival (OUFW-11): inactiva al abrir el nivel directamente para no
	# interferir con las suites de OUFW-6. El menu la activa al empezar la partida. ---
	var bot := ControladorBot.new()
	bot.name = "Bot"
	bot.personaje = rival
	bot.rival = jugadora
	bot.activo = false
	rival.add_child(bot)
	bot.owner = nivel

	# --- HUD y gestor de fin de combate (OUFW-5/OUFW-16) ---
	var capa := CanvasLayer.new()
	capa.name = "HUD"
	var etiqueta := Label.new()
	etiqueta.name = "Estado"
	etiqueta.position = Vector2(12.0, 8.0)
	etiqueta.add_theme_font_size_override("font_size", 14)
	capa.add_child(etiqueta)
	nivel.add_child(capa)
	etiqueta.owner = nivel
	capa.owner = nivel

	var gestor := CanvasLayer.new()
	gestor.name = "GestorCombate"
	gestor.layer = 10
	gestor.set_script(load("res://scripts/ui/gestor_combate.gd"))
	nivel.add_child(gestor)
	gestor.owner = nivel
	_construir_panel_fin(gestor, nivel)

	# --- Dialogo de novela visual (OUFW-13): oculto hasta que arranca la partida ---
	var dialogo: CanvasLayer = load("res://escenas/dialogo.tscn").instantiate()
	dialogo.name = "Dialogo"
	nivel.add_child(dialogo)
	dialogo.owner = nivel

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
	var ok := _guardar(nivel, RUTA_NIVEL)
	nivel.free()
	return ok


## Monta el panel de Victoria/Game Over dentro del [CanvasLayer] del gestor.
## Todos los nodos nuevos llevan [code]owner = raiz[/code] para que se serialicen.
func _construir_panel_fin(gestor: CanvasLayer, raiz: Node) -> void:
	var panel := Control.new()
	panel.name = "Panel"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	gestor.add_child(panel)
	panel.owner = raiz

	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(0, 0, 0, 0.62)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(fondo)
	fondo.owner = raiz

	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.text = "VICTORIA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 150.0)
	titulo.custom_minimum_size = Vector2(960.0, 0.0)
	titulo.add_theme_font_size_override("font_size", 48)
	panel.add_child(titulo)
	titulo.owner = raiz

	var reintentar := Button.new()
	reintentar.name = "BotonReintentar"
	reintentar.text = "Reintentar"
	reintentar.position = Vector2(390.0, 260.0)
	reintentar.custom_minimum_size = Vector2(180.0, 44.0)
	panel.add_child(reintentar)
	reintentar.owner = raiz

	var menu := Button.new()
	menu.name = "BotonMenu"
	menu.text = "Menu Principal"
	menu.position = Vector2(390.0, 320.0)
	menu.custom_minimum_size = Vector2(180.0, 44.0)
	panel.add_child(menu)
	menu.owner = raiz


## Cuerpo estatico en la capa Ground, sin mascara: no detecta nada, solo es detectado.
func _cuerpo_estatico(raiz: Node, nombre: String, tamano: Vector2, pos: Vector2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = nombre
	cuerpo.position = pos
	cuerpo.collision_layer = Personaje.CAPA_GROUND
	cuerpo.collision_mask = 0

	var forma := CollisionShape2D.new()
	forma.name = "Colision"
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	cuerpo.add_child(forma)

	raiz.add_child(cuerpo)
	cuerpo.owner = raiz
	forma.owner = raiz


func _marcador(raiz: Node, nombre: String, pos: Vector2) -> void:
	var m := Marker2D.new()
	m.name = nombre
	m.position = pos
	raiz.add_child(m)
	m.owner = raiz


func _guardar(raiz: Node, ruta: String) -> bool:
	var escena := PackedScene.new()
	var err := escena.pack(raiz)
	if err != OK:
		printerr("  pack(%s) -> %s" % [ruta, error_string(err)])
		return false
	err = ResourceSaver.save(escena, ruta)
	print("  escena %s -> %s" % [ruta, error_string(err)])
	if err != OK:
		return false
	_quitar_unique_ids(ruta)
	return true


## Mismo motivo que en crear_escenas.gd: sin los unique_id, regenerar no deja
## cambios falsos en git.
func _quitar_unique_ids(ruta: String) -> void:
	var regex := RegEx.new()
	regex.compile(" unique_id=\\d+")
	var original := FileAccess.get_file_as_string(ruta)
	var limpio := regex.sub(original, "", true)
	if limpio == original:
		return
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		printerr("  no se pudo limpiar %s" % ruta)
		return
	archivo.store_string(limpio)
	archivo.close()