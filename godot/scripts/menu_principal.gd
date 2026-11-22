extends Control
## Menu principal con seleccion de princesa (OUFW-17).
##
## Pantalla de arranque del juego: el jugador elige entre Dulcecito y Chocolatito
## y pulsa "Jugar". La eleccion se guarda en [SeleccionPartida] (clase estatica) y
## se cambia de escena a la arena, que lee esa eleccion para construir el combate.
##
## Criterio de aceptacion de OUFW-17: "carga limpia de escenas entre menu y
## niveles". Por eso el cambio de escena se hace con [method SceneTree.change_scene_to_file]
## y no instanciando la arena encima: garantiza que el menu y sus nodos se liberen
## antes de montar el combate (nada de dos mundos vivos a la vez).
##
## Referencia: GDD, flujo "Menu -> Seleccion -> Combate -> Fin de combate".

## Escena de combate a la que lleva "Jugar": el graybox jugable del Capitulo 1
## (OUFW-6). La arena de movimiento sigue existiendo como harness de pruebas.
const ESCENA_COMBATE := "res://escenas/nivel_1_frontera.tscn"

## Botones de seleccion, emparejados con su clave en [SeleccionPartida].
const OPCIONES := {
	"BotonDulcecito": SeleccionPartida.DULCECITO,
	"BotonChocolatito": SeleccionPartida.CHOCOLATITO,
}

@onready var _boton_jugar: Button = get_node_or_null("Panel/BotonJugar")
@onready var _etiqueta_seleccion: Label = get_node_or_null("Panel/EtiquetaSeleccion")


func _ready() -> void:
	# Godot enfoca un boton al abrir un menu; aqui lo forzamos al de Jugar para que
	# un mando o el teclado puedan navegar sin tocar el raton.
	if _boton_jugar != null:
		_boton_jugar.grab_focus()
		_boton_jugar.pressed.connect(_on_boton_jugar_pressed)

	for nombre_boton: String in OPCIONES:
		var boton := get_node_or_null("Panel/%s" % nombre_boton) as Button
		if boton == null:
			continue
		boton.pressed.connect(_elegir.bind(OPCIONES[nombre_boton]))

	_actualizar_seleccion()
	_actualizar_etiqueta()


## Guarda la eleccion y refresca los botones para marcar la princesa activa.
func _elegir(clave: String) -> void:
	SeleccionPartida.princesa_jugable = clave
	_actualizar_seleccion()
	_actualizar_etiqueta()


## Resalta con [code]button_pressed[/code] el boton de la princesa elegida. Los
## botones son de tipo toggle para que la seleccion se VEA, no solo se recuerde.
func _actualizar_seleccion() -> void:
	for nombre_boton: String in OPCIONES:
		var boton := get_node_or_null("Panel/%s" % nombre_boton) as Button
		if boton != null:
			boton.button_pressed = OPCIONES[nombre_boton] == SeleccionPartida.princesa_jugable


func _actualizar_etiqueta() -> void:
	if _etiqueta_seleccion == null:
		return
	var rival := SeleccionPartida.clave_rival().capitalize()
	_etiqueta_seleccion.text = "Jugable: %s   -   Rival: %s" % [
		SeleccionPartida.princesa_jugable.capitalize(), rival,
	]


## Arranca la partida: persiste la eleccion (ya esta en la clase estatica) y carga
## el combate. [method SceneTree.change_scene_to_file] libera este menu antes de
## montar la arena: la "carga limpia" que pide el criterio.
func _on_boton_jugar_pressed() -> void:
	if not SeleccionPartida.es_clave_valida(SeleccionPartida.princesa_jugable):
		# Red de seguridad: sin seleccion valida no se arranca una arena rota.
		SeleccionPartida.princesa_jugable = SeleccionPartida.DULCECITO
	SeleccionPartida.partida_iniciada = true
	SeleccionPartida.intro_vista = false
	SeleccionPartida.nivel_actual = 1
	get_tree().change_scene_to_file(ESCENA_COMBATE)
