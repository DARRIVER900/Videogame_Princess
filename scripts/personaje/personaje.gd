class_name Personaje
extends CharacterBody2D
## Clase base que encapsula el estado, los atributos escalables y las firmas de los
## metodos principales comunes a toda princesa del juego.
##
## Es la plantilla padre tanto de las instancias jugables como de la IA enemiga
## ([PrincesaDulcecito] y [PrincesaChocolatito]), de modo que el HUD y los sistemas
## de colision no necesitan conocer el tipo concreto.
##
## GDScript no tiene clases abstractas reales: la convencion es no instanciar
## [Personaje] directamente y sobrescribir [_configurar_atributos_por_defecto].
##
## Referencia: OUFW-1 "Implementar Clase Base Personaje (POO)".

## Perfil de combate (moveset). GDD seccion 8 "Fichas de Personajes".
enum Modset { AGIL_DISTANCIA, PESADO_PESA }

## Tipos de ataque del moveset base. El mapeo de teclas vive en la seccion [code][input]
## de [code]project.godot[/code] y lo consumen [ControladorJugador] (OUFW-2) y los
## sistemas de hitbox (OUFW-3); aqui solo se declara el tipo para que
## [method recibir_dano] pueda differentiate.
enum TipoAtaque { GOLPE_NORMAL, GOLPE_FUERTE, VENENO, SUPER_PESADO_CARGA }

## Poses del cuerpo. Las dos ultimas rebajan la altura del personaje y son la senal
## que OUFW-3 necesita para encoger la Hurtbox (GDD seccion 5: `S` y `S + A/D`).
enum Locomocion { DE_PIE, AGACHADO, DERRAPE }

## Equivalente a `OnHealthChanged` en OUFW-1. Lo consume el HUD (OUFW-5).
signal health_changed(current_hp: int, hp_max: int)

## Equivalente a `OnDeath` en OUFW-1. Se emite una sola vez por combate.
signal died

## Cambia la pose del cuerpo (OUFW-2). Lo escucha OUFW-3 para redimensionar la
## Hurtbox y la animacion cuando [member estado_locomocion] pasa a una pose baja.
signal locomocion_cambiada(estado: Locomocion)

## Se lanzo un salto. [param direccion_horizontal] es -1, 0 o 1 y distingue el
## salto vertical (`W`) del diagonal (`W + A/D`) y del salto hacia atras.
signal salto_realizado(direccion_horizontal: int)

## Arranco un derrape hacia [param direccion] (-1 o 1) con `S + A/D`.
signal derrape_iniciado(direccion: int)

## Toco suelo veniendo del aire. Sirve para anticipos, polvo y camara.
signal aterrizaje

@export_group("Identidad")
## Nombre mostrable en la interfaz y en los dialogos de novela visual.
@export var nombre: String = ""
## Clave del skin/estetica activa. Ver GDD seccion 8.
@export var id_skin_activa: String = ""

@export_group("Combate")
## Vida maxima. Es el techo que respeta [method aplicar_curacion].
@export var hp_max: int = 100
## Escalador aplicado al dano de cada ataque. 1.0 = dano base, >1 = glass cannon.
@export var multiplicador_dano: float = 1.0
## Unidades de pocion disponibles. El consumo se implementa en OUFW-10.
@export var cantidad_pociones: int = 3
## Perfil de combate que define el moveset disponible.
@export var modset_clase: Modset = Modset.AGIL_DISTANCIA

