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

## Estados de skin que activan diferentes sprites (OUFW-21).
enum SkinState { NORMAL, COMBO_ALTO, DAÑADO, GOLPE_CRITICO, NO_JUGADOR }

## Claves de skin válidas (deben coincidir con [member id_skin_activa] en cada princesa).
const SKIN_CANDYR_DEFAULT: String = "SKIN_CANDYR_DEFAULT"
const SKIN_CHOCOLATE_DEFAULT: String = "SKIN_CHOCOLATE_DEFAULT"

## Mapeo de skins a rutas de texturas. Usa strings como claves porque los enums
## no son expresiones constantes válidas en diccionarios const en GDScript.
var RUTAS_SPRITES: Dictionary = {
	SKIN_CANDYR_DEFAULT: {
		"NORMAL": "res://recursos/Dulcecito-removebg-preview.png",
		"COMBO_ALTO": "res://recursos/Dulcecito-removebg-preview.png",
		"DAÑADO": "res://recursos/Dulcecito-removebg-preview.png",
		"GOLPE_CRITICO": "res://recursos/Dulcecito-removebg-preview.png",
		"NO_JUGADOR": "res://recursos/placeholder_dulcecito.png"
	},
	SKIN_CHOCOLATE_DEFAULT: {
		"NORMAL": "res://recursos/chocolatito-removebg-preview.png",
		"COMBO_ALTO": "res://recursos/chocolatito-removebg-preview.png",
		"DAÑADO": "res://recursos/chocolatito-removebg-preview.png",
		"GOLPE_CRITICO": "res://recursos/chocolatito-removebg-preview.png",
		"NO_JUGADOR": "res://recursos/placeholder_chocolatito.png"
	}
}

## Tipos de ataque del moveset base. El mapeo de teclas vive en la seccion [code][input]
## de [code]project.godot[/code] y lo consumen [ControladorJugador] (OUFW-2) y los
## sistemas de hitbox (OUFW-3); aqui solo se declara el tipo para que
## [method recibir_dano] pueda diferenciar.
enum TipoAtaque { GOLPE_NORMAL, GOLPE_FUERTE, VENENO, SUPER_PESADO_CARGA }

## Poses del cuerpo. Las dos ultimas rebajan la altura del personaje y son la senal
## que OUFW-3 necesita para encoger la Hurtbox (GDD seccion 5: `S` y `S + A/D`).
enum Locomocion { DE_PIE, AGACHADO, DERRAPE }

## Capas 2D del proyecto. UNICA fuente de verdad de los valores en bruto: [Hitbox],
## [Hurtbox] y las escenas leen estas constantes. El numero de capa N corresponde al
## valor 2^(N-1); los NOMBRES de la matriz viven en project.godot y se generan con
## [code]tools/configurar_capas_fisica.gd[/code] (OUFW-6).
##   1 Ground (suelo y paredes), 2 Hurtbox, 3 Hitbox, 4 Personajes.
const CAPA_GROUND := 1
const CAPA_HURTBOX := 2
const CAPA_HITBOX := 4
const CAPA_PERSONAJE := 8

## Altura (px, respecto al centro del cuerpo) a la que nace el volumen de un golpe,
## a la altura del torso. Antes era un -24.0 escrito a mano en [method _ejecutar_ataque].
const ALTURA_GOLPE := -24.0

## Motivos por los que [method usar_pocion] puede negarse (OUFW-10). El HUD (OUFW-5)
## los usa para mostrar el feedback correcto (parpadeo del contador, sonido de error).
enum MotivoBloqueoPocion { NINGUNO, SIN_POCIONES, VIDA_COMPLETA, MUERTO }

## Estados alterados que puede sufrir una princesa (OUFW-8). Solo hay uno activo a la
## vez; el HUD (OUFW-5) muestra su texto con [method texto_estado].
enum EstadoAlterado { NINGUNO, ENVENENADO }

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

