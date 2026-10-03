class_name PrincesaChocolatito
extends Personaje
## Princesa Chocolatito, soberana menor del Reino de Chocolate (la potencia minera).
## Moveset [constant Modset.PESADO_PESA].
##
## Solo encapsula identidad y atributos base; el moveset llega en OUFW-3, la IA
## rival en OUFW-11 y el resto de sistemas segun su issue.
##
## Referencia: GDD seccion 8 "Fichas de Personajes".

## Fija identidad y atributos base tomados del GDD. La invoca [method Personaje._ready].
func _configurar_atributos_por_defecto() -> void:
	nombre = "Princesa Chocolatito"
	id_skin_activa = "SKIN_CHOCOLATE_DEFAULT"
	modset_clase = Modset.PESADO_PESA

	hp_max = 100
	multiplicador_dano = 1.0
	cantidad_pociones = 3