@export_group("Movimiento")
## Velocidad objetivo en X de pie, en px/s. Es el valor al que la aceleracion lleva
## a [member velocity] mientras se mantiene `A` o `D`.
@export var velocidad_movimiento: float = 220.0
## La velocidad de pie se multiplica por este factor mientras se mantiene `S` sola.
@export var multiplicador_velocidad_agachado: float = 0.45
## Velocidad fija que impone el derrape (`S + A/D`) mientras dura.
@export var velocidad_derrape: float = 430.0
## Duracion maxima del derrape en segundos. Cumplida, el personaje vuelve a estar
## de pie (o agachado si `S` sigue pulsada) sin quedar patinando.
@export var duracion_derrape: float = 0.35
## Impulso vertical del salto en px/s. Negativo porque en Godot la Y crece hacia abajo.
@export var fuerza_salto: float = -520.0
## `W + A/D` convierte el salto en diagonal: anade esta fraccion de
## [member velocidad_movimiento] como empuje lateral.
@export var multiplicador_salto_diagonal: float = 0.6
## Salto hacia atras (respecto a la mirada) con este multiplicador extra de
## alcance, que es lo que lo hace util como evasion.
@export var multiplicador_salto_atras: float = 1.25
## Gravedad propia del personaje en px/s^2. No usamos la del proyecto porque el
## multiplicador de caida deja el salto mas seco y legible.
@export var gravedad_personaje: float = 1600.0
## Al caer ([member velocity] con Y positiva) la gravedad se multiplica por esto:
## la caida pesa mas que la subida.
@export var multiplicador_gravedad_caida: float = 1.6
## Tope de velocidad de caida, para no atravessar el suelo en caida libre.
@export var velocidad_caida_maxima: float = 1000.0
## Cambio maximo de velocidad en X por segundo sobre el suelo.
@export var aceleracion_suelo: float = 2600.0
## Frenado sobre el suelo. Deliberadamente mayor que [member aceleracion_suelo] para
## que soltar la tecla detenga al personaje en vez de dejarlo deslizar.
@export var frenado_suelo: float = 3400.0
## Control lateral en el aire. Menor que en suelo: permite corregir la trayectoria
## sin convertirse en vuelo.
@export var aceleracion_aire: float = 1200.0
## Margen tras abandonar el suelo durante el cual `W` todavia cuenta como salto
## (coyote time). Absorbe el frame en que el suelo se pierde un instante.
@export var coyote_salto: float = 0.10
## Margen durante el cual un `W` pulsado antes de tocar suelo queda guardado y se
## ejecuta al aterrizar (jump buffer). Evita el input perdido al aterrizar.
@export var buffer_salto: float = 0.12

@export_group("Pose")
## Fraccion de altura del cuerpo al agacharse (`S`), que OUFW-3 aplica a la Hurtbox.
@export var factor_altura_agachado: float = 0.5
## Fraccion de altura durante el derrape: algo mas alta que agachada para que el
## golpe bajo siga siendo alcanzable.
@export var factor_altura_derrape: float = 0.6

@export_group("Presentacion")
## Sprite que se voltea con el flipper. Si se deja vacio se busca el primer hijo
## [Sprite2D] o [AnimatedSprite2D], que es la convencion de las escenas de OUFW-6.
@export var nodo_sprite: CanvasItem

## Vida actual. La inicializa [_ready] a partir de [member hp_max] y solo se
## modifica mediante [method recibir_dano] o [method aplicar_curacion].
var current_hp: int = 0

## Se enciende en cuanto la vida llega a 0. Impide que un segundo golpe en el
## mismo frame dispare [signal died] una segunda vez.
var esta_muerto: bool = false

## Pose actual del cuerpo. La escribe [method avanzar_movimiento] a partir de `S`
## y `S + A/D`, nunca el jugador directamente.
var estado_locomocion: Locomocion = Locomocion.DE_PIE

## Sentido en el que mira la princesa. La fija [method mirar_hacia] (el rival) o,
## si no hay objetivo, la direccion de avance.
var mirando_a_la_derecha: bool = true

## Marca que otro sistema (el controlador del jugador) ya decidio la mirada de este
## frame. La consume [method avanzar_movimiento] para no sobreescribirla con el input.
var mirada_externa: bool = false

## Segundos que le quedan al derrape en curso.
var tiempo_derrape: float = 0.0

## Fraccion de vida actual en rango 0.0..1.0. La consume el HUD para calcular el
## `fill_amount` de la barra (OUFW-5).
var ratio_hp: float:
	get:
		if hp_max <= 0:
			return 0.0
		return float(current_hp) / float(hp_max)

## Direccion en X del derrape en curso (-1 o 1).
var _direccion_derrape: int = 1
## Impide que `S + D` mantenido reinicie el derrape en bucle: hay que soltar el
## input para volver a lanzarlo.
var _derrape_gastado: bool = false
## Margen restante de coyote time.
var _coyote_restante: float = 0.0
## Margen restante de jump buffer.
var _buffer_restante: float = 0.0
## Estado de suelo del frame anterior, para detectar el aterrizaje.
var _estaba_en_suelo: bool = false


