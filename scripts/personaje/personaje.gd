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

## Tipos de ataque del moveset base. El mapeo de teclas se resuelve en OUFW-2
## (navegacion) y OUFW-3 (hitboxes); aqui solo se declara el tipo para que
## [method recibir_dano] pueda differentiate.
enum TipoAtaque { GOLPE_NORMAL, GOLPE_FUERTE, VENENO, SUPER_PESADO_CARGA }

## Equivalente a `OnHealthChanged` en OUFW-1. Lo consume el HUD (OUFW-5).
signal health_changed(current_hp: int, hp_max: int)

## Equivalente a `OnDeath` en OUFW-1. Se emite una sola vez por combate.
signal died

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

## Vida actual. La inicializa [_ready] a partir de [member hp_max] y solo se
## modifica mediante [method recibir_dano] o [method aplicar_curacion].
var current_hp: int = 0

## Se enciende en cuanto la vida llega a 0. Impide que un segundo golpe en el
## mismo frame dispare [signal died] una segunda vez.
var esta_muerto: bool = false

## Fraccion de vida actual en rango 0.0..1.0. La consume el HUD para calcular el
## `fill_amount` de la barra (OUFW-5).
var ratio_hp: float:
	get:
		if hp_max <= 0:
			return 0.0
		return float(current_hp) / float(hp_max)


## Aplica los valores por defecto del personaje y lo deja vivo y a tope de vida.
##
## El orden importa: primero [_configurar_atributos_por_defecto] (que las
## subclases sobrescriben para fijar su identidad y su [member hp_max]), y solo
## despues se deriva [member current_hp] de ese [member hp_max].
func _ready() -> void:
	_configurar_atributos_por_defecto()
	current_hp = hp_max
	esta_muerto = false


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
