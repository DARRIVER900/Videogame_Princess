class_name DialogoUI
extends CanvasLayer
## Cuadro de dialogo de novela visual (OUFW-13).
##
## Carga una lista de lineas desde un JSON ([code]datos/dialogos/*.json[/code]) y la
## muestra sobre la escena actual: retrato de la princesa, nombre del hablante y
## texto con efecto de maquina de escribir. Avanza con [code]Espacio[/code],
## [code]Enter[/code] o clic; al terminar emite [signal terminado].
##
## La escena se genera con tools/crear_escenas.gd. El nodo nace oculto y no bloquea
## nada hasta que alguien llama a [method iniciar].

## Se emitio al mostrar la ultima linea y avanzar de nuevo.
signal terminado
## Se emitio cada vez que cambia la linea visible.
signal linea_cambiada(indice: int, linea: Dictionary)

const RUTA_INTRO := "res://datos/dialogos/cap1_intro.json"

## Archivos de retrato por princesa. El estado de animo solo cambia el tinte,
## asi que no hace falta un PNG por cada expresion.
const RETRATO_DULCECITO := preload("res://recursos/retrato_dulcecito.png")
const RETRATO_CHOCOLATITO := preload("res://recursos/retrato_chocolatito.png")

const TINTES := {
	"calm": Color(1.0, 1.0, 1.0),
	"angry": Color(1.0, 0.72, 0.72),
	"furious": Color(1.0, 0.55, 0.35),
	"sad": Color(0.72, 0.82, 1.0),
}

## Caracteres por segundo del efecto de maquina de escribir. 0 = texto instantaneo.
const VELOCIDAD_TEXTO := 45.0
const COLOR_DULCECITO := Color("#f2a7d0")
const COLOR_CHOCOLATITO := Color("#d9a066")

@onready var _raiz: Control = get_node_or_null("Raiz")
@onready var _nombre: Label = get_node_or_null("Raiz/Nombre")
@onready var _texto: RichTextLabel = get_node_or_null("Raiz/Texto")
@onready var _retrato: TextureRect = get_node_or_null("Raiz/Retrato")
@onready var _indicador: Label = get_node_or_null("Raiz/Indicador")
@onready var _contador: Label = get_node_or_null("Raiz/Contador")

var _lineas: Array = []
var _indice: int = -1
var _caracteres: float = 0.0
var _activo: bool = false
var _finalizado: bool = false


func _ready() -> void:
	visible = false


func _process(delta: float) -> void:
	if not _activo or _indice < 0 or _indice >= _lineas.size():
		return
	var completo: String = _texto_de(_lineas[_indice])
	if _caracteres < float(completo.length()):
		_caracteres = minf(_caracteres + VELOCIDAD_TEXTO * delta, float(completo.length()))
		_refrescar_texto(completo)
	else:
		_refrescar_texto(completo)
		_mostrar_indicador(true)


func _input(evento: InputEvent) -> void:
	if not _activo:
		return
	var quiere_avanzar := false
	if evento is InputEventKey:
		var tecla := evento as InputEventKey
		# Sin `not echo`: mantener Espacio/Enter pulsado no debe saltarse el guion.
		if tecla.pressed and not tecla.echo:
			quiere_avanzar = evento.is_action_pressed("ui_accept") or tecla.keycode == KEY_SPACE
	elif evento is InputEventMouseButton:
		var clic := evento as InputEventMouseButton
		quiere_avanzar = clic.pressed and clic.button_index == MOUSE_BUTTON_LEFT
	if not quiere_avanzar:
		return
	get_viewport().set_input_as_handled()
	avanzar_linea()


## Carga y arranca un guion. Devuelve false si el archivo o sus lineas no son
## validos: en ese caso la UI permanece oculta y no bloquea el combate.
func iniciar(ruta: String = RUTA_INTRO) -> bool:
	var nuevas := _cargar(ruta)
	if nuevas.is_empty():
		return false
	_lineas = nuevas
	_indice = -1
	_finalizado = false
	_activo = true
	visible = true
	_mostrar_linea(0)
	return true


