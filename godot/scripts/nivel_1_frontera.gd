extends Node2D
## Nivel 1 "La Frontera Despejada" (OUFW-6): graybox del Capitulo 1.
##
## Solo guarda las medidas del escenario. La escena se genera con
## tools/crear_nivel_1.gd, asi que cada numero vive aqui y en ningun otro lado.

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


## X de la cara interior de la pared izquierda.
func limite_izquierdo() -> float:
	return -ANCHO_JUGABLE * 0.5


## X de la cara interior de la pared derecha.
func limite_derecho() -> float:
	return ANCHO_JUGABLE * 0.5