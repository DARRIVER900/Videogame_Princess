class_name Hitbox
extends Area2D
## Zona que inflige dano en el sistema de combate (OUFW-3): arquitectura clasica
## de Hitbox (area que dania) vs Hurtbox (area que recibe el dano), sobre triggers 2D.
##
## Nace por ataque de [Personaje] (K: golpe normal, L: golpe fuerte), viaja con su
## dueno (es hijo suyo) y vive solo la ventana de frames activos que le fija
## [method Personaje._ejecutar_ataque]. Nada mas impactar en una [Hurtbox] rival se
## marca [member consumida] y se destruye en el siguiente paso de fisica: es la
## barrera contra el *multi-hitting* (criterio 3 de OUFW-3).
##
## Detecta la hurtbox rival por dos rutas redundantes que caen en
## [method Hurtbox.recibir_golpe]: la senal `area_entered` de la hurtbox y este
## chequeo explicito con [method get_overlapping_areas] cada frame activo. La doble
## deteccion es inofensiva porque el consumo se resuelve antes que nada.

## Capas: se leen de [Personaje] (CAPA_HITBOX / CAPA_HURTBOX), fuente unica de verdad.

## Dano que inflige. Lo fija [method iniciar] desde los exports de [Personaje].
var dano: int = 0
## Tipo de ataque que genero este golpe.
var tipo_ataque: Personaje.TipoAtaque = Personaje.TipoAtaque.GOLPE_NORMAL
## Empuje horizontal (knockback) en px/s que aplica al impactar. 0 = sin empuje.
var empuje: float = 0.0
## Direccion del empuje: +1 hacia la derecha, -1 hacia la izquierda. Es la mirada
## del dueno en el momento del golpe, no la direccion en que "vuela" el rival.
var direccion_empuje: int = 1
## Veneno que aplica al impactar (OUFW-8). 0 = el golpe no envenena. Solo se aplica si
## [member tipo_ataque] es VENENO; lo rellena [method Personaje._ejecutar_ataque].
var veneno_dps: int = 0
var veneno_duracion: float = 0.0
## Princesa que lanzo el golpe. Su propia hurtbox ignora a este hitbox.
var dueno: Personaje = null
## Una vez la hurtbox rival consume el golpe, ya no puede herir a nadie mas.
var consumida: bool = false
## true si este golpe rompe la defensa/bloqueo enemigo (OUFW-9): la carga pesada
## ignora cualquier reduccion de dano defensiva. La [Hurtbox] lo traduce en su
## senal [signal Hurtbox.guardia_rota], que es el enganche del futuro sistema de guardia.
var rompe_guardia: bool = false

## Segundos de ventana activa restantes. Al agotarse el golpe se destruye solo.
var _tiempo_activo: float = 0.0


func _physics_process(delta: float) -> void:
	if consumida:
		queue_free()
		return
	_tiempo_activo -= delta
	if _tiempo_activo <= 0.0:
		queue_free()
		return
	_verificar_impactos()


## Configura el golpe y crea su volumen de alcance. Llamar tras anadir el nodo al
## arbol del dueno (necesita estar dentro para que el shape registre en fisica).
## [param p_rompe_guardia] marca el golpe como rompe-guardia (OUFW-9).
func iniciar(p_dano: int, p_tipo: Personaje.TipoAtaque, tamano: Vector2,
		p_empuje: float, p_direccion: int, p_dueno: Personaje, duracion: float,
		p_rompe_guardia: bool = false) -> void:
	dano = p_dano
	tipo_ataque = p_tipo
	empuje = p_empuje
	direccion_empuje = p_direccion
	dueno = p_dueno
	_tiempo_activo = duracion
## Tipo de ataque que genero este golpe (el moveset lo amplia OUFW-8).
var tipo_ataque: int = 0
## true si este golpe rompe la defensa/bloqueo enemigo (OUFW-9): la carga pesada
## es el ejemplo canonico.
var rompe_guardia: bool = false
## DPS del veneno que aplica este golpe (OUFW-8). 0 = sin veneno.
var veneno_dps: int = 0
## Duracion en segundos del veneno aplicado (OUFW-8).
var veneno_duracion: float = 0.0
	collision_mask = Personaje.CAPA_HURTBOX

	var colision := CollisionShape2D.new()
	colision.name = "Colision"
	var rect := RectangleShape2D.new()
	rect.size = tamano
	colision.shape = rect
	add_child(colision)


## Chequeo redundante de contacto: si el golpe nace ya superpuesto a la hurtbox
## rival (p.ej. atacando a boca de jarro), el `area_entered` de la hurtbox puede
## tardar un frame en detectarlo. Este barrido sobre [method get_overlapping_areas]
## garantiza que el dano caiga en el MISMO frame en que el golpe toca a su objetivo
## (criterio 2 de OUFW-3).
func _verificar_impactos() -> void:
	for area: Area2D in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox != null:
			hurtbox.recibir_golpe(self)