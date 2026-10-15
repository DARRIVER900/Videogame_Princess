extends Node2D
## Escenario minimo para probar OUFW-2 (movimiento), OUFW-3 (hitbox/hurtbox),
## OUFW-9 (carga rompe-guardia) y OUFW-11 (FSM del rival) con teclado real.
##
## Responde a la pregunta que ninguna suite headless puede responder: ¿se siente
## fluido? Las suites de `tests/` demuestran que el codigo es correcto; esta arena
## demuestra que la respuesta a los criterios es subjetiva y exige una mano humana.
##
## NO es la arena de produccion: el graybox del Capitulo 1 es OUFW-6.

const _NOMBRES_LOCOMOCION := {
	Personaje.Locomocion.DE_PIE: "DE PIE",
	Personaje.Locomocion.AGACHADO: "AGACHADO",
	Personaje.Locomocion.DERRAPE: "DERRAPE",
}


@onready var _etiqueta: Label = get_node_or_null("HUD/Estado")
@onready var _jugadora: Personaje = get_node_or_null("Jugadora")
@onready var _rival: Personaje = get_node_or_null("Rival")
@onready var _controlador: ControladorJugador = get_node_or_null("Jugadora/Controlador")
@onready var _bot: ControladorBot = get_node_or_null("Rival/Bot")


func _process(_delta: float) -> void:
	if _etiqueta == null or _jugadora == null:
		return

	# Si `rival` no esta cableado, el flipper cae en el fallback de mirar hacia el
	# ultimo input y el criterio 3 no se esta probando de verdad.
	var rival_cableado := _controlador != null and is_instance_valid(_controlador.rival)

	# Hitboxes vivas del personaje jugable: el golpe "se ve" mientras esta activo.
	var hitboxes := 0
	for hijo in _jugadora.get_children():
		if hijo is Hitbox and not hijo.consumida:
			hitboxes += 1

	var hurtbox_ok := _jugadora.get_node_or_null("Hurtbox") != null

	_etiqueta.text = "\n".join([
		"OUFW-2/3/9/11 - arena de pruebas (no es OUFW-6)",
		"",
		"A / D      moverse        W + A / D  salto diagonal",
		"S          agachar        S + A/D    derrape",
		"K          golpe normal   L          golpe fuerte",
		"J          carga pesada   (mantener para acumular, soltar para golpear)",
		"",
		"locomocion  %s   (hurtbox x%.2f)" % [
			_NOMBRES_LOCOMOCION.get(_jugadora.estado_locomocion, "?"),
			_jugadora.factor_altura_cuerpo(),
		],
		"carga       %s" % _texto_carga(),
		"velocidad   vx=%6.1f   vy=%6.1f" % [_jugadora.velocity.x, _jugadora.velocity.y],
		"en suelo    %s" % ("si" if _jugadora.en_suelo() else "no"),
		"mirando     %s" % ("derecha" if _jugadora.mirando_a_la_derecha else "izquierda"),
		"rival       %s   hurtbox %s   FSM %s" % [
			"cableado" if rival_cableado else "SIN CABLEAR (flipper no verificable)",
			"si" if hurtbox_ok else "NO",
			ControladorBot.nombre_estado(_bot.estado_actual) if _bot != null else "sin bot",
		],
		"hitboxes    %d activas" % hitboxes,
		"HP          yo %d/%d   rival %d/%d (pociones %d)" % [
			_jugadora.current_hp, _jugadora.hp_max,
			_rival.current_hp if _rival != null else 0,
			_rival.hp_max if _rival != null else 0,
			_rival.cantidad_pociones if _rival != null else 0,
		],
	])


## Linea de la carga pesada (OUFW-9): nivel de acumulacion y escala del sprite.
func _texto_carga() -> String:
	if not _jugadora.esta_cargando():
		return "sin acumular"
	return "x%.2f  (+%d%% de dano, sprite x%.2f)" % [
		_jugadora.carga_nivel(),
		roundi((_jugadora.carga_nivel() * (_jugadora.multiplicador_carga_max - 1.0)) * 100.0),
		_jugadora.nodo_sprite.scale.x if _jugadora.nodo_sprite != null else 1.0,
	]
