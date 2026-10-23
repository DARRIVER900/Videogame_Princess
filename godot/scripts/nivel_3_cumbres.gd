class_name Nivel3Cumbres
extends NivelJugable
## Nivel 3 "Cumbres de Azucar" (OUFW-14): graybox del Capitulo 3.
##
## Mismo encuadre, paredes y spawns que el resto de arenas ([NivelArena]), mas cinco
## plataformas de UN SOLO SENTIDO ("terrones de azucar") formando una escalera simetrica
## que sube de los lados hacia una cima central. La escena se genera con
## tools/crear_nivel_3.gd, asi que cada medida vive aqui y en ningun otro lado.
##
## DISENO: el Bosque (Cap 2) tiene una sola ventaja alta; aqui hay tres alturas y el
## combate se juega en vertical. El camino a la cima es siempre el mismo, de fuera hacia
## dentro: suelo -> terron bajo (60 px) -> terron medio (120 px) -> cima (180 px).
##
## ALCANCE DEL SALTO (medido en tests/test_nivel_3.gd): una princesa sube unos 80 px, asi
## que CADA peldano es de 60 px (holgura de ~20 px) y ninguno de los altos se alcanza desde
## el suelo: la cima solo se gana subiendo, peldano a peldano. Horizontalmente los
## terrones se tocan o dejan 20 px de hueco, nunca mas de lo que cruza un salto.
##
## Los spawns (x = +-140) quedan BAJO los terrones medios. No estorba: el terron queda a
## 108 px del suelo y la princesa mide 64, ademas se atraviesa por debajo.

## Plataformas del nivel. [code]altura[/code] es la distancia de la SUPERFICIE superior al
## suelo (y = 0), siempre positiva hacia arriba. [code]centro_x[/code] y [code]ancho[/code]
## estan en px respecto al centro de la arena. Orden: de fuera hacia dentro y de abajo
## arriba. La geometria ([method rect_plataforma], [method y_superficie]) la hereda de
## [NivelArena].
const PLATAFORMAS := [
	{"nombre": "TerronBajoIzquierdo", "centro_x": -300.0, "ancho": 140.0, "altura": 60.0},
	{"nombre": "TerronBajoDerecho", "centro_x": 300.0, "ancho": 140.0, "altura": 60.0},
	{"nombre": "TerronMedioIzquierdo", "centro_x": -160.0, "ancho": 140.0, "altura": 120.0},
	{"nombre": "TerronMedioDerecho", "centro_x": 160.0, "ancho": 140.0, "altura": 120.0},
	{"nombre": "TerronCima", "centro_x": 0.0, "ancho": 140.0, "altura": 180.0},
]


const SIGUIENTE_NIVEL := "res://escenas/fin_juego.tscn"


func _ready() -> void:
	numero_nivel = 3
	siguiente_escena = SIGUIENTE_NIVEL
	super._ready()
