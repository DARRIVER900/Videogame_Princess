class_name NivelJugable
extends NivelArena
## Base de los niveles jugables de produccion (OUFW-6/14/18).
##
## Anade a [NivelArena] todo lo que comparten los tres capitulos: instala la
## seleccion de princesas hecha en el menu (OUFW-17), activa la FSM del rival
## (OUFW-11), mantiene el HUD (OUFW-5), el temporizador (OUFW-12), el fin de
## combate (OUFW-16) y la intro de novela visual (OUFW-13).
##
## Las subclases solo declaran su numero de nivel, la escena siguiente y, si
## procede, su guion de intro. Asi la progresion del core loop (OUFW-18) vive en
## un unico sitio y no se duplica nivel a nivel.

const _NOMBRES_LOCOMOCION := {
	Personaje.Locomocion.DE_PIE: "DE PIE",
	Personaje.Locomocion.AGACHADO: "AGACHADO",
	Personaje.Locomocion.DERRAPE: "DERRAPE",
}

## Numero de capitulo/nivel (1 a 3). Se persiste en [SeleccionPartida].
@export var numero_nivel: int = 1
## Escena que carga "Siguiente Nivel" al ganar. Vacia = reintentar el nivel actual.
@export var siguiente_escena: String = ""
## Guion de intro que se muestra antes de combatir. Vacio = sin intro.
@export var intro: String = ""

var _jugadora: Personaje
var _rival: Personaje
var _controlador: ControladorJugador
var _bot: ControladorBot
var _dialogo: DialogoUI
var _temporizador: TemporizadorCombate
var _hud: HudCombate
var _gestor
var _panel_controles


func _ready() -> void:
	SeleccionPartida.nivel_actual = numero_nivel
	_instalar_seleccion()
	super._ready()
	_resolver_nodos()
	_configurar_gestor()
	_configurar_temporizador()
	_arrancar_intro()


func _resolver_nodos() -> void:
	_jugadora = get_node_or_null("Jugadora") as Personaje
	_rival = get_node_or_null("Rival") as Personaje
	_controlador = get_node_or_null("Jugadora/Controlador") as ControladorJugador
	_bot = get_node_or_null("Rival/Bot") as ControladorBot
	_dialogo = get_node_or_null("Dialogo") as DialogoUI
	_temporizador = get_node_or_null("HUD/Temporizador") as TemporizadorCombate
	_hud = get_node_or_null("HUD/Combate") as HudCombate
	if _hud == null:
		var capa := get_node_or_null("HUD")
		if capa != null:
			_hud = HudCombate.new()
			_hud.name = "Combate"
			capa.add_child(_hud)
	if _hud != null:
		_hud.configurar(_jugadora, _rival, numero_nivel)
	_crear_panel_controles()


## El gestor de fin de combate (OUFW-16) conoce la escena siguiente para que
## "Siguiente Nivel" avance el core loop en vez de recargar el mismo capitulo.
func _configurar_gestor() -> void:
	_gestor = get_node_or_null("GestorCombate")
	if _gestor == null:
		return
	_gestor.set("siguiente_escena", siguiente_escena)
	if _gestor.has_method("reiniciar_escucha"):
		_gestor.reiniciar_escucha()


func _configurar_temporizador() -> void:
	if _temporizador == null:
		return
	if not _temporizador.tiempo_agotado.is_connected(_on_tiempo_agotado):
		_temporizador.tiempo_agotado.connect(_on_tiempo_agotado)
	if _jugadora != null and not _jugadora.died.is_connected(_detener_temporizador):
		_jugadora.died.connect(_detener_temporizador)
	if _rival != null and not _rival.died.is_connected(_detener_temporizador):
		_rival.died.connect(_detener_temporizador)


## Solo al entrar desde el menu. Abrir la escena directamente deja el nivel en su
## estado de prueba (princesas fijas y bot inactivo).
func _instalar_seleccion() -> void:
	if not SeleccionPartida.partida_iniciada:
		return
	if not get_node_or_null("Jugadora") or not get_node_or_null("Rival"):
		return

	var ctrl := _reemplazar_personaje("Jugadora", SeleccionPartida.princesa_jugable,
		Vector2(-X_APARICION, Y_APARICION))
	var bot := _reemplazar_personaje("Rival", SeleccionPartida.clave_rival(),
		Vector2(X_APARICION, Y_APARICION))

	_montar_controlador(ctrl, "Jugadora", "Controlador", "Rival")
	_montar_controlador(bot, "Rival", "Bot", "Jugadora")


func _reemplazar_personaje(nombre: String, clave: String, posicion: Vector2) -> Node:
	var actual := get_node_or_null(nombre) as Personaje
	if actual == null:
		return null

	if _clave_de(actual) == clave:
		actual.position = posicion
		if actual.get_node_or_null("Controlador") != null:
			return actual.get_node_or_null("Controlador")
		return actual.get_node_or_null("Bot")

	var indice := actual.get_index()
	var ctrl := actual.get_node_or_null("Controlador")
	if ctrl == null:
		ctrl = actual.get_node_or_null("Bot")
	if ctrl != null:
		actual.remove_child(ctrl)

	# Guardar nodo_sprite del personaje actual para pasarlo al nuevo
	var nodo_sprite_path := actual.nodo_sprite

	var nueva := load(SeleccionPartida.ruta_de(clave)).instantiate() as Personaje
	nueva.name = nombre
	nueva.position = posicion
	# Copiar nodo_sprite al nuevo personaje (el PackedScene no lo trae)
	nueva.nodo_sprite = nodo_sprite_path
	actual.name = nombre + "_anterior"
	remove_child(actual)
	add_child(nueva)
	move_child(nueva, indice)
	actual.queue_free()
	return ctrl


