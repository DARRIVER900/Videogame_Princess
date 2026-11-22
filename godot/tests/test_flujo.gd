extends SceneTree
## Suite de pruebas headless para OUFW-18 (integracion del core loop).
##
## Ejecutar:
##   godot --headless --script res://tests/test_flujo.gd
##
## Criterio de aceptacion: transicion fluida entre escenas SIN PERDER VARIABLES DE ESTADO.
## La prueba central recorre el flujo entero con las escenas reales:
##   Menu -> Novela -> Nivel 1 -> Nivel 2 (con una derrota y un reintento) -> Nivel 3 -> Fin
## y comprueba, en cada salto, que puntuacion, pociones, derrotas y capitulo siguen donde
## deben. Ademas se prueban la fase y el fundido.
## Codigo de salida: 0 si todo pasa, 1 si algo falla.

const RUTA_DIALOGO_CAP1 := "res://datos/dialogos/cap1_intro.json"

var _fallos: int = 0
var _total: int = 0
var _flujo: FlujoJuego
var _fases: Array = []


func _init() -> void:
	_llamar_tarde()


func _llamar_tarde() -> void:
	await process_frame
	print("=== OUFW-18: Integracion del core loop ===\n")

	_prueba_proyecto_configurado()
	_prueba_estado_partida()
	_prueba_rutas_y_niveles()

	_flujo = FlujoJuego.obtener()
	_comprobar("el autoload esta en /root", _flujo != null and _flujo.get_parent() == root)
	if _flujo == null:
		quit(1)
		return
	_flujo.duracion_fundido = 0.0
	_flujo.pausa_fin_combate = 0.0

	await _prueba_nivel_emite_resultado()
	await _prueba_llamadas_fuera_de_fase()
	await _prueba_recorrido_completo()
	await _prueba_fundido()
	await _prueba_doble_llamada()
	await _prueba_novela_ilegible()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


# --- Utilidades ---

func _comprobar(nombre: String, ok: bool, detalle: String = "") -> void:
	_total += 1
	if ok:
		print("  OK    | %s  (%s)" % [nombre, detalle])
	else:
		_fallos += 1
		print("  FALLA | %s  (%s)" % [nombre, detalle])


## Espera (hasta [param max_frames] frames) a que [param condicion] sea verdadera.
func _esperar_hasta(condicion: Callable, max_frames: int = 600) -> bool:
	for _i in max_frames:
		if condicion.call():
			return true
		await process_frame
	return condicion.call()


func _escena() -> Node:
	return current_scene


## Espera a que la partida llegue a [param fase] y la transicion haya terminado.
func _esperar_fase(fase: FlujoJuego.Fase) -> bool:
	return await _esperar_hasta(_en_fase.bind(fase))


func _en_fase(fase: FlujoJuego.Fase) -> bool:
	return _flujo.fase == fase and not _flujo.esta_en_transicion() and current_scene != null


## Espera a que haya un nivel concreto cargado y listo (distinto de [param anterior]).
## [param id_anterior] es el id de instancia (get_instance_id) del nivel que se esta
## dejando: se compara por id porque ese nodo ya se libero al cambiar de escena, y un objeto
## liberado no se puede pasar como argumento. 0 = no hay nivel anterior.
func _esperar_nivel(capitulo: int, id_anterior: int = 0) -> NivelArena:
	var listo := await _esperar_hasta(_nivel_listo.bind(capitulo, id_anterior))
	return current_scene as NivelArena if listo else null


func _nivel_listo(capitulo: int, id_anterior: int) -> bool:
	var nivel := current_scene as NivelArena
	return nivel != null and nivel.get_instance_id() != id_anterior \
		and nivel.capitulo == capitulo \
		and _flujo.fase == FlujoJuego.Fase.COMBATE and not _flujo.esta_en_transicion()


func _jugadora(nivel: Node) -> Personaje:
	return nivel.get_node("Jugadora") as Personaje


func _rival(nivel: Node) -> Personaje:
	return nivel.get_node("Rival") as Personaje


