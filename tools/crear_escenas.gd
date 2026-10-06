extends SceneTree
## Genera las escenas del proyecto a partir del codigo, para que ningun valor
## quede duplicado a mano entre una escena y otra. Ejecutar tras cambiar un nodo:
##
##   godot --headless --script res://tools/crear_escenas.gd
##
## Genera:
##   recursos/placeholder_dulcecito.png / placeholder_chocolatito.png
##   escenas/princesa_dulcecito.tscn  escenas/princesa_chocolatito.tscn
##   escenas/arena_movimiento.tscn    (arena de pruebas de OUFW-2)
##
## IMPORTANTE: estas escenas son el HARNESS de pruebas de OUFW-2, no la arena
## de produccion. El graybox del Capitulo 1 es OUFW-6.

const DIR_ESCENAS := "res://escenas"
const DIR_RECURSOS := "res://recursos"
const ALTO_CUERPO := 64.0
const ANCHO_CUERPO := 48.0

## Marcado si alguna textura no se pudo resolver, normalmente porque los .png se
## acaban de crear y Godot aun no los ha importado.
var _textura_pendiente := false


func _init() -> void:
	_generar_tarde()


## Se difiere un frame. Durante `_init()` la SceneTree todavia no esta inicializada,
## asi que ningun nodo esta "inside the tree" y Godot rechaza `set_owner()` y
## `make_current()`; como `PackedScene.pack()` solo serializa los nodos con owner,
## sin esta espera se guardarian escenas vacias.
func _generar_tarde() -> void:
	await process_frame

	_crear_directorios()
	_generar_texturas()
	_crear_escenas_de_princesa(PrincesaDulcecito, "princesa_dulcecito", Color("#e78ac3"))
	_crear_escenas_de_princesa(PrincesaChocolatito, "princesa_chocolatito", Color("#a9744f"))
	_crear_arena_de_prueba()
	_fijar_escena_principal()

	if _textura_pendiente:
		printerr("\nTexturas recien creadas e sin importar. Ejecuta y vuelve a correr:")
		printerr("  godot --headless --import --path .")
		printerr("  godot --headless --script res://tools/crear_escenas.gd")
		# Codigo 2 para distinguirlo de un fallo real (1): las escenas quedan
		# generadas pero sin sprite, y hay que rehacerlas antes de commitear.
		quit(2)
		return

	print("Escenas generadas correctamente.")
	quit(0)


func _crear_directorios() -> void:
	for dir: String in [DIR_ESCENAS, DIR_RECURSOS]:
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))


