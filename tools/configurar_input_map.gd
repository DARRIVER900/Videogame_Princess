extends SceneTree
## Genera el InputMap del proyecto en project.godot a partir de una unica fuente
## de verdad. Ejecutar cuando se anada o renombre una accion de movimiento:
##
##   godot --headless --script res://tools/configurar_input_map.gd
##
## Se usan physical_keycode (no keycode) para que WASD funcione igual en
## distribuciones AZERTY/QWERTZ, que es lo que recomienda Godot.

## Acciones de OUFW-2. Los acordes (W+A, W+D, S+A/D) NO se declaran aqui como
## acciones propias: se componen en codigo en Personaje porque dependen de
## combinar el estado de varias teclas a la vez.
const ACCIONES := {
	"mover_izquierda": [KEY_A, KEY_LEFT],
	"mover_derecha": [KEY_D, KEY_RIGHT],
	"salto": [KEY_W, KEY_UP],
	"agachar": [KEY_S, KEY_DOWN],
}


func _init() -> void:
	_podar_acciones_obsoletas()

	for accion: String in ACCIONES:
		var eventos: Array[InputEventKey] = []
		for keycode: int in ACCIONES[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = keycode
			eventos.append(evento)

		ProjectSettings.set_setting("input/" + accion, {
			"deadzone": 0.2,
			"events": eventos,
		})
		print("  accion '%s' <- %s" % [accion, ACCIONES[accion]])

	var err := ProjectSettings.save()
	print("ProjectSettings.save() -> %s" % error_string(err))
	quit(0 if err == OK else 1)


## Borra del proyecto cualquier accion [code]input/*[/code] que ya no este en
## [constant ACCIONES]. Sin esto, renombrar una accion deja la vieja viva en el
## project.godot y el juego sigue leyendo el InputMap fantasma.
##
## NUNCA toca las acciones [code]input/ui_*[/code]: son las que trae el motor
## ([code]ui_accept[/code], [code]ui_cancel[/code], navegacion de foco de los menus
## de OUFW-13/OUFW-17). Borrarlas romperia la interfaz aunque no se note al correr
## el combate. Tampoco toca [code]ui_swap_input_direction[/code], que comparte prefijo.
func _podar_acciones_obsoletas() -> void:
	for propiedad in ProjectSettings.get_property_list():
		var nombre: String = propiedad.get("name", "")
		if not nombre.begins_with("input/"):
			continue
		var accion := nombre.trim_prefix("input/")
		if accion == "ui_swap_input_direction" or accion.begins_with("ui_"):
			continue
		if not ACCIONES.has(accion):
			ProjectSettings.set_setting(nombre, null)
			print("  podada accion obsoleta '%s'" % accion)