func _fase_nombre(f: int) -> String:
	return FlujoJuego.Fase.keys()[f]


# --- Pruebas sin escenas ---

func _prueba_proyecto_configurado() -> void:
	print("-- Configuracion del proyecto --")
	_comprobar("FlujoJuego esta registrado como autoload \"Flujo\"",
		str(ProjectSettings.get_setting("autoload/Flujo", "")).ends_with("flujo_juego.gd"),
		str(ProjectSettings.get_setting("autoload/Flujo", "")))
	_comprobar("la escena principal es el menu del flujo",
		ProjectSettings.get_setting("application/run/main_scene", "") == FlujoJuego.RUTA_MENU,
		str(ProjectSettings.get_setting("application/run/main_scene", "")))


func _prueba_estado_partida() -> void:
	print("-- EstadoPartida: variables que viajan entre escenas --")
	var e := EstadoPartida.new()
	_comprobar("una partida nueva empieza en el capitulo 1 sin puntos ni derrotas",
		e.capitulo == 1 and e.puntuacion == 0 and e.derrotas == 0)
	_comprobar("sin combates jugados, las pociones estan sin definir (usa las de la princesa)",
		e.pociones_jugadora == EstadoPartida.POCIONES_SIN_DEFINIR)
	_comprobar("no es el ultimo capitulo", not e.es_ultimo_capitulo())

	var puntos := e.registrar_victoria(80, 2)
	_comprobar("ganar con 80 HP da 1000 + 80 x 10 = 1800", puntos == 1800 and e.puntuacion == 1800,
		str(puntos))
	_comprobar("y se queda con las 2 pociones que sobraron", e.pociones_jugadora == 2)
	e.avanzar_capitulo()
	_comprobar("avanzar lleva al capitulo 2 conservando puntos y pociones",
		e.capitulo == 2 and e.puntuacion == 1800 and e.pociones_jugadora == 2)

	e.registrar_derrota()
	_comprobar("perder suma una derrota", e.derrotas == 1)
	_comprobar("perder no toca puntos, capitulo ni pociones (el capitulo se repite igual)",
		e.puntuacion == 1800 and e.capitulo == 2 and e.pociones_jugadora == 2,
		"pts=%d cap=%d pociones=%d" % [e.puntuacion, e.capitulo, e.pociones_jugadora])

	e.avanzar_capitulo()
	e.avanzar_capitulo()
	_comprobar("el capitulo nunca pasa del 3", e.capitulo == 3 and e.es_ultimo_capitulo(),
		str(e.capitulo))
	e.registrar_victoria(-50, -1)
	_comprobar("HP o pociones negativos se tratan como 0",
		e.puntuacion == 1800 + 1000 and e.pociones_jugadora == 0, str(e.puntuacion))

	var copia := EstadoPartida.desde_diccionario(e.a_diccionario())
	_comprobar("guardar y cargar conserva todas las variables",
		copia.a_diccionario() == e.a_diccionario(), str(copia.a_diccionario()))
	var raro := EstadoPartida.desde_diccionario({"capitulo": 99, "puntuacion": -5})
	_comprobar("al cargar, un capitulo fuera de rango se recorta y los puntos no son negativos",
		raro.capitulo == 3 and raro.puntuacion == 0, "cap=%d pts=%d" % [raro.capitulo, raro.puntuacion])
	_comprobar("al cargar, las claves que faltan toman su valor por defecto",
		EstadoPartida.desde_diccionario({}).capitulo == 1)


