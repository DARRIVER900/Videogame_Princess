extends Control

@onready var boton_dulcecito: Button = $BotonDulcecito
@onready var boton_chocolatito: Button = $BotonChocolatito
@onready var boton_salir: Button = $BotonSalir

func _ready() -> void:
	boton_dulcecito.pressed.connect(_on_dulcecito_pressed)
	boton_chocolatito.pressed.connect(_on_chocolatito_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)

func _on_dulcecito_pressed() -> void:
	# Guarda la selección de personaje o carga directamente la arena
	get_tree().change_scene_to_file("res://escenas/arena_movimiento.tscn")

func _on_chocolatito_pressed() -> void:
	get_tree().change_scene_to_file("res://escenas/arena_movimiento.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