## Se lanzo un ataque que genero un hitbox (OUFW-3). Lo escucha el HUD para la
## retroalimentacion y OUFW-8 para encadenar el moveset.
signal ataque_ejecutado(tipo: TipoAtaque)

## Se empezo a acumular la carga pesada (OUFW-9, tecla `J`).

## Escala base del sprite (capturada en _ready desde la escena).
## Se usa para restaurar la escala correcta tras efectos visuales.
var _escala_base_sprite: Vector2 = Vector2.ONE

## Aplica el sprite correspondiente al estado actual de skin (OUFW-21).
func _aplicar_sprite_por_skin_estado(nuevo_estado: SkinState) -> void:
	if nuevo_estado == skin_estado:
		return
	skin_estado = nuevo_estado
	if nodo_sprite == null:
		return
	var estado_str: String = _skin_state_to_string(skin_estado)
	var ruta_textura: String = RUTAS_SPRITES.get(id_skin_activa, {}).get(estado_str)
	if ruta_textura == null:
		return
	nodo_sprite.texture = load(ruta_textura)
	skin_cambiada.emit(skin_estado)


## Convierte un valor de SkinState a su nombre en string (GDScript no permite .name en enums).
func _skin_state_to_string(estado: SkinState) -> String:
	match estado:
		SkinState.NORMAL:
			return "NORMAL"
		SkinState.COMBO_ALTO:
			return "COMBO_ALTO"
		SkinState.DAÑADO:
			return "DAÑADO"
		SkinState.GOLPE_CRITICO:
			return "GOLPE_CRITICO"
		SkinState.NO_JUGADOR:
			return "NO_JUGADOR"
		_:
			return "NORMAL"


## Establece el estado de skin a NORMAL (base street fighter) (OUFW-21).
func establecer_skin_normal() -> void:
	_aplicar_sprite_por_skin_estado(SkinState.NORMAL)

## Establece el estado de skin a COMBO_ALTO (sprites de combo) (OUFW-21).
func establecer_skin_combo_alto() -> void:
	_aplicar_sprite_por_skin_estado(SkinState.COMBO_ALTO)

## Establece el estado de skin a DAÑADO (sprites de daño) (OUFW-21).
func establecer_skin_dañado() -> void:
	_aplicar_sprite_por_skin_estado(SkinState.DAÑADO)

## Establece el estado de skin a GOLPE_CRITICO (sprites de golpe crítico) (OUFW-21).
func establecer_skin_golpe_critico() -> void:
	_aplicar_sprite_por_skin_estado(SkinState.GOLPE_CRITICO)

## Establece el estado de skin a NO_JUGADOR (sprite placeholder) (OUFW-21).
func establecer_skin_no_jugador() -> void:
	_aplicar_sprite_por_skin_estado(SkinState.NO_JUGADOR)
signal carga_iniciada

## Nivel de carga actual (0.0..1.0) en cada frame de acumulacion. El HUD dibuja la
## barra y el sprite usa el nivel para el efecto visual de "inflarse".
signal carga_cambiada(nivel: float)

## Se libero la carga y el golpe acaba de salir con este multiplicador de dano
## (1.0 = soltada al instante, [member multiplicador_carga_max] = carga llena).
signal carga_liberada(multiplicador: float)

## Se consumio una pocion (OUFW-10). [param pociones_restantes] es el inventario que
## queda y [param hp_recuperada] la vida que de verdad se curo (puede ser menor que
## [member curacion_pocion] si el personaje estaba cerca del tope).
signal pocion_usada(pociones_restantes: int, hp_recuperada: int)

## Se intento usar una pocion y se nego (OUFW-10). No se consume nada.
signal pocion_bloqueada(motivo: MotivoBloqueoPocion)