func _prueba_rutas_y_niveles() -> void:
	print("-- Rutas del flujo y niveles --")
	for ruta in [FlujoJuego.RUTA_MENU, FlujoJuego.RUTA_NOVELA, FlujoJuego.RUTA_DERROTA,
			FlujoJuego.RUTA_FIN]:
		_comprobar("existe la pantalla %s" % ruta, ResourceLoader.exists(ruta))

	for capitulo in [1, 2, 3]:
		var ruta: String = FlujoJuego.RUTAS_NIVEL.get(capitulo, "")
		_comprobar("el capitulo %d tiene nivel (%s)" % [capitulo, ruta.get_file()],
			ruta != "" and ResourceLoader.exists(ruta))
		if ruta == "":
			continue
		var nivel := (load(ruta) as PackedScene).instantiate()
		_comprobar("  ... es un NivelArena del capitulo %d" % capitulo,
			nivel is NivelArena and (nivel as NivelArena).capitulo == capitulo)
		nivel.free()

	_comprobar("el capitulo 1 tiene dialogo de entrada",
		FlujoJuego.ruta_dialogo(1) == RUTA_DIALOGO_CAP1, FlujoJuego.ruta_dialogo(1))
	_comprobar("los capitulos 2 y 3 aun no tienen dialogo (se saltara la novela)",
		FlujoJuego.ruta_dialogo(2) == "" and FlujoJuego.ruta_dialogo(3) == "")


# --- Pruebas con escenas ---

## El nivel, sin flujo de por medio, avisa UNA vez de como termino el combate.
func _prueba_nivel_emite_resultado() -> void:
	print("-- El nivel avisa de como termino el combate --")
	var escena := load(FlujoJuego.RUTAS_NIVEL[1]) as PackedScene

	var n1 := escena.instantiate() as NivelArena
	root.add_child(n1)
	var reg1: Array = []
	n1.combate_terminado.connect(func(r: int, hp: int, p: int) -> void: reg1.append([r, hp, p]))
	_jugadora(n1).recibir_dano(30)
	_rival(n1).recibir_dano(9999)
	_comprobar("matar al rival emite VICTORIA con la vida y pociones de la jugadora",
		reg1 == [[NivelArena.Resultado.VICTORIA, 70, 3]], str(reg1))
	_jugadora(n1).recibir_dano(9999)
	_comprobar("si la jugadora cae despues, NO se emite otra vez (la primera muerte decide)",
		reg1.size() == 1, str(reg1.size()))
	var ctrl := n1.get_node("Jugadora/Controlador") as ControladorJugador
	_comprobar("al acabar el combate los controles de la jugadora quedan congelados",
		not ctrl.activo)
	n1.queue_free()

	var n2 := escena.instantiate() as NivelArena
	root.add_child(n2)
	var reg2: Array = []
	n2.combate_terminado.connect(func(r: int, hp: int, p: int) -> void: reg2.append([r, hp, p]))
	_jugadora(n2).recibir_dano(9999)
	_comprobar("morir la jugadora emite DERROTA con 0 HP",
		reg2 == [[NivelArena.Resultado.DERROTA, 0, 3]], str(reg2))
	n2.queue_free()

	# Veneno: el rival muere por DoT mientras la jugadora ya cayo -> solo cuenta la primera.
	var n3 := escena.instantiate() as NivelArena
	root.add_child(n3)
	var reg3: Array = []
	n3.combate_terminado.connect(func(r: int, _hp: int, _p: int) -> void: reg3.append(r))
	_rival(n3).recibir_dano(97)
	_rival(n3).aplicar_veneno(4, 5.0)
	_jugadora(n3).recibir_dano(9999)
	_rival(n3)._physics_process(1.0)  # el veneno mata al rival despues
	_comprobar("rival muerto por veneno tras caer la jugadora: sigue siendo 1 sola DERROTA",
		reg3 == [NivelArena.Resultado.DERROTA], str(reg3))
	n3.queue_free()
	await process_frame
	_flujo.reiniciar()


## Las llamadas de la API fuera de su fase no hacen nada (p.ej. un clic rezagado).
func _prueba_llamadas_fuera_de_fase() -> void:
	print("-- Llamadas fuera de fase se ignoran --")
	_flujo.reiniciar()
	var fase_antes := _flujo.fase
	await _flujo.novela_terminada()
	await _flujo.reintentar()
	_comprobar("novela_terminada() y reintentar() fuera de su fase no cambian nada",
		_flujo.fase == fase_antes and not _flujo.esta_en_transicion(), _fase_nombre(_flujo.fase))


