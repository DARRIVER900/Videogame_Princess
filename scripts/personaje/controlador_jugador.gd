class_name ControladorJugador
extends Node
## Lee el [InputMap] y lo traduce a la API de locomotion de [Personaje] (OUFW-2).
##
## Es un nodo aparte y no una herencia de [Personaje] a proposito: asi el bot de
## OUFW-11 puede reutilizar la misma fisica sin arrastrar el teclado, y el
## personaje jugable se puede congelar ([member activo]) sin tocar sus controles.
##
## Colocacion recomendada: hijo del [Personaje] jugador. Si se deja
## [member personaje] vacio se busca el primer ancestro [Personaje].
##
## Referencia: GDD seccion 5 "Mecanicas principales" y Pract_1.md.

## Acciones definidas en la seccion [code][input] de [code]project.godot[/code], que
## se genera con [code]tools/configurar_input_map.gd[/code].
const ACCION_IZQUIERDA := "mover_izquierda"
const ACCION_DERECHA := "mover_derecha"
const ACCION_SALTAR := "salto"
const ACCION_AGACHAR := "agachar"

## Personaje al que se le inyectan los comandos. Si se deja vacio, se resuelve el
## primer ancestro [Personaje] en [method _ready].
@export var personaje: Personaje

## Rival al que debe mirar la princesa. Si es `null`, la mirada sigue al input.
@export var rival: Node2D

## Permite congelar los controles sin quitar el nodo de la escena (pausa, menus,
## pantalla de Game Over de OUFW-16).
@export var activo: bool = true


func _ready() -> void:
	if personaje == null:
		personaje = _buscar_personaje_ancestro()


## Traduce el mando a la locomotion: `A`/`D` mueven, `W` salta (con `A`/`D` sale
## diagonal) y `S` agacha o derrapa si ademas hay direccion.
func _physics_process(delta: float) -> void:
	if not activo or personaje == null or personaje.esta_muerto:
		return

	# La mirada se resuelve primero para que el salto diagonal de este frame salga
	# alejandose del rival, y `mirar_a_nodo` marque [member Personaje.mirada_externa].
	if rival != null:
		personaje.mirar_a_nodo(rival)

	personaje.avanzar_movimiento(
		delta,
		leer_direccion(),
		Input.is_action_just_pressed(ACCION_SALTAR),
		Input.is_action_pressed(ACCION_AGACHAR)
	)


## Direccion de avance del jugador: -1.0 izquierda, 0.0 quieto, 1.0 derecha.
##
## [param fuerza] descarta pulsaciones debiles (dead zone) para que un mando analogico
## no produzca tembleque al soltar la palanca. Pulsar `A` y `D` a la vez se anula.
func leer_direccion(fuerza: float = 1.0) -> float:
	var dir := 0.0
	if Input.get_action_strength(ACCION_DERECHA) >= fuerza:
		dir += 1.0
	if Input.get_action_strength(ACCION_IZQUIERDA) >= fuerza:
		dir -= 1.0
	return clampf(dir, -1.0, 1.0)


## Elimina el input del jugador del mapa de acciones. Se usa al cambiar de
## personaje o al reiniciar el combate, para no dejar teclas "pegadas".
func soltar_controles() -> void:
	for accion: String in [ACCION_IZQUIERDA, ACCION_DERECHA, ACCION_SALTAR, ACCION_AGACHAR]:
		if Input.is_action_pressed(accion):
			Input.action_release(accion)


func _buscar_personaje_ancestro() -> Personaje:
	var nodo := get_parent()
	while nodo != null:
		if nodo is Personaje:
			return nodo
		nodo = nodo.get_parent()
	return null