## El estado alterado cambio (OUFW-8): paso a [constant EstadoAlterado.ENVENENADO] al
## recibir veneno, o volvio a [constant EstadoAlterado.NINGUNO] al acabarse el efecto o
## morir. NO se vuelve a emitir al refrescar un veneno que ya estaba activo. Es la senal
## a la que se engancha el indicador textual del HUD.
signal estado_alterado_cambiado(estado: EstadoAlterado)

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
## Unidades de pocion disponibles. El consumo lo hace [method usar_pocion] (OUFW-10).
@export var cantidad_pociones: int = 3
## Vida que restaura cada pocion (OUFW-10). Cada uso consume 1 unidad del inventario.
@export var curacion_pocion: int = 15
## Perfil de combate que define el moveset disponible.
@export var modset_clase: Modset = Modset.AGIL_DISTANCIA
## Dano base del golpe normal (K): el boton rapido del moveset, sin empuje.
@export var dano_golpe_normal: int = 10
## Dano base del golpe fuerte (L): lento, caro en cooldown y con empuje.
@export var dano_golpe_fuerte: int = 25
## Tamano del volumen del golpe normal: corto y a la altura del torso.
@export var alcance_golpe_normal: Vector2 = Vector2(90.0, 64.0)
## Tamano del golpe fuerte: area extendida (GDD seccion 5 "ataques de rango").
@export var alcance_golpe_fuerte: Vector2 = Vector2(150.0, 72.0)
## Empuje horizontal (knockback) en px/s del golpe fuerte. El golpe normal no empuja.
@export var empuje_golpe_fuerte: float = 300.0
## Pausa entre golpes normales. Corta el spam de tecla mantenida.
@export var cooldown_golpe_normal: float = 0.22
## Pausa entre golpes fuertes: mas lenta por dano y alcance.
@export var cooldown_golpe_fuerte: float = 0.48
## Ventana de frames activos ("active frames") del hitbox del golpe normal.
@export var duracion_hitbox_golpe_normal: float = 0.12
## Ventana activa del golpe fuerte: algo mas generosa que la del normal.
@export var duracion_hitbox_golpe_fuerte: float = 0.18

@export_group("Carga (OUFW-9)")
## Dano base de la carga pesada (`J`) soltada al instante. Se multiplica por el
## nivel de acumulacion y despues por [member multiplicador_dano].
@export var dano_carga: int = 30
## Multiplicador de dano con la carga llena ([member tiempo_carga_max] completo).
@export var multiplicador_carga_max: float = 2.0
## Segundos de mantener `J` para llegar a la carga maxima.
@export var tiempo_carga_max: float = 1.0
## Tamano del volumen de la carga: el golpe mas ancho del moveset.
@export var alcance_carga: Vector2 = Vector2(190.0, 80.0)
## Empuje (knockback) de la carga: sacude mas que el golpe fuerte.
@export var empuje_carga: float = 420.0
## Pausa tras soltar la carga. El golpe es lento a proposito: es un gancho leible.
@export var cooldown_carga: float = 0.80
## Ventana activa del hitbox de carga.
@export var duracion_hitbox_carga: float = 0.25
## Cuanto se "infla" el sprite con la carga llena (0.2 = +20%). Es el efecto visual
## de acumulacion que pide OUFW-9; el HUD puede sumar su barra con [signal carga_cambiada].
@export var factor_escala_carga: float = 0.2
## Veneno (OUFW-8, tecla `U`). Danio por segundo (DoT) del estado Envenenado, ANTES del
## [member multiplicador_dano]. Cada segundo completo descuenta esta cantidad de vida.
@export var dano_veneno_por_segundo: int = 4
## Segundos que dura el veneno desde el ultimo impacto (a 4 por segundo y 5 s son 20 HP).
@export var duracion_veneno: float = 5.0
## Alcance del ataque de veneno: largo y delgado, es la habilidad a distancia del
## moveset [constant Modset.AGIL_DISTANCIA].
@export var alcance_veneno: Vector2 = Vector2(260.0, 56.0)
## Cooldown tras lanzar el veneno: mas largo que el de los golpes para que no se spamee.
@export var cooldown_veneno: float = 1.40
## Segundos que el volumen del ataque de veneno queda activo.
@export var duracion_hitbox_veneno: float = 0.15

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