## EL CRITERIO: recorrer el flujo entero sin perder variables de estado.
func _prueba_recorrido_completo() -> void:
	print("-- Recorrido completo: Menu -> Novela -> N1 -> N2 -> N3 -> Fin --")
	_fases.clear()
	_flujo.fase_cambiada.connect(func(f: int) -> void: _fases.append(f))

	# 1) Menu
	await _flujo.volver_al_menu()
	var menu := current_scene as PantallaMenu
	_comprobar("arranca en el menu principal", menu != null and _flujo.fase == FlujoJuego.Fase.MENU)
	_comprobar("el menu tiene los botones Nuevo juego y Salir",
		menu != null and menu.boton_nuevo != null and menu.boton_salir != null)

	# 2) "Nuevo juego" -> Novela
	menu.boton_nuevo.pressed.emit()
	_comprobar("Nuevo juego lleva a la novela visual", await _esperar_fase(FlujoJuego.Fase.NOVELA))
	var novela := current_scene as PantallaNovela
	var lineas_json: int = (JSON.parse_string(FileAccess.get_file_as_string(RUTA_DIALOGO_CAP1)) as Array).size()
	_comprobar("la novela recibe el dialogo del capitulo 1 y lo carga entero",
		novela != null and _flujo.dialogo_actual == RUTA_DIALOGO_CAP1
		and novela.lineas_totales() == lineas_json, "%d lineas" % lineas_json)
	_comprobar("la partida nueva esta en capitulo 1, 0 puntos", _flujo.estado.capitulo == 1
		and _flujo.estado.puntuacion == 0)
	for _i in lineas_json:
		novela.avanzar()

	# 3) Nivel 1
	var n1 := await _esperar_nivel(1)
	_comprobar("al acabar la novela se carga el Nivel 1 (Frontera)", n1 is Nivel1Frontera)
	if n1 == null:
		_comprobar("(se aborta el recorrido: no cargo el Nivel 1)", false)
		return
	_comprobar("la jugadora llega con las 3 pociones de la princesa",
		_jugadora(n1).cantidad_pociones == 3, str(_jugadora(n1).cantidad_pociones))
	_comprobar("la novela ya no esta pendiente", _flujo.dialogo_actual == "")
	_jugadora(n1).recibir_dano(35)
	_jugadora(n1).usar_pocion()
	_comprobar("en el Nivel 1 la jugadora queda con 80 HP y 2 pociones",
		_jugadora(n1).current_hp == 80 and _jugadora(n1).cantidad_pociones == 2,
		"hp=%d pociones=%d" % [_jugadora(n1).current_hp, _jugadora(n1).cantidad_pociones])

	# 4) Nivel 2 (sin novela: no hay cap2_intro.json). Las variables viajan.
	var id_n1 := n1.get_instance_id()
	_rival(n1).recibir_dano(9999)
	var n2 := await _esperar_nivel(2, id_n1)
	_comprobar("ganar el Nivel 1 lleva al Nivel 2 (Bosque) sin pasar por novela",
		n2 is Nivel2Bosque)
	if n2 == null:
		_comprobar("(se aborta el recorrido: no cargo el Nivel 2)", false)
		return
	_comprobar("la puntuacion del Nivel 1 se conserva: 1000 + 80 x 10 = 1800",
		_flujo.estado.puntuacion == 1800, str(_flujo.estado.puntuacion))
	_comprobar("las 2 pociones que sobraron viajan al Nivel 2",
		_jugadora(n2).cantidad_pociones == 2, str(_jugadora(n2).cantidad_pociones))
	_comprobar("la vida NO viaja: empieza el duelo a 100 HP", _jugadora(n2).current_hp == 100)
	_comprobar("y el rival entra con la dificultad del capitulo 2 (130 HP)",
		_rival(n2).hp_max == 130, str(_rival(n2).hp_max))

	# 5) Derrota en el Nivel 2 tras gastar una pocion.
	var id_n2 := n2.get_instance_id()
	_jugadora(n2).recibir_dano(20)
	_jugadora(n2).usar_pocion()
	_comprobar("en el Nivel 2 se gasta una pocion (queda 1)", _jugadora(n2).cantidad_pociones == 1)
	_jugadora(n2).recibir_dano(9999)
	_comprobar("morir lleva a la pantalla de derrota", await _esperar_fase(FlujoJuego.Fase.DERROTA))
	var derrota := current_scene as PantallaDerrota
	_comprobar("hay pantalla de derrota con sus botones", derrota != null
		and derrota.boton_reintentar != null and derrota.boton_menu != null)
	_comprobar("la derrota se anota y los puntos NO se pierden",
		_flujo.estado.derrotas == 1 and _flujo.estado.puntuacion == 1800 and _flujo.estado.capitulo == 2,
		"derrotas=%d pts=%d cap=%d" % [_flujo.estado.derrotas, _flujo.estado.puntuacion, _flujo.estado.capitulo])
	_comprobar("las pociones del estado siguen siendo las del inicio del capitulo (2), no las del KO (1)",
		_flujo.estado.pociones_jugadora == 2, str(_flujo.estado.pociones_jugadora))

	# 6) Reintentar -> Nivel 2 nuevo, sin novela, con el estado restaurado.
	derrota.boton_reintentar.pressed.emit()
	var n2b := await _esperar_nivel(2, id_n2)
	_comprobar("Reintentar vuelve al Nivel 2", n2b is Nivel2Bosque)
	if n2b == null:
		_comprobar("(se aborta el recorrido: no cargo el reintento)", false)
		return
	_comprobar("es una instancia NUEVA del nivel (todo reiniciado)",
		n2b.get_instance_id() != id_n2)
	_comprobar("la jugadora vuelve con 2 pociones y 100 HP, y el rival a 130 HP",
		_jugadora(n2b).cantidad_pociones == 2 and _jugadora(n2b).current_hp == 100
		and _rival(n2b).current_hp == 130,
		"pociones=%d hp=%d rival=%d" % [_jugadora(n2b).cantidad_pociones,
			_jugadora(n2b).current_hp, _rival(n2b).current_hp])

	# 7) Ganar el Nivel 2 con 100 HP y 1 pocion gastada.
	_jugadora(n2b).recibir_dano(10)
	_jugadora(n2b).usar_pocion()
	var id_n2b := n2b.get_instance_id()
	_rival(n2b).recibir_dano(9999)

	# 8) Nivel 3
	var n3 := await _esperar_nivel(3, id_n2b)
	_comprobar("ganar el Nivel 2 lleva al Nivel 3 (Cumbres)", n3 is Nivel3Cumbres)
	if n3 == null:
		_comprobar("(se aborta el recorrido: no cargo el Nivel 3)", false)
		return
	_comprobar("la puntuacion acumula los dos duelos: 1800 + 2000 = 3800",
		_flujo.estado.puntuacion == 3800, str(_flujo.estado.puntuacion))
	_comprobar("llega 1 pocion al Nivel 3 y el rival es el mas duro (170 HP)",
		_jugadora(n3).cantidad_pociones == 1 and _rival(n3).hp_max == 170,
		"pociones=%d rival=%d" % [_jugadora(n3).cantidad_pociones, _rival(n3).hp_max])
	_rival(n3).recibir_dano(9999)

	# 9) Fin de juego
	_comprobar("ganar el Nivel 3 lleva al fin de juego", await _esperar_fase(FlujoJuego.Fase.FIN))
	var fin := current_scene as PantallaFin
	_comprobar("hay pantalla de fin", fin != null)
	_comprobar("la puntuacion final acumulada es 3800 + 2000 = 5800",
		_flujo.estado.puntuacion == 5800, str(_flujo.estado.puntuacion))
	_comprobar("y la pantalla de fin la muestra", fin != null
		and fin.etiqueta_puntuacion.text.contains("5800"),
		fin.etiqueta_puntuacion.text if fin != null else "")

	# 10) Volver al menu y empezar de cero: nada de la partida anterior se arrastra.
	fin.boton_menu.pressed.emit()
	_comprobar("Volver al menu regresa al menu principal", await _esperar_fase(FlujoJuego.Fase.MENU))
	(current_scene as PantallaMenu).boton_nuevo.pressed.emit()
	await _esperar_fase(FlujoJuego.Fase.NOVELA)
	_comprobar("una partida nueva NO arrastra nada de la anterior",
		_flujo.estado.capitulo == 1 and _flujo.estado.puntuacion == 0
		and _flujo.estado.derrotas == 0
		and _flujo.estado.pociones_jugadora == EstadoPartida.POCIONES_SIN_DEFINIR)

	var esperado := [
		FlujoJuego.Fase.MENU, FlujoJuego.Fase.NOVELA,
		FlujoJuego.Fase.COMBATE,  # Nivel 1
		FlujoJuego.Fase.COMBATE,  # Nivel 2 (sin novela)
		FlujoJuego.Fase.DERROTA,
		FlujoJuego.Fase.COMBATE,  # reintento del Nivel 2
		FlujoJuego.Fase.COMBATE,  # Nivel 3 (sin novela)
		FlujoJuego.Fase.FIN, FlujoJuego.Fase.MENU, FlujoJuego.Fase.NOVELA,
	]
	_comprobar("la secuencia de fases fue exactamente la esperada", _fases == esperado,
		", ".join(_fases.map(_fase_nombre)))
	_flujo.reiniciar()


