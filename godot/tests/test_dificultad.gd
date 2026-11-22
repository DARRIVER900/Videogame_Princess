extends SceneTree
## Suite de pruebas headless para OUFW-15 (dificultad gradual, capitulos 1 a 3).
##
## Ejecutar:
##   godot --headless --script res://tests/test_dificultad.gd
##
## Criterio de aceptacion: el Nivel 3 presenta un bot significativamente mas agresivo
## que el Nivel 1. "Significativamente" se mide aqui como umbrales concretos
## ([constant RATIO_MINIMO]) sobre vida, dano y golpes necesarios para ganar.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

## El bot del Cap 3 debe tener al menos esta razon de vida y de dano frente al del Cap 1.
const RATIO_MINIMO := 1.5
const RUTA_NIVEL := "res://escenas/nivel_1_frontera.tscn"

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-15: Dificultad gradual Cap 1 a 3 ===\n")

	_prueba_tabla()
	_prueba_criterio_nivel3_vs_nivel1()
	_prueba_aplicacion_al_bot()
	_prueba_idempotencia()
	_prueba_golpes_reales()
	_prueba_no_toca_a_la_jugadora()
	_prueba_casos_borde()
	await _prueba_nivel()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _total)
		quit(0)
	else:
		print("%d DE %d PRUEBAS FALLARON" % [_fallos, _total])
		quit(1)


func _comprobar(nombre: String, ok: bool, detalle: String = "") -> void:
	_total += 1
	if ok:
		print("  OK    | %s  (%s)" % [nombre, detalle])
	else:
		_fallos += 1
		print("  FALLA | %s  (%s)" % [nombre, detalle])


## Instancia el bot y simula el arranque, igual que en test_personaje.gd.
func _bot(tipo: Script = PrincesaChocolatito) -> Personaje:
	var p: Personaje = tipo.new()
	p._ready()
	return p


func _prueba_tabla() -> void:
	print("-- Tabla de multiplicadores --")
	var completa := true
	for c in range(DificultadCapitulo.CAPITULO_MIN, DificultadCapitulo.CAPITULO_MAX + 1):
		completa = completa and DificultadCapitulo.TABLA.has(c)
	_comprobar("hay una fila por cada capitulo (1 a 3)", completa)

	var crece_hp := DificultadCapitulo.multiplicador_hp(1) < DificultadCapitulo.multiplicador_hp(2) \
		and DificultadCapitulo.multiplicador_hp(2) < DificultadCapitulo.multiplicador_hp(3)
	var crece_dano := DificultadCapitulo.multiplicador_dano(1) < DificultadCapitulo.multiplicador_dano(2) \
		and DificultadCapitulo.multiplicador_dano(2) < DificultadCapitulo.multiplicador_dano(3)
	_comprobar("la vida crece estrictamente 1 < 2 < 3", crece_hp)
	_comprobar("el dano crece estrictamente 1 < 2 < 3", crece_dano)

	var positivos := true
	for c in DificultadCapitulo.TABLA:
		positivos = positivos and DificultadCapitulo.TABLA[c]["hp"] > 0.0 \
			and DificultadCapitulo.TABLA[c]["dano"] > 0.0
	_comprobar("ningun multiplicador es cero ni negativo", positivos)


func _prueba_criterio_nivel3_vs_nivel1() -> void:
	print("-- Criterio: Nivel 3 significativamente mas agresivo que Nivel 1 --")
	var r_hp := DificultadCapitulo.multiplicador_hp(3) / DificultadCapitulo.multiplicador_hp(1)
	var r_dano := DificultadCapitulo.multiplicador_dano(3) / DificultadCapitulo.multiplicador_dano(1)
	_comprobar("vida del Cap 3 >= %.1fx la del Cap 1" % RATIO_MINIMO, r_hp >= RATIO_MINIMO,
		"x%.2f" % r_hp)
	_comprobar("dano del Cap 3 >= %.1fx el del Cap 1" % RATIO_MINIMO, r_dano >= RATIO_MINIMO,
		"x%.2f" % r_dano)

	# Medido sobre personajes reales: el bot de Cap 3 debe matar a la jugadora con
	# muchos menos golpes y aguantar muchos mas golpes de la jugadora.
	var jugadora := _bot(PrincesaDulcecito)
	var b1 := _bot()
	var b3 := _bot()
	DificultadCapitulo.aplicar(b1, 1)
	DificultadCapitulo.aplicar(b3, 3)

	var golpes_para_matar_1 := _golpes_para_vencer(b1.dano_golpe_normal, b1.multiplicador_dano,
		jugadora.hp_max)
	var golpes_para_matar_3 := _golpes_para_vencer(b3.dano_golpe_normal, b3.multiplicador_dano,
		jugadora.hp_max)
	_comprobar("el bot del Cap 3 mata a la jugadora con menos golpes que el del Cap 1",
		golpes_para_matar_3 < golpes_para_matar_1,
		"cap1=%d cap3=%d golpes" % [golpes_para_matar_1, golpes_para_matar_3])

	var golpes_para_vencer_1 := _golpes_para_vencer(jugadora.dano_golpe_normal,
		jugadora.multiplicador_dano, b1.hp_max)
	var golpes_para_vencer_3 := _golpes_para_vencer(jugadora.dano_golpe_normal,
		jugadora.multiplicador_dano, b3.hp_max)
	_comprobar("la jugadora necesita mas golpes para vencer al bot del Cap 3",
		golpes_para_vencer_3 > golpes_para_vencer_1,
		"cap1=%d cap3=%d golpes" % [golpes_para_vencer_1, golpes_para_vencer_3])

	jugadora.free()
	b1.free()
	b3.free()