## Estado actual de skin que determina qué sprite usar (OUFW-21).
@export var skin_estado: SkinState = SkinState.NORMAL

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

## Señal que se emite cuando el estado de skin cambia (OUFW-21).
signal skin_cambiada(estado: SkinState)

## Segundos que le quedan al derrape en curso.
var tiempo_derrape: float = 0.0

## true mientras se mantiene pulsada la carga pesada (OUFW-9). La acumula
## [method _physics_process] y la consume [method soltar_carga].
var cargando: bool = false

## Segundos acumulados de carga en curso, con techo en [member tiempo_carga_max].
var tiempo_carga: float = 0.0

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

# --- OUFW-15: dificultad ---

## Atributos base del personaje, capturados en [_ready] tras
## [method _configurar_atributos_por_defecto]. Sobre ellos se calculan los
## multiplicadores de dificultad, de modo que aplicarlos varias veces no los acumula.
var _hp_max_base: int = 0
var _multiplicador_dano_base: float = 1.0

# --- OUFW-8: estado alterado ---

## Intervalo entre cobros del veneno: 1 s, porque el DoT es "danio por segundo".
const VENENO_INTERVALO_TICK := 1.0
## Tolerancia para que 60 pasos de 1/60 s (que suman 0.99999...) cuenten como 1 s.
const VENENO_EPSILON := 0.0001

## Estado alterado actual. Lectura publica para HUD y pruebas.
var estado_alterado: EstadoAlterado = EstadoAlterado.NINGUNO

var _veneno_dps: int = 0
var _veneno_ticks_restantes: int = 0
var _veneno_acumulador: float = 0.0

# --- OUFW-3: estado de combate ---

## Hurtbox de este personaje, creada en [_ready] (no vive en las escenas).
var _hurtbox: Hurtbox = null
## Segundos restantes del cooldown entre ataques. 0 = listo para golpear.
var _cooldown_ataque: float = 0.0
## Contador para nombrar hitboxes unicos (`Hitbox_0`, `Hitbox_1`, ...).
var _contador_hitboxes: int = 0


## Aplica los valores por defecto del personaje y lo deja vivo y a tope de vida.
##
## El orden importa: primero [_configurar_atributos_por_defecto] (que las
## subclases sobrescriben para fijar su identidad y su [member hp_max]), y solo
## despues se deriva [member current_hp] de ese [member hp_max].
func _ready() -> void:
	collision_layer = CAPA_PERSONAJE
	collision_mask = CAPA_GROUND | CAPA_PERSONAJE
	# Buscar sprite ANTES de configurar atributos, para que establecer_skin_normal()
	# en _configurar_atributos_por_defecto() funcione correctamente.
	if nodo_sprite == null:
		nodo_sprite = _buscar_sprite()
	# Guardar la escala base del sprite (definida en la escena) para restaurarla
	# correctamente tras efectos visuales (carga, etc.).
	if nodo_sprite != null:
		_escala_base_sprite = nodo_sprite.scale
	_configurar_atributos_por_defecto()
	_hp_max_base = hp_max
	_multiplicador_dano_base = multiplicador_dano
	current_hp = hp_max
	esta_muerto = false
	_estaba_en_suelo = en_suelo()
	_aplicar_flip()
	_crear_hurtbox()
	# _aplicar_sprite_por_skin_estado ya se llamó desde _configurar_atributos_por_defecto()
	# vía establecer_skin_normal() en las subclases, pero nos aseguramos aquí también.
	_aplicar_sprite_por_skin_estado(SkinState.NORMAL)


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
## [param empuje] y [param direccion_empuje] entregan el knockback de los golpes
## fuertes (OUFW-3): fijan [member velocity] en X para que el impacto "empuje" de
## verdad al rival, no solo reste vida.
## El parametro [param tipo] queda sin uso aqui: los modificadores por tipo de
## ataque (rotura de guardia) llegan en OUFW-9. El veneno (OUFW-8) no necesita
## modificar este metodo: su DoT entra por aqui como un dano mas.
@warning_ignore("unused_parameter")
func recibir_dano(cantidad: int, tipo: TipoAtaque = TipoAtaque.GOLPE_NORMAL,
		empuje: float = 0.0, direccion_empuje: int = 0) -> void:
	if esta_muerto or cantidad <= 0:
		return

	current_hp = maxi(0, current_hp - cantidad)
	health_changed.emit(current_hp, hp_max)

	if empuje > 0.0 and direccion_empuje != 0:
		velocity.x = float(direccion_empuje) * empuje

	if current_hp <= 0:
		esta_muerto = true
		cancelar_carga()
		_terminar_veneno()
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