func _montar_controlador(ctrl: Node, nombre: String, nombre_nodo: String, objetivo: String) -> void:
	var p := get_node_or_null(nombre) as Personaje
	if p == null:
		return
	if ctrl == null:
		ctrl = ControladorJugador.new() if nombre_nodo == "Controlador" else ControladorBot.new()
		ctrl.name = nombre_nodo
		p.add_child(ctrl)
	elif ctrl.get_parent() != p:
		p.add_child(ctrl)
	ctrl.personaje = p
	ctrl.rival = get_node_or_null(objetivo)
	if ctrl is ControladorBot:
		(ctrl as ControladorBot).activo = SeleccionPartida.partida_iniciada


func _clave_de(p: Personaje) -> String:
	if p is PrincesaDulcecito:
		return SeleccionPartida.DULCECITO
	if p is PrincesaChocolatito:
		return SeleccionPartida.CHOCOLATITO
	return ""


## Muestra la intro de novela visual (OUFW-13) solo al entrar desde el menu y una
## sola vez por partida: el combate y el temporizador quedan congelados hasta que
## el jugador avanza todas las lineas con Espacio o clic.
func _arrancar_intro() -> void:
	if _dialogo == null or intro == "" or not SeleccionPartida.partida_iniciada:
		return
	if SeleccionPartida.intro_vista:
		return
	if not _dialogo.iniciar(intro):
		return
	SeleccionPartida.intro_vista = true
	_dialogo.terminado.connect(_on_intro_terminada)
	_congelar_para_intro(true)


func _on_intro_terminada() -> void:
	_congelar_para_intro(false)
	if _temporizador != null:
		_temporizador.iniciar()


func _congelar_para_intro(congelar: bool) -> void:
	if _controlador != null:
		_controlador.activo = not congelar
		if congelar:
			_controlador.soltar_controles()
	if _bot != null:
		_bot.activo = not congelar
	if _jugadora != null:
		_jugadora.velocity.x = 0.0
	if congelar and _temporizador != null:
		_temporizador.detener()


func _on_tiempo_agotado() -> void:
	if _gestor != null and _gestor.has_method("forzar_derrota"):
		_gestor.forzar_derrota()


func _detener_temporizador() -> void:
	if _temporizador != null:
		_temporizador.detener()


func _process(_delta: float) -> void:
	# Solo mantener la caja de controles visible (sin debug info)
	# La caja se crea en _ready y solo se actualiza si es necesario
	pass


func _crear_panel_controles() -> void:
	var ancho := NivelArena.ANCHO_PANTALLA
	var alto := NivelArena.ALTO_PANTALLA
	var margen := 12.0
	var ancho_panel := 350.0
	var alto_panel := 200.0

	_panel_controles = Panel.new()
	_panel_controles.name = "PanelControles"
	_panel_controles.size = Vector2(ancho_panel, alto_panel)
	_panel_controles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.03, 0.08, 0.85)
	estilo.border_color = Color(1.0, 0.72, 0.82, 0.6)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 12.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_top = 8.0
	estilo.content_margin_bottom = 8.0
	_panel_controles.add_theme_stylebox_override("panel", estilo)

	# Agregar al HUD CanvasLayer para que este en coordenadas de pantalla
	var hud_capa := get_node_or_null("HUD")
	if hud_capa != null:
		hud_capa.add_child(_panel_controles)
	else:
		add_child(_panel_controles)

	# Posicionar en esquina inferior izquierda (coordenadas de pantalla)
	_panel_controles.position = Vector2(margen, alto - margen - alto_panel)

	# Titulo
	var titulo := Label.new()
	titulo.name = "Titulo"
	titulo.position = Vector2(8.0, 4.0)
	titulo.size = Vector2(ancho_panel - 20.0, 24.0)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 16)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))
	titulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	titulo.add_theme_constant_override("shadow_offset_x", 1)
	titulo.add_theme_constant_override("shadow_offset_y", 1)
	titulo.text = "CONTROLES"
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_controles.add_child(titulo)

	# Lista de controles
	var controles := [
		"A / D       Moverse",
		"W + A / D   Salto diagonal",
		"S           Agachar",
		"S + A / D   Derrape",
		"K           Golpe normal",
		"L           Golpe fuerte",
		"J           Carga (mantener y soltar)",
		"E           Pocion",
		"U           Veneno",
	]

	var y_pos := 32.0
	for texto in controles:
		var etiqueta := Label.new()
		etiqueta.position = Vector2(8.0, y_pos)
		etiqueta.size = Vector2(ancho_panel - 20.0, 20.0)
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", 13)
		etiqueta.add_theme_color_override("font_color", Color(1.0, 0.94, 0.97))
		etiqueta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		etiqueta.add_theme_constant_override("shadow_offset_x", 1)
		etiqueta.add_theme_constant_override("shadow_offset_y", 1)
		etiqueta.text = texto
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel_controles.add_child(etiqueta)
		y_pos += 18.0


func _texto_carga() -> String:
	if _jugadora != null and _jugadora.esta_cargando():
		return "acumulando %d%%" % roundi(_jugadora.carga_nivel() * 100.0)
	return "lista"