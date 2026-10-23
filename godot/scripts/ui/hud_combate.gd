class_name HudCombate
extends Control
## HUD visual de combate (OUFW-5): vida con corazones y pociones con su sprite.
##
## El panel de la jugadora vive arriba a la izquierda; el de la rival, arriba a la
## derecha. Cada corazon vale 10 HP y usa [TextureProgressBar] para que la ultima
## unidad pueda quedar parcialmente llena (p. ej. 125/125 = 12 corazones y medio).

const TEX_CORAZON_LLENO := preload("res://recursos/Corazon_lleno-removebg-preview.png")
const TEX_CORAZON_VACIO := preload("res://recursos/Corazon vacio(1).png")
const TEX_POCION := preload("res://recursos/pocion.svg")

const HP_POR_CORAZON := 25
const ANCHO_PANEL := 350.0
const ALTO_PANEL := 96.0
const MARGEN := 12.0
const ESCALA_CORAZON := 0.44
const ESCALA_POCION := 0.35
const MAX_ICONOS_POCION := 5

var _jugadora: Personaje
var _rival: Personaje
var _numero_nivel: int = 1

var _panel_jugadora: Panel
var _panel_rival: Panel
var _nombre_jugadora: Label
var _nombre_rival: Label
var _hp_jugadora: Label
var _hp_rival: Label
var _estado_jugadora: Label
var _estado_rival: Label
var _corazones_jugadora: HBoxContainer
var _corazones_rival: HBoxContainer
var _pociones_jugadora: HBoxContainer
var _pociones_rival: HBoxContainer
var _iconos_pocion_jugadora: Array[TextureRect] = []
var _iconos_pocion_rival: Array[TextureRect] = []
var _conteo_pocion_jugadora: Label
var _conteo_pocion_rival: Label

var _max_corazones_jugadora: int = -1
var _max_corazones_rival: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_construir()
	resized.connect(_reposicionar)
	_reposicionar()


## Enlaza el HUD con los combatientes del nivel. Se puede llamar de nuevo cuando
## la seleccion de princesas cambia en tiempo de ejecucion.
func configurar(jugadora: Personaje, rival: Personaje, numero_nivel: int = 1) -> void:
	_jugadora = jugadora
	_rival = rival
	_numero_nivel = numero_nivel
	_refrescar_todo()


## Rectangulo del panel enemigo, para QA y para comprobar que no tapa el timer.
func rect_panel_rival() -> Rect2:
	return Rect2(_panel_rival.position, _panel_rival.size)


## Rectangulo del panel de la jugadora.
func rect_panel_jugadora() -> Rect2:
	return Rect2(_panel_jugadora.position, _panel_jugadora.size)


## Cuantos corazones necesita un HP maximo. Publico para las pruebas.
static func corazones_para(hp_max: int) -> int:
	return maxi(1, ceili(float(hp_max) / float(HP_POR_CORAZON)))


func _process(_delta: float) -> void:
	_refrescar_valores()