# --- OUFW-15: dificultad por capitulo ---

## Escala vida y dano respecto a los atributos BASE de la princesa (OUFW-15).
##
## Pensado para el bot enemigo al empezar un combate: lo deja a vida completa con el
## nuevo [member hp_max], y notifica [signal health_changed] para que el HUD redibuje
## la barra. Es idempotente: [param mult_hp] y [param mult_dano] siempre se multiplican
## por los valores base, nunca por los ya escalados.
##
## IMPORTANTE: llamarlo DESPUES de [method _ready]. [method _ready] reescribe
## [member hp_max] con los valores de la subclase y pisaria cualquier ajuste anterior.
## No hace nada en un personaje muerto. Normalmente se invoca via [DificultadCapitulo].
func aplicar_multiplicadores_dificultad(mult_hp: float, mult_dano: float) -> void:
	if esta_muerto:
		return
	# Si se llama antes de _ready, se toman como base los valores actuales.
	if _hp_max_base <= 0:
		_hp_max_base = hp_max
		_multiplicador_dano_base = multiplicador_dano

	hp_max = maxi(1, roundi(_hp_max_base * maxf(mult_hp, 0.0)))
	multiplicador_dano = _multiplicador_dano_base * maxf(mult_dano, 0.0)
	current_hp = hp_max
	health_changed.emit(current_hp, hp_max)


# --- OUFW-10: pociones ---

## Por que no se podria usar una pocion ahora mismo, o [constant MotivoBloqueoPocion.NINGUNO]
## si se puede. Orden de prioridad: muerto, sin pociones, vida completa.
func motivo_bloqueo_pocion() -> MotivoBloqueoPocion:
	if esta_muerto:
		return MotivoBloqueoPocion.MUERTO
	if cantidad_pociones <= 0:
		return MotivoBloqueoPocion.SIN_POCIONES
	if current_hp >= hp_max:
		return MotivoBloqueoPocion.VIDA_COMPLETA
	return MotivoBloqueoPocion.NINGUNO


## [return] Si [method usar_pocion] tendria efecto. Lo consulta el HUD para atenuar el icono.
func puede_usar_pocion() -> bool:
	return motivo_bloqueo_pocion() == MotivoBloqueoPocion.NINGUNO


## Consume 1 pocion y restaura [member curacion_pocion] HP (OUFW-10, tecla `E`).
##
## Se BLOQUEA, sin gastar nada, si [member cantidad_pociones] es 0 o si la vida ya esta
## al 100%: nadie pierde una pocion curandose sin necesidad. La curacion respeta el
## techo de [member hp_max] (la ultima pocion puede curar menos de 15) pero igualmente
## gasta la unidad. Delega la vida en [method aplicar_curacion], que emite
## [signal health_changed].
## [return] Si la pocion se consumio.
func usar_pocion() -> bool:
	var motivo := motivo_bloqueo_pocion()
	if motivo != MotivoBloqueoPocion.NINGUNO:
		pocion_bloqueada.emit(motivo)
		return false

	var recuperada := aplicar_curacion(curacion_pocion)
	cantidad_pociones -= 1
	pocion_usada.emit(cantidad_pociones, recuperada)
	return true


