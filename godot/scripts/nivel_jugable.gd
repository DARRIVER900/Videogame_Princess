class_name NivelJugable
extends NivelArena
## Base de los niveles jugables de produccion (OUFW-6/14/18).
##
## Anade a [NivelArena] todo lo que comparten los tres capitulos: instala la
## seleccion de princesas hecha en el menu (OUFW-17), activa la FSM del rival
## (OUFW-11), mantiene el HUD (OUFW-5), el temporizador (OUFW-12), el fin de
## combate (OUFW-16) y la intro de novela visual (OUFW-13).
##
## Las subclases solo declaran su numero de nivel, la escena siguiente y, si
## procede, su guion de intro. Asi la progresion del core loop (OUFW-18) vive en
## un unico sitio y no se duplica nivel a nivel.

const _NOMBRES_LOCOMOCION := {
	Personaje.Locomocion.DE_PIE: "DE PIE",
	Personaje.Locomocion.AGACHADO: "AGACHADO",
	Personaje.Locomocion.DERRAPE: "DERRAPE",
}

## Numero de capitulo/nivel (1 a 3). Se persiste en [SeleccionPartida].
@export var numero_nivel: int = 1
## Escena que carga "Siguiente Nivel" al ganar. Vacia = reintentar el nivel actual.
@export var siguiente_escena: String = ""
## Guion de intro que se muestra antes de combatir. Vacio = sin intro.
@export var intro: String = ""

var _etiqueta: Label
var _jugadora: Personaje
var _rival: Personaje
var _controlador: ControladorJugador
var _bot: ControladorBot
var _dialogo: DialogoUI
var _temporizador: TemporizadorCombate
var _gestor


func _ready() -> void:
	SeleccionPartida.nivel_actual = numero_nivel
	_instalar_seleccion()
	super._ready()
	_resolver_nodos()
	_configurar_gestor()
	_configurar_temporizador()
	_arrancar_intro()


func _resolver_nodos() -> void:
	_etiqueta = get_node_or_null("HUD/Estado")
	_jugadora = get_node_or_null("Jugadora") as Personaje
	_rival = get_node_or_null("Rival") as Personaje
	_controlador = get_node_or_null("Jugadora/Controlador") as ControladorJugador
	_bot = get_node_or_null("Rival/Bot") as ControladorBot
	_dialogo = get_node_or_null("Dialogo") as DialogoUI
	_temporizador = get_node_or_null("HUD/Temporizador") as TemporizadorCombate


## El gestor de fin de combate (OUFW-16) conoce la escena siguiente para que
## "Siguiente Nivel" avance el core loop en vez de recargar el mismo capitulo.
func _configurar_gestor() -> void:
	_gestor = get_node_or_null("GestorCombate")
	if _gestor == null:
		return
	_gestor.set("siguiente_escena", siguiente_escena)
	if _gestor.has_method("reiniciar_escucha"):
		_gestor.reiniciar_escucha()


func _configurar_temporizador() -> void:
	if _temporizador == null:
		return
	if not _temporizador.tiempo_agotado.is_connected(_on_tiempo_agotado):
		_temporizador.tiempo_agotado.connect(_on_tiempo_agotado)
	if _jugadora != null and not _jugadora.died.is_connected(_detener_temporizador):
		_jugadora.died.connect(_detener_temporizador)
	if _rival != null and not _rival.died.is_connected(_detener_temporizador):
		_rival.died.connect(_detener_temporizador)


## Solo al entrar desde el menu. Abrir la escena directamente deja el nivel en su
## estado de prueba (princesas fijas y bot inactivo).
func _instalar_seleccion() -> void:
	if not SeleccionPartida.partida_iniciada:
		return
	if not get_node_or_null("Jugadora") or not get_node_or_null("Rival"):
		return

	var ctrl := _reemplazar_personaje("Jugadora", SeleccionPartida.princesa_jugable,
		Vector2(-X_APARICION, Y_APARICION))
	var bot := _reemplazar_personaje("Rival", SeleccionPartida.clave_rival(),
		Vector2(X_APARICION, Y_APARICION))

	_montar_controlador(ctrl, "Jugadora", "Controlador", "Rival")
	_montar_controlador(bot, "Rival", "Bot", "Jugadora")


