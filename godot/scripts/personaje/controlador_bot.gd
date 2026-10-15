class_name ControladorBot
extends Node
## Maquina de Estados Finitos (FSM) que da vida al rival enemigo (OUFW-11).
##
## Es el espejo de [ControladorJugador] con la misma filosofia: un nodo aparte del
## [Personaje] que no arrastra teclado y reutiliza exactamente la misma fisica y el
## mismo combate via [method Personaje.avanzar_movimiento] y los metodos de ataque.
##
## Estados del GDD seccion 5:
##   [constant EstadoBot.IDLE]       Quieto. Arranque y estados muertos del duelo.
##   [constant EstadoBot.ACERCARSE]  Camina hacia el rival hasta entrar en rango.
##   [constant EstadoBot.ATACAR]     Plantado, alterna golpe normal y fuerte.
##   [constant EstadoBot.USAR_POCION] Bebe una pocion (uida util) y espera.
##
## Las decisiones se reevaluan cada [member intervalo_decision] segundos en vez de
## en cada frame, para que el bot no parezca una maquina perfecta; entre evaluaciones
## el estado actual se "sostiene" con [method _mantener_estado].
##
## La poción se apoya en la API ya existente de [Personaje] ([method Personaje.aplicar_curacion]
## y [member Personaje.cantidad_pociones]); el inventario del JUGADOR y su tecla `E`
## son el issue OUFW-10 y estan fuera de este alcance.
##
## Referencia: OUFW-11 "Maquina de Estados (FSM) para el bot Enemigo".

## Estados de la FSM. [member estado_actual] solo cambia via [method _transicionar].
enum EstadoBot { IDLE, ACERCARSE, ATACAR, USAR_POCION }

## Se emite cada vez que la FSM cambia de estado. La escuchan el HUD de la arena
## y las pruebas de OUFW-11.
signal estado_cambiado(estado: EstadoBot)

## Personaje al que se le inyectan las decisiones. Si se deja vacio, se resuelve el
## primer ancestro [Personaje] en [method _ready].
@export var personaje: Personaje

## Rival al que persigue y golpea el bot. Si es `null` el bot se queda en IDLE.
@export var rival: Personaje

## Permite congelar la IA sin quitar el nodo de la escena (pausa, menus, turnos).
@export var activo: bool = true

## Distancia horizontal maxima (px) a la que el bot considera que esta "a golpe":
## por dentro ataca, por fuera se acerca.
@export var distancia_ataque: float = 120.0

## Segundos entre reevaluaciones de la FSM. Mas alto = decisiones mas "humanas"
## y reacciones mas tardias.
@export var intervalo_decision: float = 0.3

## Fraccion de vida ([member Personaje.ratio_hp]) por debajo de la cual el bot
## bebe pocion si le quedan unidades.
@export var umbral_vida_pocion: float = 0.35

## Vida que restaura cada pocion del bot. El valor del jugador (OUFW-10) es otro.
@export var curacion_por_pocion: int = 15

## Segundos que dura la accion de beber: el bot se planta mientras bebe, que es el
## riesgo que asume al gastar la pocion en plena pelea.
@export var tiempo_uso_pocion: float = 0.8

## Estado actual de la FSM. Solo lo escribe [method _transicionar]; leerlo para HUD
## y pruebas.
var estado_actual: EstadoBot = EstadoBot.IDLE

## Segundos restantes hasta la proxima reevaluacion de la FSM.
var _tiempo_decision: float = 0.0
## Segundos restantes de la accion acotada en curso (uso de pocion).
var _tiempo_accion: float = 0.0
## Alterna golpe normal / golpe fuerte en el estado ATACAR.
var _proximo_golpe_fuerte: bool = false


func _ready() -> void:
	if personaje == null:
		personaje = _buscar_personaje_ancestro()
	if personaje != null:
		# La alternancia de golpes avanza solo cuando un ataque se ejecuta de
		# verdad (la senal no se emite si el cooldown interno lo rechaza).
		personaje.ataque_ejecutado.connect(_on_ataque_ejecutado)


