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

## Capa 2D en la que vive el hitbox. Valor en bruto a proposito: la matriz de capas
## con NOMBRES la configura OUFW-6 ("Physics Layer Matrix configurados
## correctamente"); aqui solo importa que hurtbox y hitbox se encuentren.
const CAPA_HITBOX := 4

## Dano que inflige. Lo fija [method iniciar] desde los exports de [Personaje].
var dano: int = 0
## Tipo de ataque que genero este golpe (el moveset lo amplia OUFW-8).
var tipo_ataque: Personaje.TipoAtaque = Personaje.TipoAtaque.GOLPE_NORMAL
## Empuje horizontal (knockback) en px/s que aplica al impactar. 0 = sin empuje.
var empuje: float = 0.0
## Direccion del empuje: +1 hacia la derecha, -1 hacia la izquierda. Es la mirada
## del dueno en el momento del golpe, no la direccion en que "vuela" el rival.
var direccion_empuje: int = 1
## Princesa que lanzo el golpe. Su propia hurtbox ignora a este hitbox.
var dueno: Personaje = null
## Una vez la hurtbox rival consume el golpe, ya no puede herir a nadie mas.
var consumida: bool = false

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
func iniciar(p_dano: int, p_tipo: Personaje.TipoAtaque, tamano: Vector2,
		p_empuje: float, p_direccion: int, p_dueno: Personaje, duracion: float) -> void:
	dano = p_dano
	tipo_ataque = p_tipo
	empuje = p_empuje
	direccion_empuje = p_direccion
	dueno = p_dueno
	_tiempo_activo = duracion
	collision_layer = CAPA_HITBOX
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