## Avanza el texto. Si la maquina de escribir aun esta escribiendo, completa la
## linea; si ya esta completa, pasa a la siguiente o termina el dialogo.
## Devuelve true mientras el dialogo siga activo.
func avanzar_linea() -> bool:
	if not _activo:
		return false
	var completo := _texto_de(_lineas[_indice])
	if _caracteres < float(completo.length()):
		_caracteres = float(completo.length())
		_refrescar_texto(completo)
		_mostrar_indicador(true)
		return true
	if _indice + 1 < _lineas.size():
		_mostrar_linea(_indice + 1)
		return true
	_terminar()
	return false


func _mostrar_linea(indice: int) -> void:
	_indice = indice
	_caracteres = 0.0
	var linea: Dictionary = _lineas[indice]
	var hablante: String = linea.get("speaker", "")
	if _nombre != null:
		_nombre.text = hablante
		_nombre.add_theme_color_override("font_color", _color_de(hablante))
	_aplicar_retrato(str(linea.get("portrait", "")))
	_refrescar_texto("")
	_mostrar_indicador(false)
	if _contador != null:
		_contador.text = "%d / %d" % [indice + 1, _lineas.size()]
	linea_cambiada.emit(indice, linea)


func _refrescar_texto(completo: String) -> void:
	if _texto == null:
		return
	var visibles := int(_caracteres)
	_texto.text = completo.substr(0, visibles)


func _mostrar_indicador(completo: bool) -> void:
	if _indicador == null:
		return
	_indicador.visible = completo
	_indicador.text = "Espacio / clic  >"


func _terminar() -> void:
	_activo = false
	_finalizado = true
	visible = false
	terminado.emit()


func _aplicar_retrato(portrait: String) -> void:
	if _retrato == null:
		return
	var es_dulcecito := portrait.begins_with("dulcecito_")
	_retrato.texture = RETRATO_DULCECITO if es_dulcecito else RETRATO_CHOCOLATITO
	_retrato.modulate = TINTES.get(portrait.get_slice("_", 1), Color.WHITE)


func _color_de(hablante: String) -> Color:
	return COLOR_CHOCOLATITO if hablante.contains("Chocolatito") else COLOR_DULCECITO


func _texto_de(linea: Variant) -> String:
	if linea is Dictionary:
		return str((linea as Dictionary).get("text", ""))
	return ""


## Lee el JSON y descarta lineas incompletas en vez de romper la partida.
func _cargar(ruta: String) -> Array:
	if not FileAccess.file_exists(ruta):
		return []
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(ruta)) != OK:
		return []
	var datos: Variant = json.data
	if not datos is Array:
		return []
	var salida: Array = []
	for linea in datos:
		if not linea is Dictionary:
			continue
		var d: Dictionary = linea
		if str(d.get("speaker", "")).strip_edges() == "":
			continue
		if str(d.get("text", "")).strip_edges() == "":
			continue
		salida.append({
			"speaker": str(d.get("speaker", "")),
			"text": str(d.get("text", "")),
			"portrait": str(d.get("portrait", "")),
		})
	return salida


## --- Lecturas publicas para HUD y pruebas ---

func esta_activo() -> bool:
	return _activo


func esta_finalizado() -> bool:
	return _finalizado


func indice_actual() -> int:
	return _indice


func total_lineas() -> int:
	return _lineas.size()


func linea_actual() -> Dictionary:
	if _indice < 0 or _indice >= _lineas.size():
		return {}
	return _lineas[_indice]


func texto_visible() -> String:
	return "" if _texto == null else _texto.text


func texto_completo() -> bool:
	var linea := linea_actual()
	return not linea.is_empty() and texto_visible().length() >= str(linea.get("text", "")).length()


func nombre_visible() -> String:
	return "" if _nombre == null else _nombre.text


func retrato_actual() -> Texture2D:
	return null if _retrato == null else _retrato.texture
