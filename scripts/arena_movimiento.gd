extends Node2D
## Escenario minimo para probar OUFW-2 con teclado real.
##
## Responde a la pregunta que ninguna suite headless puede responder: ¿se siente
## fluido? Las pruebas de `tests/test_movimiento.gd` demuestran que el codigo es
## correcto; esta arena demuestra que la respuesta a los criterios 1 y 2 es
## subjetiva y exige una mano humana.
##
## NO es la arena de produccion: el graybox del Capitulo 1 es OUFW-6.

const _NOMBRES_LOCOMOCION := {
	Personaje.Locomocion.DE_PIE: "DE PIE",
	Personaje.Locomocion.AGACHADO: "AGACHADO",
	Personaje.Locomocion.DERRAPE: "DERRAPE",
}


@onready var _etiqueta: Label = get_node_or_null("HUD/Estado")
@onready var _jugadora: Personaje = get_node_or_null("Jugadora")
@onready var _controlador: ControladorJugador = get_node_or_null("Jugadora/Controlador")


func _process(_delta: float) -> void:
	if _etiqueta == null or _jugadora == null:
		return

	# Si `rival` no esta cableado, el flipper cae en el fallback de mirar hacia el
	# ultimo input y el criterio 3 no se esta probando de verdad.
	var rival_cableado := _controlador != null and is_instance_valid(_controlador.rival)

	_etiqueta.text = "\n".join([
		"OUFW-2 - arena de pruebas (no es OUFW-6)",
		"",
		"A / D      moverse        W + A / D  salto diagonal",
		"S          agachar        S + A/D    derrape",
		"",
		"locomocion  %s   (altura x%.2f)" % [
			_NOMBRES_LOCOMOCION.get(_jugadora.estado_locomocion, "?"),
			_jugadora.factor_altura_cuerpo(),
		],
		"velocidad   vx=%6.1f   vy=%6.1f" % [_jugadora.velocity.x, _jugadora.velocity.y],
		"en suelo    %s" % ("si" if _jugadora.en_suelo() else "no"),
		"mirando     %s" % ("derecha" if _jugadora.mirando_a_la_derecha else "izquierda"),
		"rival       %s" % ("cableado" if rival_cableado else "SIN CABLEAR (criterio 3 no verificable)"),
		"HP          %d/%d" % [_jugadora.current_hp, _jugadora.hp_max],
	])