## Aplica los valores por defecto del personaje y lo deja vivo y a tope de vida.
##
## El orden importa: primero [_configurar_atributos_por_defecto] (que las
## subclases sobrescriben para fijar su identidad y su [member hp_max]), y solo
## despues se deriva [member current_hp] de ese [member hp_max].
func _ready() -> void:
	_configurar_atributos_por_defecto()
	current_hp = hp_max
	esta_muerto = false
	if nodo_sprite == null:
		nodo_sprite = _buscar_sprite()
	_estaba_en_suelo = en_suelo()
	_aplicar_flip()


## Punto de extension donde cada princesa declara su identidad y sus atributos
## base tomados del GDD (seccion 8). La clase base no sobrescribe nada, de modo
## que conserva los valores por defecto de los campos exportados.
##
## Se invoca desde [_ready], por lo que los valores aplican tanto en el Editor
## como en nodos instanciados en runtime (bot enemigo, seleccion de personaje).
func _configurar_atributos_por_defecto() -> void:
	pass


## Aplica dano al personaje (OUFW-1). El HP nunca baja de 0 y, al alcanzarlo, se
## marca como muerto y se emite [signal died] exactamente una vez.
##
## El parametro [param tipo] queda sin uso aqui: los modificadores por tipo de
## ataque (veneno, rotura de guardia) llegan en OUFW-8 y OUFW-9.
@warning_ignore("unused_parameter")
func recibir_dano(cantidad: int, tipo: TipoAtaque = TipoAtaque.GOLPE_NORMAL) -> void:
	if esta_muerto or cantidad <= 0:
		return

	current_hp = maxi(0, current_hp - cantidad)
	health_changed.emit(current_hp, hp_max)

	if current_hp <= 0:
		esta_muerto = true
		died.emit()


## Restaura vida sin exceder [member hp_max] y notifica el cambio al HUD (OUFW-1).
##
## Este metodo NO descuenta pociones: solo mueve el HP. El gasto de inventario y
## las reglas de bloqueo (sin pociones / vida al 100%) pertenecen a OUFW-10, que
## debe llamar a este metodo una vez validada la peticion.
## [param hp_restaurada] se descarta si el personaje ya esta al tope de vida.
## [return] Cuanta vida se recupero realmente (0 si ya estaba al tope).
func aplicar_curacion(hp_restaurada: int) -> int:
	if esta_muerto or hp_restaurada <= 0:
		return 0

	var vida_previa := current_hp
	current_hp = mini(hp_max, current_hp + hp_restaurada)

	if current_hp != vida_previa:
		health_changed.emit(current_hp, hp_max)

	return current_hp - vida_previa


# --- OUFW-2: locomocion (movimiento, salto, agachado, derrape y flipper) ---

## Avanza un paso de simulacion de la locomotion. Es el UNICO punto de entrada del
## movimiento, a proposito: [Personaje] no lee teclas por su cuenta para que el bot
## de OUFW-11 pueda reutilizar exactamente la misma fisica con su FSM.
##
## [param delta] segundos del paso de fisica, [param direccion] -1.0..1.0 en X,
## [param quiere_saltar] `W` en este frame, [param quiere_agacharse] `S` mantenido.
func avanzar_movimiento(delta: float, direccion: float, quiere_saltar: bool = false, quiere_agacharse: bool = false) -> void:
	if esta_muerto or delta <= 0.0:
		return

	# La mirada la fijo el controlador (el rival manda); si nadie la fijo, la
	# orientamos con el input. El flag vale solo para este frame.
	var mirar_con_input := not mirada_externa
	mirada_externa = false

	var suelo := en_suelo()
	_actualizar_coyote(delta, suelo)
	_actualizar_buffer_salto(delta, quiere_saltar)
	_actualizar_derrape(delta)
	_actualizar_locomocion(direccion, quiere_agacharse, suelo)
	var saltando := _intentar_saltar(direccion)
	# En el frame del despegue no se toca la velocidad horizontal: el impulso del
	# salto diagonal acaba de fijarse y la aceleracion de suelo lo devolverian
	# hacia la velocidad de caminar en el mismo frame, dejando
	# multiplicador_salto_diagonal sin efecto observable.
	if not saltando:
		_actualizar_velocidad_x(delta, direccion, suelo)
	_actualizar_gravedad(delta, suelo)

	if mirar_con_input:
		_invertir_por_movimiento(direccion)

	if is_inside_tree():
		move_and_slide()

	var suelo_final := en_suelo()
	if suelo_final and not _estaba_en_suelo:
		aterrizaje.emit()
	_estaba_en_suelo = suelo_final


