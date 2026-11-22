extends SceneTree
## Genera las pantallas PROVISIONALES del flujo (OUFW-18):
##
##   godot --headless --script res://tools/crear_pantallas.gd
##
## Cada escena es un nodo [Control] con su script, que construye la interfaz en codigo (ver
## scripts/flujo/pantalla_*.gd). Cuando un companero entregue la pantalla definitiva, basta
## cambiar su ruta en scripts/flujo/flujo_juego.gd; esto y los scripts se pueden borrar.

const Util := preload("res://tools/utilidades_nivel.gd")

const PANTALLAS := [
	{"nombre": "MenuPrincipal", "script": "res://scripts/flujo/pantalla_menu.gd",
		"ruta": "res://escenas/menu_principal.tscn"},
	{"nombre": "NovelaVisual", "script": "res://scripts/flujo/pantalla_novela.gd",
		"ruta": "res://escenas/novela_visual.tscn"},
	{"nombre": "PantallaDerrota", "script": "res://scripts/flujo/pantalla_derrota.gd",
		"ruta": "res://escenas/pantalla_derrota.tscn"},
	{"nombre": "FinDeJuego", "script": "res://scripts/flujo/pantalla_fin.gd",
		"ruta": "res://escenas/fin_de_juego.tscn"},
]


func _init() -> void:
	var ok := true
	for datos: Dictionary in PANTALLAS:
		var pantalla := Control.new()
		pantalla.name = datos["nombre"]
		pantalla.set_script(load(datos["script"]))
		ok = Util.guardar(pantalla, datos["ruta"]) and ok
		pantalla.free()

	print("Pantallas generadas correctamente." if ok else "Hubo errores al generar pantallas.")
	quit(0 if ok else 1)