## Un paso de simulacion de la FSM: primero mirada al rival, despues decision (si
## toca) y por ultimo la accion continua del estado actual.
func _physics_process(delta: float) -> void:
	if not activo or personaje == null or personaje.esta_muerto:
		return

	# Sin rival vivo el duelo se acabo: el bot se queda quieto en IDLE.
	if rival == null or rival.esta_muerto:
		_transicionar(EstadoBot.IDLE)
		personaje.avanzar_movimiento(delta, 0.0)
		return

	# La mirada sigue al rival en todo momento, igual que el ControladorJugador.
	personaje.mirar_a_nodo(rival)

	if estado_actual == EstadoBot.USAR_POCION:
		# Mientras bebe no se mueve: esa es la ventana en la que es vulnerable.
		_tiempo_accion = maxf(0.0, _tiempo_accion - delta)
		personaje.avanzar_movimiento(delta, 0.0)
		if _tiempo_accion <= 0.0:
			_reevaluar()
		return

	if _tiempo_decision <= 0.0:
		_reevaluar()
	else:
		_tiempo_decision = maxf(0.0, _tiempo_decision - delta)

	_mantener_estado(delta)


## Evalua la situacion (vida propia, distancia al rival) y transiciona si hace falta.
## Se llama al arrancar, al agotarse [member intervalo_decision] y al terminar una
## accion acotada.
func _reevaluar() -> void:
	_tiempo_decision = intervalo_decision

	if _conviene_pocion():
		_transicionar(EstadoBot.USAR_POCION)
		_tiempo_accion = tiempo_uso_pocion
		_usar_pocion()
		return

	if _distancia_al_rival() <= distancia_ataque:
		_transicionar(EstadoBot.ATACAR)
		return

	_transicionar(EstadoBot.ACERCARSE)


## Accion continua del estado actual mientras no toca reevaluar.
func _mantener_estado(delta: float) -> void:
	match estado_actual:
		EstadoBot.ACERCARSE:
			var direccion := 1.0 if rival.global_position.x >= personaje.global_position.x else -1.0
			personaje.avanzar_movimiento(delta, direccion)
		EstadoBot.ATACAR:
			personaje.avanzar_movimiento(delta, 0.0)
			_golpear_si_puede()
		_:
			personaje.avanzar_movimiento(delta, 0.0)


## Intenta golpear cada frame; [Personaje] descarta el intento mientras su cooldown
## interno siga activo, asi que la cadencia real la marca el moveset, no el bot.
func _golpear_si_puede() -> void:
	if _proximo_golpe_fuerte:
		personaje.ataque_fuerte()
	else:
		personaje.ataque_normal()


func _on_ataque_ejecutado(_tipo: Personaje.TipoAtaque) -> void:
	_proximo_golpe_fuerte = not _proximo_golpe_fuerte


## Bebe una pocion: mueve el HP via [method Personaje.aplicar_curacion] y gasta una
## unidad del inventario SOLO si la curacion fue real. Duplica aqui las reglas de
## bloqueo de OUFW-10 (sin pociones o vida al tope) porque no hay peticion que
## validar: la decision es del propio bot.
func _usar_pocion() -> void:
	if personaje.cantidad_pociones <= 0 or personaje.current_hp >= personaje.hp_max:
		return
	var curado := personaje.aplicar_curacion(curacion_por_pocion)
	if curado > 0:
		personaje.cantidad_pociones -= 1


## [return] Si le conviene beber pocion: le quedan unidades, no esta al tope y su
## vida cae por debajo de [member umbral_vida_pocion].
func _conviene_pocion() -> bool:
	if personaje.cantidad_pociones <= 0:
		return false
	if personaje.current_hp >= personaje.hp_max:
		return false
	return personaje.ratio_hp < umbral_vida_pocion


## [return] Distancia horizontal en px al rival (la altura no cuenta: la arena es
## un plano y el bot no salta).
func _distancia_al_rival() -> float:
	return absf(rival.global_position.x - personaje.global_position.x)


## Fuerza una reevaluacion inmediata de la FSM en el proximo frame, sin esperar
## a [member intervalo_decision]. Para tests, reinicios de combate y cambios de
## escenario bruscos; el ciclo normal no lo necesita.
func reevaluar_ahora() -> void:
	_tiempo_decision = 0.0


func _transicionar(nuevo: EstadoBot) -> void:
	if estado_actual == nuevo:
		return
	estado_actual = nuevo
	estado_cambiado.emit(nuevo)


## Nombre corto del estado, para HUD de la arena y mensajes de prueba.
static func nombre_estado(estado: EstadoBot) -> String:
	match estado:
		EstadoBot.ACERCARSE:
			return "ACERCARSE"
		EstadoBot.ATACAR:
			return "ATACAR"
		EstadoBot.USAR_POCION:
			return "USAR POCION"
		_:
			return "IDLE"


func _buscar_personaje_ancestro() -> Personaje:
	var nodo := get_parent()
	while nodo != null:
		if nodo is Personaje:
			return nodo
		nodo = nodo.get_parent()
	return null