# --- OUFW-8: veneno ---

## Si esta princesa tiene la habilidad de veneno (`U`). Es del moveset
## [constant Modset.AGIL_DISTANCIA]; si el GDD la reparte distinto, este es el UNICO
## sitio que hay que cambiar.
func tiene_habilidad_veneno() -> bool:
	return modset_clase == Modset.AGIL_DISTANCIA


## Ataque de veneno (`U`): lanza un volumen largo que NO hace danio directo pero, si
## toca a una [Hurtbox] rival, la deja Envenenada ([method aplicar_veneno]) con
## [member dano_veneno_por_segundo] x [member multiplicador_dano] durante
## [member duracion_veneno] s. Respeta el cooldown compartido de los ataques. Si la
## princesa no tiene la habilidad ([method tiene_habilidad_veneno]) no hace nada.
func ataque_veneno() -> void:
	if not tiene_habilidad_veneno():
		return
	_ejecutar_ataque(
		0,
		TipoAtaque.VENENO,
		alcance_veneno,
		0.0,
		cooldown_veneno,
		duracion_hitbox_veneno,
		maxi(1, roundi(dano_veneno_por_segundo * multiplicador_dano)),
		duracion_veneno
	)


## Deja a esta princesa Envenenada: [param dps] de vida por segundo durante
## [param duracion] segundos. Lo invoca la [Hurtbox] cuando recibe un golpe de veneno.
##
## Reglas si ya estaba envenenada: NO se apila. Se refresca la duracion (nunca se acorta
## una mas larga) y se queda el mayor de los dos [param dps]. El reloj del siguiente cobro
## no se reinicia, asi que reaplicar el veneno cada segundo no lo "congela".
## [return] Si se aplico (false si esta muerta o los datos no son validos).
func aplicar_veneno(dps: int, duracion: float) -> bool:
	if esta_muerto or dps <= 0 or duracion <= 0.0:
		return false

	var ticks := maxi(1, roundi(duracion / VENENO_INTERVALO_TICK))
	if estado_alterado == EstadoAlterado.ENVENENADO:
		_veneno_dps = maxi(_veneno_dps, dps)
		_veneno_ticks_restantes = maxi(_veneno_ticks_restantes, ticks)
	else:
		_veneno_dps = dps
		_veneno_ticks_restantes = ticks
		_veneno_acumulador = 0.0
		_fijar_estado_alterado(EstadoAlterado.ENVENENADO)
	return true


func esta_envenenado() -> bool:
	return estado_alterado == EstadoAlterado.ENVENENADO


## Texto del estado para el indicador del HUD: "Normal" o "Envenenado" (OUFW-8).
func texto_estado() -> String:
	match estado_alterado:
		EstadoAlterado.ENVENENADO:
			return "Envenenado"
		_:
			return "Normal"


## Segundos de veneno que le quedan (0 si no esta envenenada).
func segundos_veneno_restantes() -> float:
	if not esta_envenenado():
		return 0.0
	return maxf(0.0, _veneno_ticks_restantes * VENENO_INTERVALO_TICK - _veneno_acumulador)


## Dano por segundo del veneno activo (0 si no esta envenenada).
func dps_veneno_actual() -> int:
	return _veneno_dps if esta_envenenado() else 0


## Cobra los segundos completos transcurridos. Si [param delta] es grande (un tirón de
## frames) cobra todos los ticks que correspondan, sin adelantarse ni saltarse ninguno.
func _actualizar_veneno(delta: float) -> void:
	if not esta_envenenado() or esta_muerto:
		return

	_veneno_acumulador += delta
	while _veneno_ticks_restantes > 0 \
			and _veneno_acumulador >= VENENO_INTERVALO_TICK - VENENO_EPSILON:
		_veneno_acumulador = maxf(0.0, _veneno_acumulador - VENENO_INTERVALO_TICK)
		_veneno_ticks_restantes -= 1
		recibir_dano(_veneno_dps, TipoAtaque.VENENO)
		if esta_muerto:
			return  # recibir_dano ya limpio el estado al morir

	if _veneno_ticks_restantes <= 0:
		_terminar_veneno()


