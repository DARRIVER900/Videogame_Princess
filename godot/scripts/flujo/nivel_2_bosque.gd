class_name Nivel2Bosque
extends NivelArena
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
## estan en px respecto al centro de la arena. Orden: de fuera hacia dentro. La geometria
## ([method rect_plataforma], [method y_superficie]) la hereda de [NivelArena].
const PLATAFORMAS := [
	{"nombre": "TroncoIzquierdo", "centro_x": -250.0, "ancho": 160.0, "altura": 60.0},
	{"nombre": "TroncoDerecho", "centro_x": 250.0, "ancho": 160.0, "altura": 60.0},
	{"nombre": "RamaCentral", "centro_x": 0.0, "ancho": 220.0, "altura": 120.0},
]