class_name Nivel2Bosque
extends NivelJugable
## Nivel 2 "Bosque Encantado" (OUFW-14): graybox del Capitulo 2.
##
## Mismo encuadre, paredes y spawns que el resto de arenas ([NivelArena]), mas tres
## plataformas de UN SOLO SENTIDO (se atraviesan por debajo y de lado, y se aterriza
## encima): dos troncos bajos a los lados y una rama alta en el centro. La escena se genera con
## tools/crear_nivel_2.gd, asi que cada medida vive aqui y en ningun otro lado.
##
## ALCANCE DEL SALTO (medido en tests/test_nivel_2.gd): una princesa sube unos 80 px.
## Por eso las alturas se eligen con holgura, para que el diseno no dependa de afinar el
## salto al pixel:
##   - Troncos (60 px): alcanzables desde el suelo con margen de ~20 px.
##   - Rama (120 px): NO alcanzable desde el suelo, solo desde un tronco (60 + 60, tambien
##     con ~20 px de margen). Es la
##     posicion de ventaja del nivel y obliga a ganarsela moviendose.

## Plataformas del nivel. [code]altura[/code] es la distancia de la SUPERFICIE superior al
## suelo (y = 0), siempre positiva hacia arriba. [code]centro_x[/code] y [code]ancho[/code]
## estan en px respecto al centro de la arena. Orden: de fuera hacia dentro.
const PLATAFORMAS := [
	{"nombre": "TroncoIzquierdo", "centro_x": -250.0, "ancho": 160.0, "altura": 60.0},
	{"nombre": "TroncoDerecho", "centro_x": 250.0, "ancho": 160.0, "altura": 60.0},
	{"nombre": "RamaCentral", "centro_x": 0.0, "ancho": 220.0, "altura": 120.0},
]


## Rectangulo de la plataforma en coordenadas del nivel (y negativa hacia arriba):
## su borde superior es la superficie sobre la que se pisa.
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

const SIGUIENTE_NIVEL := "res://escenas/nivel_3_cumbres.tscn"


func _ready() -> void:
	numero_nivel = 2
	siguiente_escena = SIGUIENTE_NIVEL
	super._ready()