func _construir() -> void:
	_panel_jugadora = _crear_panel("Jugador")
	_panel_rival = _crear_panel("Rival")

	_nombre_jugadora = _etiqueta(_panel_jugadora, "Nombre", 10.0, 4.0,
		Vector2(220.0, 20.0), HORIZONTAL_ALIGNMENT_LEFT, 15)
	_nombre_rival = _etiqueta(_panel_rival, "Nombre", 120.0, 4.0,
		Vector2(220.0, 20.0), HORIZONTAL_ALIGNMENT_RIGHT, 15)

	_hp_jugadora = _etiqueta(_panel_jugadora, "HPTexto", 240.0, 4.0,
		Vector2(100.0, 20.0), HORIZONTAL_ALIGNMENT_RIGHT, 14)
	_hp_rival = _etiqueta(_panel_rival, "HPTexto", 10.0, 4.0,
		Vector2(100.0, 20.0), HORIZONTAL_ALIGNMENT_LEFT, 14)

	_corazones_jugadora = _fila(_panel_jugadora, "Corazones", 10.0, 27.0,
		BoxContainer.ALIGNMENT_BEGIN)
	_corazones_rival = _fila(_panel_rival, "Corazones", 10.0, 27.0,
		BoxContainer.ALIGNMENT_END)

	# Estado (dificultad/veneno) a la izquierda, pociones a la derecha (opuesto)
	# Bajado a Y=70 para no tapar corazones (que terminan ~Y=47)
	_estado_jugadora = _etiqueta(_panel_jugadora, "EstadoAlterado", 10.0, 70.0,
		Vector2(160.0, 18.0), HORIZONTAL_ALIGNMENT_LEFT, 13)
	_estado_rival = _etiqueta(_panel_rival, "EstadoAlterado", 180.0, 70.0,
		Vector2(160.0, 18.0), HORIZONTAL_ALIGNMENT_RIGHT, 13)

	# Pociones: contenedor más estrecho (120px) para que quepa en el panel
	# Jugadora: alineado a la derecha, empieza en x=230 (panel 350 - 120)
	# Rival: alineado a la izquierda, empieza en x=10
	_pociones_jugadora = _fila(_panel_jugadora, "Pociones", 220.0, 70.0,
		BoxContainer.ALIGNMENT_END, 120.0)
	_pociones_rival = _fila(_panel_rival, "Pociones", 10.0, 70.0,
		BoxContainer.ALIGNMENT_BEGIN, 120.0)
	_conteo_pocion_jugadora = _crear_iconos_pocion(_pociones_jugadora,
		_iconos_pocion_jugadora)
	_conteo_pocion_rival = _crear_iconos_pocion(_pociones_rival,
		_iconos_pocion_rival)


func _crear_panel(nombre: String) -> Panel:
	var panel := Panel.new()
	panel.name = "Panel" + nombre
	panel.size = Vector2(ANCHO_PANEL, ALTO_PANEL)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.03, 0.08, 0.72)
	estilo.border_color = Color(1.0, 0.72, 0.82, 0.45)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 8.0
	estilo.content_margin_right = 8.0
	panel.add_theme_stylebox_override("panel", estilo)
	add_child(panel)
	return panel


func _etiqueta(padre: Control, nombre: String, x: float, y: float,
		tamano: Vector2, alineacion: HorizontalAlignment,
		tamano_fuente: int) -> Label:
	var etiqueta := Label.new()
	etiqueta.name = nombre
	etiqueta.position = Vector2(x, y)
	etiqueta.size = tamano
	etiqueta.custom_minimum_size = tamano
	etiqueta.horizontal_alignment = alineacion
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano_fuente)
	etiqueta.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))
	etiqueta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	etiqueta.add_theme_constant_override("shadow_offset_x", 1)
	etiqueta.add_theme_constant_override("shadow_offset_y", 1)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(etiqueta)
	return etiqueta


func _fila(padre: Control, nombre: String, x: float, y: float,
		alineacion: BoxContainer.AlignmentMode, ancho: float = -1.0) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = nombre
	fila.position = Vector2(x, y)
	var w := ANCHO_PANEL - 20.0 if ancho < 0 else ancho
	fila.size = Vector2(w, 22.0)
	fila.custom_minimum_size = Vector2(w, 22.0)
	fila.alignment = alineacion
	fila.add_theme_constant_override("separation", 1)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(fila)
	return fila


func _crear_iconos_pocion(fila: HBoxContainer, iconos: Array[TextureRect]) -> Label:
	for i in MAX_ICONOS_POCION:
		var icono := TextureRect.new()
		icono.name = "Pocion%d" % i
		icono.texture = TEX_POCION
		var tamano := Vector2(TEX_POCION.get_width(), TEX_POCION.get_height()) * ESCALA_POCION
		icono.custom_minimum_size = tamano
		icono.size = tamano
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(icono)
		iconos.append(icono)
	var conteo := Label.new()
	conteo.name = "Cantidad"
	conteo.add_theme_font_size_override("font_size", 14)
	conteo.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))
	conteo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	conteo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(conteo)
	return conteo