func _reemplazar_personaje(nombre: String, clave: String, posicion: Vector2) -> Node:
	var actual := get_node_or_null(nombre) as Personaje
	if actual == null:
		return null

	if _clave_de(actual) == clave:
		actual.position = posicion
		if actual.get_node_or_null("Controlador") != null:
			return actual.get_node_or_null("Controlador")
		return actual.get_node_or_null("Bot")

	var indice := actual.get_index()
	var ctrl := actual.get_node_or_null("Controlador")
	if ctrl == null:
		ctrl = actual.get_node_or_null("Bot")
	if ctrl != null:
		actual.remove_child(ctrl)

	var nueva := load(SeleccionPartida.ruta_de(clave)).instantiate() as Personaje
	nueva.name = nombre
	nueva.position = posicion
	actual.name = nombre + "_anterior"
	remove_child(actual)
	add_child(nueva)
	move_child(nueva, indice)
	actual.queue_free()
	return ctrl


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
		(ctrl as ControladorBot).activo = SeleccionPartida.partida_iniciada


func _clave_de(p: Personaje) -> String:
	if p is PrincesaDulcecito:
		return SeleccionPartida.DULCECITO
	if p is PrincesaChocolatito:
		return SeleccionPartida.CHOCOLATITO
	return ""


## Muestra la intro de novela visual (OUFW-13) solo al entrar desde el menu y una
## sola vez por partida: el combate y el temporizador quedan congelados hasta que
## el jugador avanza todas las lineas con Espacio o clic.
func _arrancar_intro() -> void:
	if _dialogo == null or intro == "" or not SeleccionPartida.partida_iniciada:
		return
	if SeleccionPartida.intro_vista:
		return
	if not _dialogo.iniciar(intro):
		return
	SeleccionPartida.intro_vista = true
	_dialogo.terminado.connect(_on_intro_terminada)
	_congelar_para_intro(true)


func _on_intro_terminada() -> void:
	_congelar_para_intro(false)
	if _temporizador != null:
		_temporizador.iniciar()


func _congelar_para_intro(congelar: bool) -> void:
	if _controlador != null:
		_controlador.activo = not congelar
		if congelar:
			_controlador.soltar_controles()
	if _bot != null:
		_bot.activo = not congelar
	if _jugadora != null:
		_jugadora.velocity.x = 0.0
	if congelar and _temporizador != null:
		_temporizador.detener()


func _on_tiempo_agotado() -> void:
	if _gestor != null and _gestor.has_method("forzar_derrota"):
		_gestor.forzar_derrota()


func _detener_temporizador() -> void:
	if _temporizador != null:
		_temporizador.detener()


func _process(_delta: float) -> void:
	if _etiqueta == null or _jugadora == null:
		return

	var rival_cableado := _controlador != null and is_instance_valid(_controlador.rival)
	var hitboxes := 0
	for hijo in _jugadora.get_children():
		if hijo is Hitbox and not hijo.consumida:
			hitboxes += 1

	var hurtbox_ok := _jugadora.get_node_or_null("Hurtbox") != null
	_etiqueta.text = "\n".join([
		"Nivel %d   Jugadora HP %d/%d   pociones %d   %s" % [
			numero_nivel, _jugadora.current_hp, _jugadora.hp_max,
			_jugadora.cantidad_pociones, _jugadora.texto_estado(),
		],
		"Rival     HP %d/%d   pociones %d   %s" % [
			_rival.current_hp if _rival != null else 0,
			_rival.hp_max if _rival != null else 0,
			_rival.cantidad_pociones if _rival != null else 0,
			_rival.texto_estado() if _rival != null else "Normal",
		],
		"",
		"A / D      moverse        W + A / D  salto diagonal",
		"S          agachar        S + A/D    derrape",
		"K          golpe normal   L          golpe fuerte",
		"J          carga (mantener y soltar)   E  pocion   U  veneno",
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
			"cableado" if rival_cableado else "SIN CABLEAR",
			"si" if hurtbox_ok else "NO",
			ControladorBot.nombre_estado(_bot.estado_actual) if _bot != null else "sin bot",
		],
		"hitboxes    %d activas" % hitboxes,
	])


func _texto_carga() -> String:
	if _jugadora != null and _jugadora.esta_cargando():
		return "acumulando %d%%" % roundi(_jugadora.carga_nivel() * 100.0)
	return "lista"
