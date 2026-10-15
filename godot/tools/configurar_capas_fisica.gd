extends SceneTree
## Nombra las capas de fisica 2D en project.godot (Physics Layer Matrix, OUFW-6).
## Ejecutar una vez, o cuando se anada o renombre una capa:
##
##   godot --headless --script res://tools/configurar_capas_fisica.gd
##
## Los valores en bruto viven en Personaje (CAPA_GROUND, CAPA_HURTBOX, CAPA_HITBOX, CAPA_PERSONAJE):
## el numero de capa N corresponde al valor 2^(N-1).
##
## Matriz (quien vive en cada capa y que detecta):
##   1 Ground      suelo y paredes          no detecta nada
##   2 Hurtbox     zona que recibe dano     detecta Hitbox
##   3 Hitbox      zona que inflige dano    detecta Hurtbox
##   4 Personajes  cuerpo de las princesas  detecta Ground y Personajes

const CAPAS := {
	1: "Ground",
	2: "Hurtbox",
	3: "Hitbox",
	4: "Personajes",
}


func _init() -> void:
	for numero: int in CAPAS:
		ProjectSettings.set_setting("layer_names/2d_physics/layer_%d" % numero, CAPAS[numero])
		print("  capa %d <- %s" % [numero, CAPAS[numero]])

	var err := ProjectSettings.save()
	print("ProjectSettings.save() -> %s" % error_string(err))
	quit(0 if err == OK else 1)