## El fundido deja la pantalla clara y desbloqueada al terminar, y bloquea mientras dura.
func _prueba_fundido() -> void:
	print("-- Fundido entre escenas --")
	var velo: ColorRect = null
	_flujo.duracion_fundido = 0.12
	_flujo.volver_al_menu()  # sin await: se observa a mitad de la transicion
	await process_frame
	await process_frame
	velo = _flujo.get_node("Fundido").get_child(0) as ColorRect
	_comprobar("durante la transicion el flujo esta ocupado", _flujo.esta_en_transicion())
	_comprobar("y el velo bloquea el raton (un clic no se cuela)",
		velo.mouse_filter == Control.MOUSE_FILTER_STOP)

	await _esperar_fase(FlujoJuego.Fase.MENU)
	await process_frame
	_comprobar("al terminar el velo esta transparente y deja pasar el raton",
		is_zero_approx(velo.modulate.a) and velo.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"alfa=%.2f" % velo.modulate.a)
	_comprobar("y el flujo queda libre", not _flujo.esta_en_transicion())
	_flujo.duracion_fundido = 0.0
	_flujo.reiniciar()


## Un doble clic en "Nuevo juego" no dispara dos transiciones.
func _prueba_doble_llamada() -> void:
	print("-- Doble clic --")
	await _flujo.volver_al_menu()
	var contador := {"n": 0}
	var anota := func(f: int) -> void:
		if f == FlujoJuego.Fase.NOVELA:
			contador["n"] += 1
	_flujo.fase_cambiada.connect(anota)
	_flujo.iniciar_partida()
	_flujo.iniciar_partida()
	await _esperar_fase(FlujoJuego.Fase.NOVELA)
	await process_frame
	_comprobar("dos llamadas seguidas a iniciar_partida() producen una sola transicion",
		contador["n"] == 1, str(contador["n"]))
	_flujo.fase_cambiada.disconnect(anota)
	_flujo.reiniciar()


## Una novela con un dialogo roto o ausente se salta: la jugadora nunca queda atrapada.
func _prueba_novela_ilegible() -> void:
	print("-- Novela ilegible no atrapa a la jugadora --")
	await _flujo.volver_al_menu()
	_flujo.reiniciar()
	_flujo.fase = FlujoJuego.Fase.NOVELA
	_flujo.dialogo_actual = "res://datos/dialogos/no_existe.json"
	var novela := (load(FlujoJuego.RUTA_NOVELA) as PackedScene).instantiate()
	root.add_child(novela)
	var nivel := await _esperar_nivel(1)
	_comprobar("con un dialogo inexistente la novela se salta y se llega al combate",
		nivel != null, "fase=%s" % _fase_nombre(_flujo.fase))
	novela.queue_free()
	_flujo.reiniciar()