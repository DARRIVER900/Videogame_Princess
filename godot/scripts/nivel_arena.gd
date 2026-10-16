class_name NivelArena
extends Node2D
## Base de todas las arenas de combate (OUFW-6, OUFW-14): medidas compartidas del
## escenario (encuadre, paredes, suelo, spawns) y ajuste de dificultad del rival.
##
## Cada nivel hereda de aqui y agrega solo lo suyo: [code]nivel_1_frontera.gd[/code],
## [code]nivel_2_bosque.gd[/code]... Las escenas se generan con [code]tools/crear_nivel_*.gd[/code],
## asi que cada numero vive en un script y en ningun otro lado.

## Encuadre de la camara (igual al viewport de project.godot).
const ANCHO_PANTALLA := 960.0
const ALTO_PANTALLA := 540.0
const POSICION_CAMARA := Vector2(0.0, -60.0)

## Medio ancho del sprite de una princesa: las paredes dejan este margen para
## que ningun sprite se salga del encuadre.
const MARGEN_PARED := 24.0
## Distancia entre las caras interiores de las paredes invisibles.
const ANCHO_JUGABLE := ANCHO_PANTALLA - 2.0 * MARGEN_PARED
const GROSOR_PARED := 40.0
## Mucho mayor que el salto (~85 px): no se puede saltar por encima.
const ALTO_PARED := 800.0

## La superficie del suelo esta en y = 0. Los pies de una princesa (capsula de
## 64 px) tocan el suelo con position.y = -32.
const GROSOR_SUELO := 200.0
const Y_APARICION := -32.0
## Separacion horizontal de cada princesa respecto al centro al empezar. Deja
## sitio detras para un derrape y un salto atras sin tocar la pared, y las
## deja fuera del alcance del golpe fuerte (ver tests/test_nivel_1.gd).
const X_APARICION := 140.0

## Capitulo al que pertenece este nivel (1 a 3). Define la dificultad del rival
## (OUFW-15): ver [DificultadCapitulo]. Cada nivel lo fija en su escena.
@export_range(1, 3) var capitulo: int = 1


## Ajusta al rival al capitulo. Se hace aqui y no en la escena porque
## [method Personaje._ready] reescribe vida y dano: los multiplicadores tienen que
## entrar DESPUES del `_ready` del rival, y el de un padre corre despues del de sus hijos.
func _ready() -> void:
	var rival := get_node_or_null("Rival") as Personaje
	if rival != null:
		DificultadCapitulo.aplicar(rival, capitulo)


## X de la cara interior de la pared izquierda.
func limite_izquierdo() -> float:
	return -ANCHO_JUGABLE * 0.5


## X de la cara interior de la pared derecha.
func limite_derecho() -> float:
	return ANCHO_JUGABLE * 0.5


# --- Plataformas (OUFW-14): geometria compartida por los niveles con plataformas ---

## Grosor visual y de colision de cada plataforma, en px.
const GROSOR_PLATAFORMA := 12.0


## Rectangulo de una plataforma en coordenadas del nivel (y negativa hacia arriba): su
## borde superior es la superficie sobre la que se pisa. [param datos] es una entrada de
## la tabla [code]PLATAFORMAS[/code] del nivel: [code]centro_x[/code], [code]ancho[/code] y
## [code]altura[/code] (distancia de la superficie al suelo, positiva hacia arriba).
static func rect_plataforma(datos: Dictionary) -> Rect2:
	var ancho: float = datos["ancho"]
	return Rect2(
		float(datos["centro_x"]) - ancho * 0.5,
		-float(datos["altura"]),
		ancho,
		GROSOR_PLATAFORMA)


## Y (coordenada del nivel) de la superficie de la plataforma: ahi quedan los PIES de una
## princesa de pie encima. El centro de su capsula de 64 px queda 32 px mas arriba, es
## decir, en [code]y_superficie(datos) + Y_APARICION[/code] (Y_APARICION vale -32).
static func y_superficie(datos: Dictionary) -> float:
	return -float(datos["altura"])
