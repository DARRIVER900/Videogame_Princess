class_name Hurtbox
extends Area2D
## Zona receptora de dano del sistema de combate (OUFW-3): arquitectura clasica
## de Hitbox (area que dania) vs Hurtbox (area que recibe el dano), sobre triggers 2D.
##
## Vive como hija de [Personaje] creada en runtime ([method Personaje._crear_hurtbox]),
## asi que no hace falta tocarla en las escenas: toda princesa (jugable, bot de
## OUFW-11, futuras) recibe la suya sin cableado manual.
##
## Encoge su capsula cuando el personaje se agacha (`S`) o derrapa (`S + A/D`),
## escuchando [signal Personaje.locomocion_cambiada]; esa redimension dinamica es el
## criterio 1 de OUFW-3. El centro baja con la pose para que los PIES queden anclados
## al suelo: encoger no debe hacer flotar al personaje.
##
## Punto unico de entrada del dano es [method recibir_golpe], al que llegan las dos
## rutas de deteccion (su propio `area_entered` y el barrido del [Hitbox]). Ignora
## los golpes propios y los ya consumidos: ahi se corta el *multi-hitting*.

## Capa 2D en la que vive la hurtbox. Valor en bruto a proposito (ver [Hitbox]).
const CAPA_HURTBOX := 2

## Altura de pie de la capsula en px. Coincide con la colision del cuerpo.
const ALTURA_PIE := 64.0
## Aspas que envuelven la capsula: algo mas anchas que el cuerpo para que el combate
## se sienta justo (pegar "por el borde" del sprite cuenta como golpe).
const RADIO := 12.0

## Se emite cuando esta hurtbox recibe un golpe valido. HUD, particulas o camara la
## escuchan para la retroalimentacion de impacto.
signal golpe_recibido(hitbox: Hitbox)

## Princesa duena de esta hurtbox. Se resuelve sola en [_ready]; en runtime lo fija
## [method Personaje._crear_hurtbox] antes de anadir el nodo.
@export var personaje: Personaje

var _forma: CapsuleShape2D
var _colision: CollisionShape2D


func _ready() -> void:
	if personaje == null:
		personaje = _buscar_personaje_ancestro()

	collision_layer = CAPA_HURTBOX
	collision_mask = Personaje.CAPA_HITBOX

	_forma = CapsuleShape2D.new()
	_forma.radius = RADIO
	_forma.height = ALTURA_PIE
	_colision = CollisionShape2D.new()
	_colision.name = "Colision"
	_colision.shape = _forma
	add_child(_colision)

	area_entered.connect(_on_area_entered)
	if personaje != null:
		personaje.locomocion_cambiada.connect(_on_locomocion_cambiada)
		actualizar_altura(personaje.factor_altura_cuerpo())
	else:
		push_warning("Hurtbox sin [Personaje] dueno: no podra ignorar los golpes propios")


func _on_area_entered(area: Area2D) -> void:
	var hitbox := area as Hitbox
	if hitbox != null:
		recibir_golpe(hitbox)


func _on_locomocion_cambiada(_estado: Personaje.Locomocion) -> void:
	if personaje != null:
		actualizar_altura(personaje.factor_altura_cuerpo())


## Redimensiona la capsula segun la pose del cuerpo ([method Personaje.factor_altura_cuerpo]):
## 1.0 de pie, 0.5 agachado, 0.6 derrape. El centro baja la mitad de lo que encoge
## para conservar los pies en el suelo.
func actualizar_altura(factor: float) -> void:
	if _forma == null or _colision == null:
		return
	var nueva := ALTURA_PIE * clampf(factor, 0.1, 1.0)
	_forma.height = nueva
	_colision.position.y = (ALTURA_PIE - nueva) * 0.5


## Altura actual de la capsula en px. Lectura publica para pruebas y HUD.
func altura_actual() -> float:
	return _forma.height if _forma != null else 0.0


## Posicion local de la capsula. Lectura publica para pruebas (verificar el anclaje
## de los pies al encoger).
func posicion_forma() -> Vector2:
	return _colision.position if _colision != null else Vector2.ZERO


## Punto unico de entrada del dano. Solo acepta golpes ajenos no consumidos:
## aqui se corta el *multi-hitting* indebido (criterio 3 de OUFW-3).
func recibir_golpe(hitbox: Hitbox) -> void:
	if hitbox == null or hitbox.consumida:
		return
	if personaje == null or hitbox.dueno == null or hitbox.dueno == personaje:
		return
	hitbox.consumida = true
	personaje.recibir_dano(
		hitbox.dano,
		hitbox.tipo_ataque,
		hitbox.empuje,
		hitbox.direccion_empuje
	)
	golpe_recibido.emit(hitbox)


func _buscar_personaje_ancestro() -> Personaje:
	var nodo := get_parent()
	while nodo != null:
		if nodo is Personaje:
			return nodo
		nodo = nodo.get_parent()
	return null