func _terminar_veneno() -> void:
	_veneno_dps = 0
	_veneno_ticks_restantes = 0
	_veneno_acumulador = 0.0
	_fijar_estado_alterado(EstadoAlterado.NINGUNO)


func _fijar_estado_alterado(nuevo: EstadoAlterado) -> void:
	if nuevo == estado_alterado:
		return
	estado_alterado = nuevo
	estado_alterado_cambiado.emit(nuevo)


# --- OUFW-3: hitbox/hurtbox (combate) ---

## Descuenta el cooldown entre ataques. El combate no bloquea la locomotion: la
## princesa puede moverse y saltar mientras el golpe esta en cooldown.
func _physics_process(delta: float) -> void:
	if _cooldown_ataque > 0.0:
		_cooldown_ataque = maxf(0.0, _cooldown_ataque - delta)
	if cargando:
		var nivel_previo := carga_nivel()
		tiempo_carga = minf(tiempo_carga + delta, tiempo_carga_max)
		if not is_equal_approx(nivel_previo, carga_nivel()):
			_actualizar_escalado_carga()
			carga_cambiada.emit(carga_nivel())
	_actualizar_veneno(delta)


## Golpe normal (`K`): rapido, corto y sin empuje. Es el pilar del moveset base y
## el que los jugadores van a probar primero en la arena.
func ataque_normal() -> void:
	_ejecutar_ataque(
		dano_golpe_normal,
		TipoAtaque.GOLPE_NORMAL,
		alcance_golpe_normal,
		0.0,
		cooldown_golpe_normal,
		duracion_hitbox_golpe_normal
	)


## Golpe fuerte (`L`): lento, de area extendida, con dano alto y empuje
## (GDD seccion 5: "ataques de rango" y "gestión de riesgo vs. recompensa").
func ataque_fuerte() -> void:
	_ejecutar_ataque(
		dano_golpe_fuerte,
		TipoAtaque.GOLPE_FUERTE,
		alcance_golpe_fuerte,
		empuje_golpe_fuerte,
		cooldown_golpe_fuerte,
		duracion_hitbox_golpe_fuerte
	)


# --- OUFW-9: carga rompe-guardia (tecla J) ---

## Empieza a acumular la carga pesada (`J` mantenida). No se puede cargar dos veces
## a la vez ni con el golpe anterior todavia en cooldown; tampoco un personaje
## muerto. La acumulacion avanza sola en [method _physics_process].
func iniciar_carga() -> void:
	if esta_muerto or cargando or _cooldown_ataque > 0.0 or not is_inside_tree():
		return
	cargando = true
	tiempo_carga = 0.0
	carga_iniciada.emit()


## Suelta la carga y despacha el golpe: el dano escala con el nivel acumulado, de
## [member dano_carga] (soltada al instante) hasta dano_carga x
## [member multiplicador_carga_max] (carga llena). El golpe lleva la marca
## [member Hitbox.rompe_guardia], la que la Hurtbox rival convierte en
## [signal Hurtbox.guardia_rota].
func soltar_carga() -> void:
	if not cargando:
		return

	var multiplicador := lerpf(1.0, multiplicador_carga_max, carga_nivel())
	cargando = false
	tiempo_carga = 0.0
	_restaurar_escala_sprite()
	carga_liberada.emit(multiplicador)

	_ejecutar_ataque(
		roundi(dano_carga * multiplicador),
		TipoAtaque.SUPER_PESADO_CARGA,
		alcance_carga,
		empuje_carga,
		cooldown_carga,
		duracion_hitbox_carga,
		0,
		0.0,
		true
	)