## Traduce `S` y `S + A/D` a la pose del cuerpo (GDD seccion 5).
func _actualizar_locomocion(direccion: float, quiere_agacharse: bool, suelo: bool) -> void:
	var dir := _direccion_discreta(direccion)

	if not quiere_agacharse:
		_derrape_gastado = false
		_fijar_locomocion(Locomocion.DE_PIE)
		return

	if dir == 0:
		_derrape_gastado = false
		_fijar_locomocion(Locomocion.AGACHADO)
		return

	# El derrape solo arranca desde el suelo y no se renueva mientras dure: mantener
	# `S + D` da un unico impulso y despues el personaje frena hasta el suelo.
	if suelo and not _derrape_gastado:
		_iniciar_derrape(dir)


## Lanza el salto diagonal (`W + A/D`) o vertical (`W`) si hay margen valido.
## [return] Si el salto llego a ejecutarse.
func _intentar_saltar(direccion: float) -> bool:
	if _buffer_restante <= 0.0 or _coyote_restante <= 0.0:
		return false

	var dir := _direccion_discreta(direccion)
	velocity.y = fuerza_salto

	if dir != 0:
		var alcance := velocidad_movimiento * multiplicador_salto_diagonal
		# Saltar hacia atras respecto a la mirada (es decir, alejandose del rival)
		# recibe un plus de alcance: es la evasion de verdad.
		if dir != _signo_mirada():
			alcance *= multiplicador_salto_atras
		velocity.x = float(dir) * alcance

	_buffer_restante = 0.0
	_coyote_restante = 0.0
	# Un derrape no sobrevive al despegue: se degrada a pose agachada.
	if estado_locomocion == Locomocion.DERRAPE:
		_fijar_locomocion(Locomocion.AGACHADO)
	salto_realizado.emit(dir)
	return true


## Lleva [member velocity] en X hacia el objetivo con aceleracion y frenado distintos.
func _actualizar_velocidad_x(delta: float, direccion: float, suelo: bool) -> void:
	if estado_locomocion == Locomocion.DERRAPE:
		# Durante el derrape manda el impulso: la friccion se apaga un tiempo.
		velocity.x = float(_direccion_derrape) * velocidad_derrape
		return

	var objetivo := clampf(direccion, -1.0, 1.0) * velocidad_movimiento
	if estado_locomocion == Locomocion.AGACHADO:
		objetivo *= multiplicador_velocidad_agachado

	if suelo:
		var paso := frenado_suelo if is_zero_approx(objetivo) else aceleracion_suelo
		velocity.x = move_toward(velocity.x, objetivo, paso * delta)
	elif not is_zero_approx(objetivo):
		# En el aire solo se corrige la trayectoria si hay input; sin input se
		# conserva la inercia para no cortar a la mitad el salto diagonal.
		velocity.x = move_toward(velocity.x, objetivo, aceleracion_aire * delta)


func _actualizar_gravedad(delta: float, suelo: bool) -> void:
	if suelo and velocity.y >= 0.0:
		velocity.y = 0.0
		return

	var g := gravedad_personaje
	if velocity.y > 0.0:
		g *= multiplicador_gravedad_caida
	velocity.y = minf(velocity.y + g * delta, velocidad_caida_maxima)


func _actualizar_coyote(delta: float, suelo: bool) -> void:
	if suelo:
		_coyote_restante = coyote_salto
	else:
		_coyote_restante = maxf(0.0, _coyote_restante - delta)


func _actualizar_buffer_salto(delta: float, quiere_saltar: bool) -> void:
	if quiere_saltar:
		_buffer_restante = buffer_salto
	else:
		_buffer_restante = maxf(0.0, _buffer_restante - delta)


func _actualizar_derrape(delta: float) -> void:
	if estado_locomocion != Locomocion.DERRAPE:
		return
	tiempo_derrape = maxf(0.0, tiempo_derrape - delta)
	if tiempo_derrape <= 0.0:
		# Cumplido el tiempo, se pierde el impulso de golpe: el personaje queda
		# de pie o agachado, pero nunca patinando.
		_fijar_locomocion(Locomocion.AGACHADO)