## Placeholder asimetrico: el ojo va pegado al borde DERECHO, asi que el volteo
## del Sprite Flipper (criterio 3) se distingue de un vistazo en el playtest.
func _generar_texturas() -> void:
	var cfg := {
		"dulcecito": Color("#e78ac3"),
		"chocolatito": Color("#a9744f"),
	}
	for nombre: String in cfg:
		var ruta := "%s/placeholder_%s.png" % [DIR_RECURSOS, nombre]
		# Solo se crea si no existe: reescribir el .png invalida su .import y
		# deja la textura ilegible hasta el siguiente --import. En un clon nuevo
		# el archivo y su .import llegan del repositorio, asi que se respeta.
		if FileAccess.file_exists(ruta):
			continue

		var img := Image.create(int(ANCHO_CUERPO), int(ALTO_CUERPO), false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.fill_rect(Rect2i(4, 8, 40, 56), cfg[nombre])
		img.fill_rect(Rect2i(4, 0, 40, 8), Color("#ffd700"))   # corona
		# Mancha de jarabe oscuro, igual que describe el GDD para Dulcecito.
		img.fill_rect(Rect2i(8, 48, 14, 10), Color(0.2, 0.05, 0.1, 0.65))
		# Ojo asimetrico: eje de la mirada.
		img.fill_rect(Rect2i(30, 18, 9, 9), Color.WHITE)
		img.fill_rect(Rect2i(34, 20, 5, 5), Color("#2b1b3a"))
		# Asa del vestido a la derecha, refuerza el sentido de la mirada.
		img.fill_rect(Rect2i(40, 34, 6, 16), Color(1, 1, 1, 0.35))

		var err := img.save_png(ruta)
		print("  textura %s -> %s" % [ruta, error_string(err)])


func _crear_escenas_de_princesa(tipo: Script, nombre_archivo: String, _tinte: Color) -> void:
	var raiz: Personaje = tipo.new()
	raiz.name = "Princesa"
	# Obligatorio: set_owner exige que el nodo este dentro del arbol, y sin owner
	# los hijos no se serializarian y la escena se guardaria vacia.
	root.add_child(raiz)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	# El generador de texturas usa el sufijo sin el prefijo "princesa_":
	# princesa_dulcecito.tscn -> placeholder_dulcecito.png
	var ruta_textura := "%s/placeholder_%s.png" % [
		DIR_RECURSOS, nombre_archivo.trim_prefix("princesa_"),
	]
	sprite.texture = load(ruta_textura)
	if sprite.texture == null:
		# Ocurre solo la primera vez en una maquina nueva: los .png acaban de
		# crearse y Godot no los ha importado. Sin este aviso se guardarian
		# escenas sin sprite y nadie se daria cuenta hasta abrir el editor.
		_textura_pendiente = true
		printerr("  textura sin importar: %s" % ruta_textura)
	raiz.add_child(sprite)
	sprite.owner = raiz

	var colision := CollisionShape2D.new()
	colision.name = "Colision"
	var capsula := CapsuleShape2D.new()
	capsula.height = ALTO_CUERPO
	capsula.radius = 12.0
	colision.shape = capsula
	raiz.add_child(colision)
	colision.owner = raiz

	# La colision queda centrada en el origen: los pies tocan el suelo cuando
	# position.y es -ALTO_CUERPO/2. Igual que asumen las pruebas de OUFW-2.
	root.remove_child(raiz)
	_guardar(raiz, "%s/%s.tscn" % [DIR_ESCENAS, nombre_archivo])
	raiz.free()


func _crear_arena_de_prueba() -> void:
	var arena := Node2D.new()
	arena.name = "Arena"
	arena.set_script(load("res://scripts/arena_movimiento.gd"))
	# Igual que en el caso de las princesas: construir dentro del arbol para que
	# set_owner() y make_current() no se rechacen.
	root.add_child(arena)

	# --- Suelo: la fisica del graybox de OUFW-6, en miniatura. ---
	var suelo := StaticBody2D.new()
	suelo.name = "Suelo"
	var col_suelo := CollisionShape2D.new()
	col_suelo.name = "Colision"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2400.0, 200.0)
	col_suelo.shape = rect
	col_suelo.position = Vector2(0.0, 100.0)
	suelo.add_child(col_suelo)
	arena.add_child(suelo)
	# Ojo al orden: primero se monta el arbol, despues se asigna el owner. Al
	# reves, Godot rechaza el owner porque el nodo todavia no es descendiente.
	col_suelo.owner = arena
	suelo.owner = arena

	# --- Jugadora ---
	var jugadora: Personaje = load("%s/princesa_dulcecito.tscn" % DIR_ESCENAS).instantiate()
	jugadora.name = "Jugadora"
	jugadora.position = Vector2(-160.0, -32.0)
	arena.add_child(jugadora)
	jugadora.owner = arena

	# --- Rival ---
	var rival: Personaje = load("%s/princesa_chocolatito.tscn" % DIR_ESCENAS).instantiate()
	rival.name = "Rival"
	rival.position = Vector2(160.0, -32.0)
	arena.add_child(rival)
	rival.owner = arena

	# --- Control de la jugadora: aqui se cablea `rival`, que es lo que hace
	# que el Sprite Flipper mire al rival y no al ultimo input (criterio 3). ---
	var ctrl := ControladorJugador.new()
	ctrl.name = "Controlador"
	ctrl.personaje = jugadora
	ctrl.rival = rival
	jugadora.add_child(ctrl)
	ctrl.owner = arena

	# --- Camara y HUD ---
	var camara := Camera2D.new()
	camara.name = "Camara"
	camara.position = Vector2(0.0, -60.0)
	arena.add_child(camara)
	camara.make_current()
	camara.owner = arena

	var capa := CanvasLayer.new()
	capa.name = "HUD"
	var etiqueta := Label.new()
	etiqueta.name = "Estado"
	etiqueta.position = Vector2(12.0, 8.0)
	etiqueta.add_theme_font_size_override("font_size", 14)
	capa.add_child(etiqueta)
	arena.add_child(capa)
	etiqueta.owner = arena
	capa.owner = arena

	root.remove_child(arena)
	_guardar(arena, "%s/arena_movimiento.tscn" % DIR_ESCENAS)
	arena.free()


func _fijar_escena_principal() -> void:
	ProjectSettings.set_setting("application/run/main_scene",
		"%s/arena_movimiento.tscn" % DIR_ESCENAS)
	ProjectSettings.set_setting("display/window/size/viewport_width", 960)
	ProjectSettings.set_setting("display/window/size/viewport_height", 540)
	ProjectSettings.set_setting("display/window/size/window_width_override", 960)
	ProjectSettings.set_setting("display/window/size/window_height_override", 540)
	var err := ProjectSettings.save()
	print("  escena principal fijada -> %s" % error_string(err))


func _guardar(raiz: Node, ruta: String) -> void:
	var escena := PackedScene.new()
	var err := escena.pack(raiz)
	if err != OK:
		printerr("  pack(%s) -> %s" % [ruta, error_string(err)])
		quit(1)
		return
	err = ResourceSaver.save(escena, ruta)
	print("  escena %s -> %s" % [ruta, error_string(err)])
	if err != OK:
		quit(1)
		return
	_quitar_unique_ids(ruta)


## Godot escribe un `unique_id` aleatorio por nodo en cada `pack()`. Con eso, cada
## regeneracion reescribia los tres .tscn completos y parecia que hubiera cambios
## reales en git (y provocaria conflictos entre compas). Se eliminan para que la
## generacion sea determinista: byte a byte identica si nadie toca los nodos.
## Godot los reasigna solo si alguien abre y guarda la escena en el editor.
func _quitar_unique_ids(ruta: String) -> void:
	var regex := RegEx.new()
	regex.compile(" unique_id=\\d+")
	var original := FileAccess.get_file_as_string(ruta)
	var limpio := regex.sub(original, "", true)
	if limpio == original:
		return
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		printerr("  no se pudo limpiar %s (%s)" % [ruta, error_string(FileAccess.get_open_error())])
		return
	archivo.store_string(limpio)
	archivo.close()
