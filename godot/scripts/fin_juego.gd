extends Control
## Pantalla de fin de juego (OUFW-18): se muestra al completar el Capitulo 3.
##
## Conserva la seleccion de princesa de [SeleccionPartida] para que el resumen
## tenga sentido tras tres combates y ofrece volver al menu o cerrar el juego.

const ESCENA_MENU := "res://escenas/menu_principal.tscn"

@onready var _titulo: Label = get_node_or_null("Panel/Titulo")
@onready var _resumen: Label = get_node_or_null("Panel/Resumen")
@onready var _boton_menu: Button = get_node_or_null("Panel/BotonMenu")
@onready var _boton_salir: Button = get_node_or_null("Panel/BotonSalir")


func _ready() -> void:
	if _titulo != null:
		_titulo.text = "FIN DEL JUEGO"
	if _resumen != null:
		_resumen.text = "Has completado los tres capitulos con %s.\nEl reino de Candy vuelve a respirar... por ahora." % \
			SeleccionPartida.princesa_jugable.capitalize()
	if _boton_menu != null:
		_boton_menu.pressed.connect(_on_menu_pressed)
		_boton_menu.grab_focus()
	if _boton_salir != null:
		_boton_salir.pressed.connect(_on_salir_pressed)


func _on_menu_pressed() -> void:
	SeleccionPartida.partida_iniciada = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _on_salir_pressed() -> void:
	get_tree().quit()


func texto_resumen() -> String:
	return "" if _resumen == null else _resumen.text