func _reposicionar() -> void:
	if _panel_jugadora == null or _panel_rival == null:
		return
	var ancho := NivelArena.ANCHO_PANTALLA
	_panel_jugadora.position = Vector2(MARGEN, 8.0)
	_panel_rival.position = Vector2(ancho - MARGEN - ANCHO_PANEL, 8.0)


func _refrescar_todo() -> void:
	_refrescar_personaje(_jugadora, _panel_jugadora, _nombre_jugadora, _hp_jugadora,
		_estado_jugadora, _corazones_jugadora, _pociones_jugadora,
		_iconos_pocion_jugadora, _conteo_pocion_jugadora, true)
	_refrescar_personaje(_rival, _panel_rival, _nombre_rival, _hp_rival,
		_estado_rival, _corazones_rival, _pociones_rival,
		_iconos_pocion_rival, _conteo_pocion_rival, false)


func _refrescar_valores() -> void:
	_refrescar_personaje(_jugadora, _panel_jugadora, _nombre_jugadora, _hp_jugadora,
		_estado_jugadora, _corazones_jugadora, _pociones_jugadora,
		_iconos_pocion_jugadora, _conteo_pocion_jugadora, false)
	_refrescar_personaje(_rival, _panel_rival, _nombre_rival, _hp_rival,
		_estado_rival, _corazones_rival, _pociones_rival,
		_iconos_pocion_rival, _conteo_pocion_rival, false)


func _refrescar_personaje(p: Personaje, panel: Panel, nombre: Label, hp_texto: Label,
		estado: Label, corazones: HBoxContainer, pociones: HBoxContainer,
		iconos: Array[TextureRect], conteo: Label, es_jugadora: bool) -> void:
	if p == null:
		return
	panel.visible = true
	nombre.text = p.nombre if not p.nombre.is_empty() else (
		"Jugadora" if es_jugadora else "Rival")
	hp_texto.text = "%d/%d" % [p.current_hp, p.hp_max]

	var max_corazones := corazones_para(p.hp_max)
	if es_jugadora and max_corazones != _max_corazones_jugadora:
		_max_corazones_jugadora = max_corazones
		_montar_corazones(corazones, max_corazones)
	elif not es_jugadora and max_corazones != _max_corazones_rival:
		_max_corazones_rival = max_corazones
		_montar_corazones(corazones, max_corazones)

	for i in corazones.get_child_count():
		var corazon := corazones.get_child(i) as TextureProgressBar
		if corazon != null:
			corazon.value = clampi(p.current_hp - i * HP_POR_CORAZON, 0, HP_POR_CORAZON)

	var visibles := mini(p.cantidad_pociones, MAX_ICONOS_POCION)
	for i in iconos.size():
		iconos[i].visible = i < visibles
	conteo.text = "x%d" % p.cantidad_pociones
	estado.text = _texto_estado(p)
	if p.esta_muerto:
		nombre.add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
		hp_texto.add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
	else:
		nombre.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))
		hp_texto.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))


func _montar_corazones(fila: HBoxContainer, cantidad: int) -> void:
	for hijo in fila.get_children():
		fila.remove_child(hijo)
		hijo.queue_free()
	for i in cantidad:
		var corazon := TextureProgressBar.new()
		corazon.name = "Corazon%d" % i
		corazon.texture_under = TEX_CORAZON_VACIO
		corazon.texture_progress = TEX_CORAZON_LLENO
		corazon.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
		corazon.min_value = 0.0
		corazon.max_value = float(HP_POR_CORAZON)
		corazon.custom_minimum_size = Vector2(
			TEX_CORAZON_LLENO.get_width(), TEX_CORAZON_LLENO.get_height()) * ESCALA_CORAZON
		corazon.size = corazon.custom_minimum_size
		corazon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(corazon)


func _texto_estado(p: Personaje) -> String:
	return p.texto_estado()
