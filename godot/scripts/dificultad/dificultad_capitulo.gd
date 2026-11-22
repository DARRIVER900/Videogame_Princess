class_name DificultadCapitulo
extends RefCounted
## Curva de dificultad del bot enemigo a lo largo de los 3 capitulos (OUFW-15).
##
## TODOS los numeros de balance viven en [constant TABLA] y en ningun otro lado: para
## afinar la dificultad basta con editar esa tabla. Las columnas [code]hp[/code] y
## [code]dano[/code] son MULTIPLICADORES sobre los atributos base del bot
## ([member Personaje.hp_max] y [member Personaje.multiplicador_dano]); las columnas
## [code]reaccion[/code], [code]distancia[/code] y [code]pocion[/code] afinan la FSM
## (OUFW-11) sin tocar su codigo.
##
## Uso, desde el nivel y DESPUES de que el bot haya hecho su [method Node._ready]:
## [codeblock]
## DificultadCapitulo.aplicar(rival, 3)
## DificultadCapitulo.aplicar_bot(rival.get_node("Bot"), 3)
## [/codeblock]
##
## Referencia: OUFW-15 "Ajustar Dificultad Gradual Cap 1 a 3" y OUFW-19 "Balanceo de
## Combate y Tiempos del Bot".

const CAPITULO_MIN := 1
const CAPITULO_MAX := 3

## Tabla de balance. La curva es estrictamente creciente en todos los ejes:
##   Cap 1: tutorial. Bot lento (reacciona cada 0.55 s) y blando (pega al 80%).
##   Cap 2: duelo parejo. Mas vida, pega algo mas y decide cada 0.38 s.
##   Cap 3: jefe. +50% de vida y +69% de dano, reacciona cada 0.20 s y bebe antes.
## [code]reaccion[/code] es el [member ControladorBot.intervalo_decision] en segundos;
## [code]distancia[/code] su [member ControladorBot.distancia_ataque] en px; y
## [code]pocion[/code] el [member ControladorBot.umbral_vida_pocion].
## Con los golpes base (normal 10 / fuerte 25) y 100 HP de la jugadora, el bot necesita
## 13 / 10 / 8 golpes normales para derrotarla en los capitulos 1 / 2 / 3. El Cap 3 no
## se gana spameando el combo basico: exige usar carga, veneno y pociones (OUFW-19).
const TABLA := {
	1: {"hp": 1.0, "dano": 0.8, "reaccion": 0.55, "distancia": 105.0, "pocion": 0.30},
	2: {"hp": 1.25, "dano": 1.05, "reaccion": 0.38, "distancia": 120.0, "pocion": 0.35},
	3: {"hp": 1.5, "dano": 1.35, "reaccion": 0.20, "distancia": 135.0, "pocion": 0.45},
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


## Segundos entre decisiones de la FSM en ese capitulo (menor = reacciona antes).
static func intervalo_decision(capitulo: int) -> float:
	return TABLA[normalizar_capitulo(capitulo)]["reaccion"]


## Distancia horizontal (px) a la que el bot considera que esta en rango.
static func distancia_ataque(capitulo: int) -> float:
	return TABLA[normalizar_capitulo(capitulo)]["distancia"]


## Fraccion de vida por debajo de la cual el bot bebe pocion.
static func umbral_pocion(capitulo: int) -> float:
	return TABLA[normalizar_capitulo(capitulo)]["pocion"]


## Aplica la dificultad del capitulo a [param bot]. Es idempotente: se calcula siempre
## sobre los atributos base del bot, asi que repetir la llamada, o pasar de un capitulo
## a otro, no acumula multiplicadores. Ver [method Personaje.aplicar_multiplicadores_dificultad].
static func aplicar(bot: Personaje, capitulo: int) -> void:
	if bot == null:
		return
	bot.aplicar_multiplicadores_dificultad(
		multiplicador_hp(capitulo), multiplicador_dano(capitulo))


## Ajusta los tiempos y el criterio de la FSM al capitulo (OUFW-19). Se llama despues
## de crear el [ControladorBot]; no toca vida ni dano (eso es [method aplicar]).
static func aplicar_bot(bot: ControladorBot, capitulo: int) -> void:
	if bot == null:
		return
	var c := normalizar_capitulo(capitulo)
	bot.intervalo_decision = intervalo_decision(c)
	bot.distancia_ataque = distancia_ataque(c)
	bot.umbral_vida_pocion = umbral_pocion(c)


## Texto corto del capitulo para depuracion y HUD, por ejemplo "Cap 3: vida x1.50, dano x1.35".
static func descripcion(capitulo: int) -> String:
	var c := normalizar_capitulo(capitulo)
	return "Cap %d: vida x%.2f, dano x%.2f" % [c, multiplicador_hp(c), multiplicador_dano(c)]