func _iniciar_derrape(direccion: int) -> void:
	_direccion_derrape = 1 if direccion >= 0 else -1
	tiempo_derrape = duracion_derrape
	_derrape_gastado = true
	velocity.x = float(_direccion_derrape) * velocidad_derrape
	_fijar_locomocion(Locomocion.DERRAPE)
	derrape_iniciado.emit(_direccion_derrape)


func _fijar_locomocion(nuevo: Locomocion) -> void:
	if estado_locomocion == nuevo:
		return
	estado_locomocion = nuevo
	locomocion_cambiada.emit(nuevo)


## Gira la princesa para mirar a [param posicion_objetivo]. Este es el sprite
## flipper: la mirada sigue al rival, no al ultimo input.
func mirar_hacia(posicion_objetivo: Vector2) -> void:
	# El signo va como float explicito: pasar el int a un parametro bool daria `true`
	# tanto para +1 como para -1 y el sprite nunca se voltearia.
	var objetivo := 1.0 if posicion_objetivo.x >= global_position.x else -1.0
	mirada_externa = true
	_fijar_mirando(objetivo > 0.0)


## Como [method mirar_hacia] pero tomando la posicion de otro nodo, normalmente el
## rival. Pensado para llamarlo ANTES de [method avanzar_movimiento] en el mismo
## frame de fisica.
func mirar_a_nodo(objetivo: Node2D) -> void:
	if objetivo == null:
		return
	mirar_hacia(objetivo.global_position)


func _fijar_mirando(derecha: bool) -> void:
	if mirando_a_la_derecha == derecha:
		return
	mirando_a_la_derecha = derecha
	_aplicar_flip()


## Voltea el sprite con `flip_h`; para nodos sin esa propiedad se usa `scale.x`.
func _aplicar_flip() -> void:
	if nodo_sprite == null:
		return
	if nodo_sprite is Sprite2D or nodo_sprite is AnimatedSprite2D:
		# `flip_h` conserva el pivote del sprite; `scale.x` lo desplazaria.
		nodo_sprite.set("flip_h", not mirando_a_la_derecha)
		return
	nodo_sprite.scale.x = 1.0 if mirando_a_la_derecha else -1.0


func _buscar_sprite() -> CanvasItem:
	for hijo in get_children():
		if hijo is Sprite2D or hijo is AnimatedSprite2D:
			return hijo
	return null


## Indica si el personaje esta apoyado. Es un alias de [method CharacterBody2D.is_on_floor]
## con nombre corto, para que el codigo de OUFW-11 se lea igual que el de OUFW-2.
## OJO: vale `false` hasta el primer [method CharacterBody2D.move_and_slide], porque
## Godot deduce el contacto con el suelo al mover el cuerpo, no antes.
func en_suelo() -> bool:
	return is_on_floor()


## Direccion en X del empuje actual: -1, 0 o 1.
func direccion_horizontal() -> int:
	if velocity.x > 0.0:
		return 1
	if velocity.x < 0.0:
		return -1
	return 0


## Fraccion de altura del cuerpo actual. OUFW-3 la aplica a la Hurtbox: 1.0 de pie,
## [member factor_altura_agachado] agachada, [member factor_altura_derrape] derrapando.
func factor_altura_cuerpo() -> float:
	match estado_locomocion:
		Locomocion.AGACHADO:
			return factor_altura_agachado
		Locomocion.DERRAPE:
			return factor_altura_derrape
		_:
			return 1.0


## [return] Si la pose actual es una pose baja (agachada o derrapando).
func esta_agachado() -> bool:
	return estado_locomocion != Locomocion.DE_PIE


## [return] Si hay un derrape en curso.
func esta_derrapando() -> bool:
	return estado_locomocion == Locomocion.DERRAPE


## Convierte un eje continuo -1.0..1.0 en -1, 0 o 1. A y D a la vez se anulan.
func _direccion_discreta(direccion: float) -> int:
	if direccion > 0.0:
		return 1
	if direccion < 0.0:
		return -1
	return 0


## +1 si mira a la derecha, -1 si mira a la izquierda.
func _signo_mirada() -> int:
	return 1 if mirando_a_la_derecha else -1


func _invertir_por_movimiento(direccion: float) -> void:
	if is_zero_approx(direccion):
		return
	_fijar_mirando(direccion > 0.0)

