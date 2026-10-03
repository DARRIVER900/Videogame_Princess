class_name PrincesaDulcecito
extends Personaje
## Princesa Dulcecito, heredera menor del Reino de Candyr (la potencia comercial).
## Moveset [constant Modset.AGIL_DISTANCIA].
##
## Solo encapsula identidad y atributos base; el moveset llega en OUFW-3, la IA
## rival en OUFW-11 y el resto de sistemas segun su issue.
##
## Referencia: GDD seccion 8 "Fichas de Personajes".

## Fija identidad y atributos base tomados del GDD. La invoca [method Personaje._ready].
func _configurar_atributos_por_defecto() -> void:
	nombre = "Princesa Dulcecito"
	id_skin_activa = "SKIN_CANDYR_DEFAULT"
	modset_clase = Modset.AGIL_DISTANCIA

	hp_max = 100
	multiplicador_dano = 1.0
	cantidad_pociones = 3