## Golpes de [param dano_base] (escalado por [param mult]) que hacen falta para
## llevar [param vida] a cero. Replica el redondeo de Personaje._ejecutar_ataque.
func _golpes_para_vencer(dano_base: int, mult: float, vida: int) -> int:
	var por_golpe := maxi(1, roundi(dano_base * mult))
	return ceili(float(vida) / float(por_golpe))


func _prueba_aplicacion_al_bot() -> void:
	print("-- Aplicacion al bot --")
	var bases := _bot()
	var hp_base := bases.hp_max
	var dano_base := bases.multiplicador_dano
	bases.free()

	for c in [1, 2, 3]:
		var bot := _bot()
		var reg := {"emitidas": []}
		bot.health_changed.connect(func(hp: int, m: int) -> void: reg["emitidas"].append([hp, m]))
		DificultadCapitulo.aplicar(bot, c)

		var hp_esperado := roundi(hp_base * DificultadCapitulo.multiplicador_hp(c))
		_comprobar("Cap %d: hp_max = base x multiplicador" % c, bot.hp_max == hp_esperado,
			"%d (esperado %d)" % [bot.hp_max, hp_esperado])
		_comprobar("Cap %d: multiplicador_dano = base x multiplicador" % c,
			is_equal_approx(bot.multiplicador_dano, dano_base * DificultadCapitulo.multiplicador_dano(c)),
			"%.2f" % bot.multiplicador_dano)
		_comprobar("Cap %d: el bot empieza a vida completa" % c, bot.current_hp == bot.hp_max,
			"%d/%d" % [bot.current_hp, bot.hp_max])
		_comprobar("Cap %d: avisa al HUD con health_changed" % c,
			reg["emitidas"] == [[bot.hp_max, bot.hp_max]], str(reg["emitidas"]))
		bot.free()

	var b := _bot()
	DificultadCapitulo.aplicar(b, 3)
	_comprobar("Cap 3: 100 HP base pasan a 150", b.hp_max == 150, str(b.hp_max))
	b.free()


func _prueba_idempotencia() -> void:
	print("-- Idempotencia: los multiplicadores no se acumulan --")
	var bot := _bot()
	DificultadCapitulo.aplicar(bot, 3)
	DificultadCapitulo.aplicar(bot, 3)
	DificultadCapitulo.aplicar(bot, 3)
	_comprobar("aplicar el Cap 3 tres veces deja 150 HP, no 100 x1.5^3",
		bot.hp_max == 150, str(bot.hp_max))
	_comprobar("y el dano sigue en x1.35",
		is_equal_approx(bot.multiplicador_dano, 1.35), "%.3f" % bot.multiplicador_dano)

	DificultadCapitulo.aplicar(bot, 1)
	_comprobar("volver al Cap 1 devuelve la vida base (100)", bot.hp_max == 100,
		str(bot.hp_max))
	_comprobar("y el dano a x0.80", is_equal_approx(bot.multiplicador_dano, 0.8),
		"%.3f" % bot.multiplicador_dano)
	bot.free()


## El dano que sale en un Hitbox real ya lleva el multiplicador.
func _prueba_golpes_reales() -> void:
	print("-- El dano de los golpes reales sale escalado --")
	var esperado := {1: [8, 20], 2: [11, 26], 3: [14, 34]}
	for c in [1, 2, 3]:
		var bot := _bot()
		bot.nombre = "Bot"
		root.add_child(bot)
		DificultadCapitulo.aplicar(bot, c)
		bot.ataque_normal()
		var normal: Hitbox = bot.get_node_or_null("Hitbox_0")
		bot._cooldown_ataque = 0.0
		bot.ataque_fuerte()
		var fuerte: Hitbox = bot.get_node_or_null("Hitbox_1")
		_comprobar("Cap %d: golpe normal %d y fuerte %d" % [c, esperado[c][0], esperado[c][1]],
			normal != null and fuerte != null
			and normal.dano == esperado[c][0] and fuerte.dano == esperado[c][1],
			"normal=%s fuerte=%s" % [
				str(normal.dano) if normal != null else "?",
				str(fuerte.dano) if fuerte != null else "?"])
		bot.queue_free()


