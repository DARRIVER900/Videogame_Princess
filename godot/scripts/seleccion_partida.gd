class_name SeleccionPartida
extends RefCounted
## Estado persistente de la partida, compartido entre la seleccion de personaje
## (OUFW-17), el combate y las pantallas de fin (OUFW-16).
##
## Es una clase SIN instancia: todo es [code]static[/code], asi que el estado vive en
## el script cargado y sobrevive al cambio de escena igual que un autoload, pero sin
## depender de la seccion [code][autoload][/code] del proyecto. Esa independencia es
## deliberada: las suites headless corren con [code]--script[/code], modo en el que
## Godot NO carga los autoloads; una clase estatica si esta disponible siempre.
##
## Referencia: OUFW-17 "Menu Principal y Seleccion de Personajes".

## Escenas de las dos princesas jugables.
const ESCENA_DULCECITO := "res://escenas/princesa_dulcecito.tscn"
const ESCENA_CHOCOLATITO := "res://escenas/princesa_chocolatito.tscn"

## Clave de seleccion: la princesa Dulcecito (AGIL_DISTANCIA).
const DULCECITO := "dulcecito"
## Clave de seleccion: la princesa Chocolatito (PESADO_PESA).
const CHOCOLATITO := "chocolatito"

## Princesa elegida por el jugador. El rival de la arena sera la OTRA.
static var princesa_jugable: String = DULCECITO

## true cuando el jugador pulsa "Jugar". Distingue la partida real (menu -> nivel)
## de abrir una escena directamente en las suites headless, donde el nivel debe
## conservar sus princesas de prueba y el bot inactivo.
static var partida_iniciada: bool = false

## true cuando ya se mostro la intro del capitulo en esta partida. Evita repetirla
## al pulsar "Reintentar" tras un Game Over; el menu la reinicia al empezar de nuevo.
static var intro_vista: bool = false


## [return] La ruta de escena correspondiente a [param clave].
static func ruta_de(clave: String) -> String:
	return ESCENA_CHOCOLATITO if clave == CHOCOLATITO else ESCENA_DULCECITO


## [return] La princesa rival, que es siempre la que NO eligio el jugador.
static func clave_rival() -> String:
	return CHOCOLATITO if princesa_jugable == DULCECITO else DULCECITO


## [return] Si [param clave] es una seleccion valida.
static func es_clave_valida(clave: String) -> bool:
	return clave == DULCECITO or clave == CHOCOLATITO