## Cancela la carga en curso SIN golpear: se usa cuando la accion se interrumpe
## (controles congelados, muerte del personaje, reinicio del combate).
func cancelar_carga() -> void:
	cargando = false
	tiempo_carga = 0.0
	_restaurar_escala_sprite()


## [return] Progreso de la carga en rango 0.0..1.0. 1.0 = [member tiempo_carga_max].
func carga_nivel() -> float:
	if tiempo_carga_max <= 0.0:
		return 1.0
	return clampf(tiempo_carga / tiempo_carga_max, 0.0, 1.0)


## [return] Si hay una carga acumulandose en este momento.
func esta_cargando() -> bool:
	return cargando


## Efecto visual de acumulacion (OUFW-9): el sprite se "infla" con la carga, hasta
## [member factor_escala_carga] extra al nivel maximo. OJO: usa [member Node2D.scale]
## del sprite, asi que solo conviene con sprites que se volteen via `flip_h` (la
## convencion de las escenas); un sprite que dependa del signo de `scale.x` para
## mirar perderia el flip mientras dure la carga.
func _actualizar_escalado_carga() -> void:
	if nodo_sprite == null:
		return
	var escala_mult := 1.0 + factor_escala_carga * carga_nivel()
	nodo_sprite.scale = _escala_base_sprite * escala_mult


func _restaurar_escala_sprite() -> void:
	if nodo_sprite != null:
		nodo_sprite.scale = _escala_base_sprite


## Crea un [Hitbox] frontal como hijo (viaja con el personaje) y lo posiciona a la
## distancia de alcance EN FRENTE de la mirada. El cooldown corta el spam de tecla
## mantenida: pulsar `K` en bucle solo suelta un golpe cada
## [member cooldown_golpe_normal] segundos.
##
## El dano pasa por [member multiplicador_dano] (perfil "glass cannon" del GDD
## seccion 8); el resto del volumen y el empuje se inyectan tal cual.
func _ejecutar_ataque(dano: int, tipo: TipoAtaque, tamano: Vector2, empuje: float,
		cooldown: float, duracion: float, veneno_dps: int = 0,
		veneno_duracion: float = 0.0, rompe_guardia: bool = false) -> void:
	if esta_muerto or _cooldown_ataque > 0.0 or not is_inside_tree():
		return

	_cooldown_ataque = cooldown

	var hitbox := Hitbox.new()
	hitbox.name = "Hitbox_%d" % _contador_hitboxes
	_contador_hitboxes += 1
	add_child(hitbox)
	# Un golpe de danio 0 es valido (el veneno solo aplica estado): no se sube a 1.
	var dano_final := 0 if dano <= 0 else maxi(1, roundi(dano * multiplicador_dano))
	hitbox.iniciar(
		dano_final,
		tipo,
		tamano,
		empuje,
		_signo_mirada(),
		self,
		duracion,
		rompe_guardia
	)
	# El golpe nace a alcance corto del cuerpo (media del tamano + 8 px) para no
	# "nacer adentro" del rival: la superposicion se produce cuando el golpe entra
	# en rango, y la hurtbox lo detecta con su area_entered ese mismo frame.
	hitbox.position = Vector2(float(_signo_mirada()) * (tamano.x * 0.5 + 8.0), ALTURA_GOLPE)
	hitbox.veneno_dps = veneno_dps
	hitbox.veneno_duracion = veneno_duracion

	ataque_ejecutado.emit(tipo)


## Crea la hurtbox de este personaje en runtime. Al vivir en la clase base, toda
## princesa (jugable, bot de OUFW-11, futuras) recibe la suya sin tocar escenas.
func _crear_hurtbox() -> void:
	if _hurtbox != null:
		return
	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.personaje = self
	add_child(hurtbox)
	_hurtbox = hurtbox


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
