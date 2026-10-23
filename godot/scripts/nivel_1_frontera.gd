class_name Nivel1Frontera
extends NivelJugable
## Nivel 1 "La Frontera Despejada" (OUFW-6): primer capitulo jugable.
##
## La geometria, la seleccion de princesas, el HUD y el fin de combate viven en
## [NivelJugable]. Este script solo declara su lugar en el core loop (OUFW-18): es
## el unico nivel con intro de novela visual y lleva al Bosque al ganar.

const SIGUIENTE_NIVEL := "res://escenas/nivel_2_bosque.tscn"


func _ready() -> void:
	numero_nivel = 1
	siguiente_escena = SIGUIENTE_NIVEL
	intro = DialogoUI.RUTA_INTRO
	super._ready()
