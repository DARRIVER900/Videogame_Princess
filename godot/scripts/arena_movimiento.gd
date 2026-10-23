extends Node2D
## Escenario minimo para probar OUFW-2 (movimiento), OUFW-3 (hitbox/hurtbox),
## OUFW-9 (carga rompe-guardia) y OUFW-11 (FSM del rival) con teclado real, y punto
## de entrada del combate para OUFW-17.
##
## Responde a la pregunta que ninguna suite headless puede responder: ¿se siente
## fluido? Las suites de `tests/` demuestran que el codigo es correcto; esta arena
## demuestra que la respuesta a los criterios es subjetiva y exige una mano humana.
##
## Desde OUFW-17 la arena instala a las princesas elegidas en el menu: "Jugadora" es
## la princesa seleccionada y "Rival" su contraria, con sus controladores (jugador y
## bot) re-cableados. Abrir la arena sin seleccion previa (las suites de OUFW-2/3/9/11)
## conserva las princesas de la escena tal cual.
##
## NO es la arena de produccion: el graybox del Capitulo 1 es OUFW-6.

const _NOMBRES_LOCOMOCION := {
	Personaje.Locomocion.DE_PIE: "DE PIE",
	Personaje.Locomocion.AGACHADO: "AGACHADO",
	Personaje.Locomocion.DERRAPE: "DERRAPE",
}

## Posicion de la jugadora en la escena. Se reutiliza al reinstalar la princesa
## elegida para que el cambio de personaje no altere el layout del combate.
const POS_JUGADORA := Vector2(-160.0, -32.0)
## Posicion del rival en la escena (ver [constant POS_JUGADORA]).
const POS_RIVAL := Vector2(160.0, -32.0)


var _etiqueta: Label
var _jugadora: Personaje
var _rival: Personaje
var _controlador: ControladorJugador
var _bot: ControladorBot


## Al arrancar, sustituye las princesas de la escena por las que el jugador eligio
## en el menu (OUFW-17) y resuelve las referencias del HUD.
func _ready() -> void:
	_instalar_seleccion()
	_resolver_nodos()
	# El gestor de fin de combate (OUFW-16) se inicializo antes que esta funcion
	# (los hijos van primero en Godot), cuando aun existian las princesas viejas.
	# Se le pide reescuchar para que quede conectado a las princesas instaladas.
	var gestor := get_node_or_null("GestorCombate")
	if gestor != null and gestor.has_method("reiniciar_escucha"):
		gestor.reiniciar_escucha()


func _resolver_nodos() -> void:
	_etiqueta = get_node_or_null("HUD/Estado")
	_jugadora = get_node_or_null("Jugadora") as Personaje
	_rival = get_node_or_null("Rival") as Personaje
	_controlador = get_node_or_null("Jugadora/Controlador") as ControladorJugador
	_bot = get_node_or_null("Rival/Bot") as ControladorBot


## Instala en "Jugadora" y "Rival" las princesas elegidas en [SeleccionPartida]. El
## rival es siempre la contraparte. Se reemplaza el nodo entero (no solo el script)
## para que la princesa nueva corra su [_configurar_atributos_por_defecto] desde
## cero, con su identidad y atributos correctos.
##
## Los controladores (jugador y bot) viven DENTRO de su princesa y se re-montan
## sobre la princesa nueva: recrearlos perderia su configuracion.
##
## Sin seleccion previa (arena abierta directo) la escena ya trae a Dulcecito de
## jugadora y a Chocolatito de rival, que es exactamente la seleccion por defecto.
func _instalar_seleccion() -> void:
	if not get_node_or_null("Jugadora") or not get_node_or_null("Rival"):
		return

	var ctrl := _reemplazar_personaje("Jugadora", SeleccionPartida.princesa_jugable, POS_JUGADORA)
	var bot := _reemplazar_personaje("Rival", SeleccionPartida.clave_rival(), POS_RIVAL)

	# Los controladores desenganchados se vuelven a montar sobre las princesas
	# instaladas. El de la jugadora mira al rival; el del bot persigue a la jugadora.
	_montar_controlador(ctrl, "Jugadora", "Controlador", "Rival")
	_montar_controlador(bot, "Rival", "Bot", "Jugadora")


## Sustituye el nodo [param nombre] por una instancia nueva de la princesa
## [param clave], en la posicion [param posicion] y manteniendo el indice de hijo
## para que el orden de la escena no cambie (los .tscn y las pruebas lo asumen).
##
## [return] El [ControladorJugador] o [ControladorBot] desenganchado del nodo viejo
## (puede ser `null` si el nodo no tenia controlador). El llamador lo re-monta.
func _reemplazar_personaje(nombre: String, clave: String, posicion: Vector2) -> Node:
	var actual := get_node_or_null(nombre) as Personaje
	if actual == null:
		return null

	# Si el nodo de la escena YA es la princesa pedida, no se toca el arbol: solo se
	# recoloca. Mantiene intacto el camino por defecto que usan las suites de
	# OUFW-2/3/9/11 (nada de reparentar cuando no hace falta).
	if _clave_de(actual) == clave:
		actual.position = posicion
		if actual.get_node_or_null("Controlador") != null:
			return actual.get_node_or_null("Controlador")
		return actual.get_node_or_null("Bot")

	var indice := actual.get_index()
	# El controlador es hijo de la princesa vieja: se desengancha antes de liberarla
	# para poder reutilizarlo (recrearlo perderia su configuracion).
	var ctrl := actual.get_node_or_null("Controlador")
	if ctrl == null:
		ctrl = actual.get_node_or_null("Bot")
	if ctrl != null:
		actual.remove_child(ctrl)

	var nueva := load(SeleccionPartida.ruta_de(clave)).instantiate() as Personaje
	nueva.name = nombre
	nueva.position = posicion
	# El nodo viejo sigue en el arbol hasta fin de frame (queue_free); se renombra
	# para que el nuevo pueda tomar el nombre sin colision.
	actual.name = nombre + "_anterior"
	remove_child(actual)
	add_child(nueva)
	move_child(nueva, indice)
	actual.queue_free()
	return ctrl


## Re-monta el controlador [param ctrl] (jugador o bot) sobre el nodo [param nombre]
## y lo cablea a su objetivo [param objetivo]. Si no existia se crea uno nuevo.
## Si el controlador ya cuelga de la princesa correcta (camino "ya coincide") no se
## re-engancha: solo se refresca su cableado.
func _montar_controlador(ctrl: Node, nombre: String, nombre_nodo: String, objetivo: String) -> void:
	var p := get_node_or_null(nombre) as Personaje
	if p == null:
		return
	if ctrl == null:
		ctrl = ControladorJugador.new() if nombre_nodo == "Controlador" else ControladorBot.new()
		ctrl.name = nombre_nodo
		p.add_child(ctrl)
	elif ctrl.get_parent() != p:
		p.add_child(ctrl)
	ctrl.personaje = p
	ctrl.rival = get_node_or_null(objetivo)
	if ctrl is ControladorBot:
		(ctrl as ControladorBot).activo = true


## [return] La clave de seleccion ([constant SeleccionPartida.DULCECITO] o
## [constant SeleccionPartida.CHOCOLATITO]) que corresponde al script del personaje
## [param p], o [code]""[/code] si no es una de las dos princesas conocidas.
func _clave_de(p: Personaje) -> String:
	if p is PrincesaDulcecito:
		return SeleccionPartida.DULCECITO
	if p is PrincesaChocolatito:
		return SeleccionPartida.CHOCOLATITO
	return ""


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
