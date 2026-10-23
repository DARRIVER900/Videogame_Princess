extends CanvasLayer
## Gestor de fin de combate (OUFW-16): escucha la muerte de cualquiera de los dos
## combatientes, congela la partida y despliega la pantalla de Victoria o de Game
## Over con los botones "Reintentar" y "Menu Principal".
##
## Criterio de aceptacion de OUFW-16: "se despliega automaticamente al morir el
## jugador o la IA". Por eso NO espera a que nadie lo llame: se conecta a la senal
## [signal Personaje.died] de ambos personajes en [_ready] y se dispara solo.
##
## Vive como un [CanvasLayer] (HUD) porque debe dibujar sobre el mundo sin seguir a
## la camara ni recibir la fisica del combate.

## Escena del menu principal a la que lleva "Menu Principal".
const ESCENA_MENU := "res://escenas/menu_principal.tscn"

## Escena de combate recargada por "Reintentar" si el arbol no expone la escena
## actual (por ejemplo en las suites headless). Reintentar reejecuta exactamente
## esa partida, sea la arena de pruebas o el nivel de produccion (OUFW-6).
const ESCENA_COMBATE := "res://escenas/nivel_1_frontera.tscn"

## Personaje del jugador. Si se deja vacio se busca "Jugadora" en la arena.
@export var jugadora: Personaje
## Personaje de la IA rival. Si se deja vacio se busca "Rival" en la arena.
@export var rival: Personaje

## Controlador del jugador, para congelarlo al terminar el combate. Si se deja
## vacio se busca "Jugadora/Controlador".
@export var controlador: ControladorJugador

## Escena que carga "Siguiente Nivel" al ganar (OUFW-18). Vacia = reintentar el
## nivel actual. El nivel jugable la asigna al arrancar.
@export var siguiente_escena: String = ""

@onready var _panel: Control = get_node_or_null("Panel")
@onready var _titulo: Label = get_node_or_null("Panel/Titulo")
@onready var _boton_reintentar: Button = get_node_or_null("Panel/BotonReintentar")
@onready var _boton_menu: Button = get_node_or_null("Panel/BotonMenu")

## Se enciende al terminar el combate. Evita que un segundo `died` (empate, doble
## golpe letal en el mismo frame) reprograme el fin o vuelva a mostrar el panel.
var _terminado: bool = false
## Resultado del combate, para saber si "Reintentar" avanza o recarga.
var _victoria: bool = false


func _ready() -> void:
	_resolver_referencias()
	_conectar_botones()

	if _panel != null:
		_panel.visible = false

	_escuchar_combatientes()


## (Re)cablea las senales [signal Personaje.died] de los dos combatientes.
##
## Es publico porque la arena reemplaza a las princesas al instalar la seleccion
## (OUFW-17) DESPUES de que este gestor ya se inicializo: sin volver a escuchar, el
## gestor quedaria conectado a los nodos recien liberados y no habria fin de combate.
func _escuchar_combatientes() -> void:
	if jugadora != null and not jugadora.died.is_connected(_on_personaje_muerto):
		jugadora.died.connect(_on_personaje_muerto.bind(jugadora))
	if rival != null and not rival.died.is_connected(_on_personaje_muerto):
		rival.died.connect(_on_personaje_muerto.bind(rival))


## Vuelve a resolver los combatientes desde la escena y a escucharlos. La llama la
## arena tras cambiar de princesa.
func reiniciar_escucha() -> void:
	_resolver_referencias(true)
	_escuchar_combatientes()


## Resuelve las referencias de los combatientes desde la escena si no se cablearon
## a mano, para que el gestor funcione en la arena sin configuracion extra.
## [param forzar] refresca tambien las referencias ya asignadas, necesario tras el
## cambio de princesa de la seleccion (el nodo viejo ya no es el que combate).
func _resolver_referencias(forzar: bool = false) -> void:
	var arena := get_parent()
	if arena == null:
		return
	if forzar or jugadora == null:
		var ref := arena.get_node_or_null("Jugadora") as Personaje
		if ref != null:
			jugadora = ref
	if forzar or rival == null:
		var ref_r := arena.get_node_or_null("Rival") as Personaje
		if ref_r != null:
			rival = ref_r
	if forzar or controlador == null:
		var ref_c := arena.get_node_or_null("Jugadora/Controlador") as ControladorJugador
		if ref_c != null:
			controlador = ref_c


func _conectar_botones() -> void:
	if _boton_reintentar != null:
		_boton_reintentar.pressed.connect(_on_reintentar_pressed)
	if _boton_menu != null:
		_boton_menu.pressed.connect(_on_menu_pressed)


## Punto unico de entrada del fin de combate. Decide si es victoria o derrota segun
## quien murio: si cae la jugadora, Game Over; si cae la IA, Victoria.
func _on_personaje_muerto(muerto: Personaje) -> void:
	if _terminado:
		return
	_terminado = true

	_congelar_combate()
	_mostrar_panel(muerto != jugadora)


## Congela el combate sin pausar el arbol de forma global ([code]get_tree().paused[/code]):
## la pantalla de fin debe seguir respondiendo, y para eso basta con desactivar el
## controlador del jugador (el rival sin FSM ya deja de atacar al morir).
func _congelar_combate() -> void:
	if controlador != null:
		controlador.activo = false
		controlador.soltar_controles()


## Despliega el panel de fin con el texto y el foco correctos.
func _mostrar_panel(victoria: bool) -> void:
	_victoria = victoria
	if _titulo != null:
		_titulo.text = "VICTORIA" if victoria else "GAME OVER"
	if _boton_reintentar != null:
		_boton_reintentar.text = "Siguiente Nivel" \
			if victoria and siguiente_escena != "" else "Reintentar"
	if _panel != null:
		_panel.visible = true
	# El foco va a "Reintentar", la accion mas probable tras perder o ganar.
	if _boton_reintentar != null:
		_boton_reintentar.grab_focus()


## "Reintentar": recarga el combate desde cero. La seleccion de personaje del
## jugador persiste en [SeleccionPartida], asi que se vuelve a jugar con la misma
## princesa.
func _on_reintentar_pressed() -> void:
	if _victoria and siguiente_escena != "":
		SeleccionPartida.nivel_actual = mini(SeleccionPartida.nivel_actual + 1, 3)
		get_tree().change_scene_to_file(siguiente_escena)
		return
	var actual := get_tree().current_scene
	var ruta := actual.scene_file_path if actual != null else ""
	get_tree().change_scene_to_file(ruta if ruta != "" else ESCENA_COMBATE)


## Fuerza una derrota sin combatiente muerto (tiempo agotado, OUFW-12).
func forzar_derrota() -> void:
	if _terminado:
		return
	_terminado = true
	_congelar_combate()
	_mostrar_panel(false)


## "Menu Principal": vuelve al menu de seleccion (OUFW-17).
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_MENU)


## [return] Si el combate ya termino. Lectura publica para pruebas.
func combate_terminado() -> bool:
	return _terminado


## [return] Si el panel de fin esta visible.
func panel_visible() -> bool:
	return _panel != null and _panel.visible
