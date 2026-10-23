class_name DificultadCapitulo
extends RefCounted
## Curva de dificultad del bot enemigo a lo largo de los 3 capitulos (OUFW-15).
##
## TODOS los numeros de balance viven en [constant TABLA] y en ningun otro lado: para
## afinar la dificultad basta con editar esa tabla. Cada fila son MULTIPLICADORES sobre
## los atributos base del bot ([member Personaje.hp_max] y
## [member Personaje.multiplicador_dano]), no valores absolutos, asi que funcionan igual
## para [PrincesaDulcecito], [PrincesaChocolatito] o cualquier princesa futura.
##
## Uso, desde el nivel y DESPUES de que el bot haya hecho su [method Node._ready]:
## [codeblock]
## DificultadCapitulo.aplicar(rival, 3)
## [/codeblock]
##
## La IA del bot (OUFW-11) es otro ticket: aqui solo se ajustan vida y dano. Los datos
## de [method descripcion] estan pensados para que esa IA y el HUD los puedan consultar.
##
## Referencia: OUFW-15 "Ajustar Dificultad Gradual Cap 1 a 3".

const CAPITULO_MIN := 1
const CAPITULO_MAX := 3

## Multiplicadores por capitulo. La curva es estrictamente creciente en ambos ejes:
##   Cap 1: bot blando (pega al 80%): el capitulo sirve de tutorial de combate.
##   Cap 2: bot equilibrado, algo mas duro de matar y que ya pega mas que la jugadora.
##   Cap 3: bot agresivo: +70% de vida y +50% de dano frente al base.
## Con los golpes base (normal 10 / fuerte 25) y 100 HP de la jugadora, el bot necesita
## 13 / 10 / 7 golpes normales para derrotarla en los capitulos 1 / 2 / 3.
const TABLA := {
	1: {"hp": 1.0, "dano": 0.8},
	2: {"hp": 1.3, "dano": 1.1},
	3: {"hp": 1.7, "dano": 1.5},
}


## Capitulo valido mas cercano: 0 o menos cae en el 1, y mas de 3 cae en el 3 (asi un
## capitulo de DLC o un valor mal puesto no revienta la partida).
static func normalizar_capitulo(capitulo: int) -> int:
	return clampi(capitulo, CAPITULO_MIN, CAPITULO_MAX)


## Multiplicador de vida maxima del bot en ese capitulo.
static func multiplicador_hp(capitulo: int) -> float:
	return TABLA[normalizar_capitulo(capitulo)]["hp"]


## Multiplicador de dano del bot en ese capitulo.
static func multiplicador_dano(capitulo: int) -> float:
	return TABLA[normalizar_capitulo(capitulo)]["dano"]


## Aplica la dificultad del capitulo a [param bot]. Es idempotente: se calcula siempre
## sobre los atributos base del bot, asi que repetir la llamada, o pasar de un capitulo
## a otro, no acumula multiplicadores. Ver [method Personaje.aplicar_multiplicadores_dificultad].
static func aplicar(bot: Personaje, capitulo: int) -> void:
	if bot == null:
		return
	bot.aplicar_multiplicadores_dificultad(
		multiplicador_hp(capitulo), multiplicador_dano(capitulo))


## Texto corto del capitulo para depuracion y HUD, por ejemplo "Cap 3: vida x1.70, dano x1.50".
static func descripcion(capitulo: int) -> String:
	var c := normalizar_capitulo(capitulo)
	return "Cap %d: vida x%.2f, dano x%.2f" % [c, multiplicador_hp(c), multiplicador_dano(c)]