func _prueba_no_toca_a_la_jugadora() -> void:
	print("-- La dificultad solo afecta al bot que se le pasa --")
	var jugadora := _bot(PrincesaDulcecito)
	var bot := _bot()
	DificultadCapitulo.aplicar(bot, 3)
	_comprobar("la jugadora conserva 100 HP y dano x1.0",
		jugadora.hp_max == 100 and is_equal_approx(jugadora.multiplicador_dano, 1.0),
		"hp=%d dano=%.2f" % [jugadora.hp_max, jugadora.multiplicador_dano])
	_comprobar("las pociones del bot no cambian", bot.cantidad_pociones == 3,
		str(bot.cantidad_pociones))
	jugadora.free()
	bot.free()


func _prueba_casos_borde() -> void:
	print("-- Casos borde --")
	_comprobar("capitulo 0 cae en el 1", DificultadCapitulo.normalizar_capitulo(0) == 1)
	_comprobar("capitulo negativo cae en el 1", DificultadCapitulo.normalizar_capitulo(-5) == 1)
	_comprobar("capitulo 4 cae en el 3", DificultadCapitulo.normalizar_capitulo(4) == 3)
	_comprobar("capitulo 99 usa la fila del 3",
		is_equal_approx(DificultadCapitulo.multiplicador_hp(99), DificultadCapitulo.multiplicador_hp(3)))

	DificultadCapitulo.aplicar(null, 2)
	_comprobar("aplicar a null no revienta", true)

	var muerto := _bot()
	muerto.recibir_dano(9999)
	DificultadCapitulo.aplicar(muerto, 3)
	_comprobar("un bot muerto no se modifica", muerto.hp_max == 100 and muerto.current_hp == 0,
		"hp_max=%d hp=%d" % [muerto.hp_max, muerto.current_hp])
	muerto.free()

	var extremo := _bot()
	extremo.aplicar_multiplicadores_dificultad(0.0, -3.0)
	_comprobar("un multiplicador de vida 0 nunca deja hp_max < 1", extremo.hp_max >= 1,
		str(extremo.hp_max))
	_comprobar("un multiplicador de dano negativo se trata como 0",
		extremo.multiplicador_dano >= 0.0, "%.2f" % extremo.multiplicador_dano)
	extremo.free()

	_comprobar("descripcion legible",
		DificultadCapitulo.descripcion(3) == "Cap 3: vida x1.50, dano x1.35",
		DificultadCapitulo.descripcion(3))


## Camino real: la escena del nivel aplica la dificultad al Rival en su _ready.
func _prueba_nivel() -> void:
	print("-- Integracion con el nivel --")
	var escena: PackedScene = load(RUTA_NIVEL)

	var n1 := escena.instantiate() as Node2D
	root.add_child(n1)
	var r1 := n1.get_node("Rival") as Personaje
	var j1 := n1.get_node("Jugadora") as Personaje
	_comprobar("Nivel con capitulo por defecto (1): rival a 100 HP, dano x0.80",
		r1.hp_max == 100 and is_equal_approx(r1.multiplicador_dano, 0.8),
		"hp=%d dano=%.2f" % [r1.hp_max, r1.multiplicador_dano])
	_comprobar("la jugadora no se toca (100 HP, dano x1.0)",
		j1.hp_max == 100 and is_equal_approx(j1.multiplicador_dano, 1.0))

	var n3 := escena.instantiate() as Node2D
	n3.set("capitulo", 3)
	root.add_child(n3)
	var r3 := n3.get_node("Rival") as Personaje
	_comprobar("Nivel con capitulo = 3: rival a 150 HP, dano x1.35",
		r3.hp_max == 150 and is_equal_approx(r3.multiplicador_dano, 1.35)
		and r3.current_hp == 150,
		"hp=%d/%d dano=%.2f" % [r3.current_hp, r3.hp_max, r3.multiplicador_dano])
	_comprobar("el rival del Nivel 3 es mas duro que el del Nivel 1",
		r3.hp_max > r1.hp_max and r3.multiplicador_dano > r1.multiplicador_dano)

	n1.queue_free()
	n3.queue_free()