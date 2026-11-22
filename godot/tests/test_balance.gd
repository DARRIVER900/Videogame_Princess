extends SceneTree
## Suite de pruebas headless para OUFW-19 (balanceo de combate y tiempos del bot).
##
## Ejecutar:
##   godot --headless --script res://tests/test_balance.gd
##
## Criterios internos:
##   - Los cooldowns dejan combos legibles (sin spam) y cada herramienta tiene un DPS
##     dentro de la banda de diseno.
##   - La FSM reacciona mas rapido y bebe antes en cada capitulo.
##   - El combo basico tarda un tiempo razonable en tumbar a cada rival; el Cap 3 no
##     se gana solo spameandolo, pero el kit completo (carga + veneno + pociones) si
##     supera su DPS.
##   - Duelos reales bot-vs-bot: Cap 1 y 2 se ganan con margen decreciente y el Cap 3
##     exige las herramientas de la jugadora. Ninguno se acerca al timeout de 99 s.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const RUTA_NIVELES := {
	1: "res://escenas/nivel_1_frontera.tscn",
	2: "res://escenas/nivel_2_bosque.tscn",
	3: "res://escenas/nivel_3_cumbres.tscn",
}
## Reaccion del bot que hace de "jugadora" en el banco de pruebas: un humano medio.
const REACCION_BANCO := 0.20
const DISTANCIA_BANCO := 140.0
const UMBRAL_POCION_BANCO := 0.50
const LIMITE_DUELO := 45.0

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== OUFW-19: balanceo de combate y tiempos del bot ===\n")

	_prueba_cooldowns()
	_prueba_tiempos_bot()
	_prueba_tiempos_para_matar()
	_prueba_kit_de_habilidades()
	await _prueba_niveles()
	await _prueba_duelos()

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


func _base() -> Personaje:
	var p: Personaje = PrincesaDulcecito.new()
	p._ready()
	return p


func _prueba_cooldowns() -> void:
	print("-- Cooldowns: combos legibles y DPS dentro de banda --")
	var p := _base()
	_comprobar("golpe normal entre 0.18 y 0.30 s (no es spam)",
		p.cooldown_golpe_normal >= 0.18 and p.cooldown_golpe_normal <= 0.30,
		"%.2f s" % p.cooldown_golpe_normal)
	_comprobar("el fuerte es mas lento que el normal",
		p.cooldown_golpe_fuerte > p.cooldown_golpe_normal,
		"normal=%.2f fuerte=%.2f" % [p.cooldown_golpe_normal, p.cooldown_golpe_fuerte])
	_comprobar("la carga es mas lenta que el fuerte",
		p.cooldown_carga > p.cooldown_golpe_fuerte,
		"fuerte=%.2f carga=%.2f" % [p.cooldown_golpe_fuerte, p.cooldown_carga])
	_comprobar("el veneno tiene su propio cooldown largo (>= 1.2 s)",
		p.cooldown_veneno >= 1.2, "%.2f s" % p.cooldown_veneno)

	var ciclo := p.cooldown_golpe_normal + p.cooldown_golpe_fuerte
	var dano_ciclo := p.dano_golpe_normal + p.dano_golpe_fuerte
	var dps_combo := float(dano_ciclo) / ciclo
	var dps_carga := float(roundi(p.dano_carga * p.multiplicador_carga_max)) / p.cooldown_carga
	_comprobar("el combo normal+fuerte hace %.0f de dano cada %.2f s" % [dano_ciclo, ciclo],
		dano_ciclo == 35 and is_equal_approx(ciclo, 0.70), "%.2f" % ciclo)
	_comprobar("DPS del combo entre 40 y 60", dps_combo >= 40.0 and dps_combo <= 60.0,
		"%.1f" % dps_combo)
	_comprobar("DPS de la carga completa entre 65 y 85",
		dps_carga >= 65.0 and dps_carga <= 85.0, "%.1f" % dps_carga)
	p.free()


func _prueba_tiempos_bot() -> void:
	print("-- Tiempos del bot: reacciona antes y bebe antes en cada capitulo --")
	var reaccion_ok := true
	var distancias_ok := true
	var pociones_ok := true
	for c in range(2, 4):
		reaccion_ok = reaccion_ok \
			and DificultadCapitulo.intervalo_decision(c) < DificultadCapitulo.intervalo_decision(c - 1)
		distancias_ok = distancias_ok \
			and DificultadCapitulo.distancia_ataque(c) > DificultadCapitulo.distancia_ataque(c - 1)
		pociones_ok = pociones_ok \
			and DificultadCapitulo.umbral_pocion(c) > DificultadCapitulo.umbral_pocion(c - 1)
	_comprobar("la reaccion baja 0.55 -> 0.38 -> 0.20 s", reaccion_ok)
	_comprobar("el rango de ataque crece con el capitulo (105 -> 120 -> 135)",
		distancias_ok)
	_comprobar("el umbral de pocion crece con el capitulo (30% -> 35% -> 45%)",
		pociones_ok)

	var en_rango := true
	for c in [1, 2, 3]:
		var r := DificultadCapitulo.intervalo_decision(c)
		en_rango = en_rango and r >= 0.15 and r <= 0.70
	_comprobar("todas las reacciones son humanas (0.15 a 0.70 s)", en_rango)

	var bot := ControladorBot.new()
	DificultadCapitulo.aplicar_bot(bot, 3)
	_comprobar("aplicar_bot configura la FSM del Cap 3",
		is_equal_approx(bot.intervalo_decision, 0.20)
		and is_equal_approx(bot.distancia_ataque, 135.0)
		and is_equal_approx(bot.umbral_vida_pocion, 0.45),
		"reaccion=%.2f distancia=%.0f pocion=%.2f" % [
			bot.intervalo_decision, bot.distancia_ataque, bot.umbral_vida_pocion])
	DificultadCapitulo.aplicar_bot(bot, 1)
	_comprobar("volver al Cap 1 devuelve la FSM lenta",
		is_equal_approx(bot.intervalo_decision, 0.55)
		and is_equal_approx(bot.distancia_ataque, 105.0),
		"reaccion=%.2f distancia=%.0f" % [bot.intervalo_decision, bot.distancia_ataque])
	DificultadCapitulo.aplicar_bot(null, 2)
	_comprobar("aplicar_bot(null) no revienta", true)
	bot.free()


## Segundos de combo normal+fuerte necesarios para tumbar [param vida].
func _segundos_combo(vida: int, dano_ciclo: int, ciclo: float) -> float:
	var ciclos := ceili(float(vida) / float(dano_ciclo))
	return ciclos * ciclo


func _prueba_tiempos_para_matar() -> void:
	print("-- Tiempo para matar: el Cap 3 no cae solo con el combo basico --")
	var p := _base()
	var ciclo := p.cooldown_golpe_normal + p.cooldown_golpe_fuerte
	var dano_ciclo := p.dano_golpe_normal + p.dano_golpe_fuerte
	var t_cap1 := _segundos_combo(100, dano_ciclo, ciclo)
	var t_cap3 := _segundos_combo(150, dano_ciclo, ciclo)
	_comprobar("combo basico: Cap 1 cae en 2-4 s", t_cap1 >= 2.0 and t_cap1 <= 4.0,
		"%.1f s" % t_cap1)
	_comprobar("combo basico: Cap 3 exige 3-6 s de impacto limpio",
		t_cap3 >= 3.0 and t_cap3 <= 6.0, "%.1f s" % t_cap3)
	_comprobar("el Cap 3 aguanta mas combo que el Cap 1", t_cap3 > t_cap1,
		"cap1=%.1f cap3=%.1f" % [t_cap1, t_cap3])

	var golpes_cap1 := ceili(100.0 / p.dano_golpe_normal)
	var golpes_cap3 := ceili(150.0 / p.dano_golpe_normal)
	_comprobar("los 100 HP del rival del Cap 1 son 10 golpes normales",
		golpes_cap1 == 10, str(golpes_cap1))
	_comprobar("los 150 HP del Cap 3 son 15 golpes normales (antes 17 con 170 HP)",
		golpes_cap3 == 15, str(golpes_cap3))

	# La jugadora aguanta 145 HP efectivos con sus 3 pociones.
	var golpes_rival_cap3 := ceili(145.0 / (p.dano_golpe_normal * DificultadCapitulo.multiplicador_dano(3)))
	_comprobar("con 3 pociones la jugadora aguanta 11 golpes normales del Cap 3",
		golpes_rival_cap3 == 11, "%d golpes" % golpes_rival_cap3)
	p.free()


func _prueba_kit_de_habilidades() -> void:
	print("-- El kit completo (carga + veneno + pociones) supera al Cap 3 --")
	var p := _base()
	var ciclo := p.cooldown_golpe_normal + p.cooldown_golpe_fuerte
	var dps_jefe := float(p.dano_golpe_normal + p.dano_golpe_fuerte) \
		* DificultadCapitulo.multiplicador_dano(3) / ciclo
	var dps_carga := float(roundi(p.dano_carga * p.multiplicador_carga_max)) / p.cooldown_carga
	var dps_veneno := float(p.dano_veneno_por_segundo)
	_comprobar("el combo basico NO alcanza al jefe (DPS %.1f < %.1f)" % [50.0, dps_jefe],
		(float(p.dano_golpe_normal + p.dano_golpe_fuerte) / ciclo) < dps_jefe)
	_comprobar("la carga completa supera el DPS del jefe",
		dps_carga > dps_jefe, "%.1f > %.1f" % [dps_carga, dps_jefe])
	_comprobar("carga + veneno abren una ventana clara de victoria",
		dps_carga + dps_veneno > dps_jefe + 5.0,
		"%.1f > %.1f" % [dps_carga + dps_veneno, dps_jefe])
	_comprobar("el veneno alcanza desde fuera del rango del jefe (260 > 135 px)",
		p.alcance_veneno.x > DificultadCapitulo.distancia_ataque(3),
		"%.0f px" % p.alcance_veneno.x)
	_comprobar("el veneno aporta 20 de dano total (13% de los 150 HP del jefe)",
		p.dano_veneno_por_segundo * p.duracion_veneno == 20,
		"%d de dano" % int(p.dano_veneno_por_segundo * p.duracion_veneno))

	var vida_efectiva := p.hp_max + p.cantidad_pociones * p.curacion_pocion
	_comprobar("las 3 pociones dan 145 HP efectivos a la jugadora",
		vida_efectiva == 145, "%d HP" % vida_efectiva)
	p.free()


func _prueba_niveles() -> void:
	print("-- Los niveles aplican el perfil de su capitulo --")
	for c in [1, 2, 3]:
		var nivel: Node = load(RUTA_NIVELES[c]).instantiate()
		root.add_child(nivel)
		await process_frame
		var rival := nivel.get_node("Rival") as Personaje
		var bot := nivel.get_node("Rival/Bot") as ControladorBot
		var hp_esperado := roundi(100.0 * DificultadCapitulo.multiplicador_hp(c))
		_comprobar("Cap %d: rival con %d HP y dano x%.2f" % [
				c, hp_esperado, DificultadCapitulo.multiplicador_dano(c)],
			rival.hp_max == hp_esperado
			and is_equal_approx(rival.multiplicador_dano, DificultadCapitulo.multiplicador_dano(c)),
			"hp=%d dano=%.2f" % [rival.hp_max, rival.multiplicador_dano])
		_comprobar("Cap %d: el bot usa la reaccion de su capitulo (%.2f s)" % [
				c, DificultadCapitulo.intervalo_decision(c)],
			is_equal_approx(bot.intervalo_decision, DificultadCapitulo.intervalo_decision(c)),
			"%.2f s" % bot.intervalo_decision)
		nivel.queue_free()
		await process_frame


## Banco de duelos deterministico: piso, dos princesas y sus FSM. La "jugadora" usa
## una reaccion humana fija; el rival recibe la dificultad y el perfil del capitulo.
func _duelo(capitulo: int) -> Dictionary:
	var arena := Node2D.new()
	root.add_child(arena)

	var piso := StaticBody2D.new()
	piso.collision_layer = 2
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2400.0, 200.0)
	forma.shape = rect
	forma.position = Vector2(0.0, 100.0)
	piso.add_child(forma)
	arena.add_child(piso)

	var jugadora: Personaje = load("res://escenas/princesa_dulcecito.tscn").instantiate()
	jugadora.name = "Jugadora"
	jugadora.position = Vector2(-140.0, -32.0)
	arena.add_child(jugadora)

	var rival: Personaje = load("res://escenas/princesa_chocolatito.tscn").instantiate()
	rival.name = "Rival"
	rival.position = Vector2(140.0, -32.0)
	arena.add_child(rival)

	DificultadCapitulo.aplicar(rival, capitulo)
	var bot_j := ControladorBot.new()
	bot_j.name = "BotJugadora"
	bot_j.personaje = jugadora
	bot_j.rival = rival
	bot_j.intervalo_decision = REACCION_BANCO
	bot_j.distancia_ataque = DISTANCIA_BANCO
	bot_j.umbral_vida_pocion = UMBRAL_POCION_BANCO
	jugadora.add_child(bot_j)

	var bot_r := ControladorBot.new()
	bot_r.name = "BotRival"
	bot_r.personaje = rival
	bot_r.rival = jugadora
	rival.add_child(bot_r)
	DificultadCapitulo.aplicar_bot(bot_r, capitulo)

	var t := 0.0
	while t < LIMITE_DUELO and not jugadora.esta_muerto and not rival.esta_muerto:
		await physics_frame
		t += 1.0 / 60.0

	var resultado := {
		"ganador": "jugadora" if rival.esta_muerto else ("rival" if jugadora.esta_muerto else "nadie"),
		"tiempo": t,
		"hp_jugadora": jugadora.current_hp,
		"hp_rival": rival.current_hp,
	}
	arena.queue_free()
	await process_frame
	return resultado


func _prueba_duelos() -> void:
	print("-- Duelos reales: dificultad creciente sin llegar al timeout --")
	var d1 := await _duelo(1)
	var d2 := await _duelo(2)
	var d3 := await _duelo(3)

	_comprobar("Cap 1: la jugadora gana con vida de sobra",
		d1["ganador"] == "jugadora" and d1["hp_jugadora"] >= 40,
		"ganador=%s hp=%d t=%.1f" % [d1["ganador"], d1["hp_jugadora"], d1["tiempo"]])
	_comprobar("Cap 2: la jugadora gana con el margen mas justo",
		d2["ganador"] == "jugadora" and d2["hp_jugadora"] < d1["hp_jugadora"],
		"ganador=%s hp=%d t=%.1f" % [d2["ganador"], d2["hp_jugadora"], d2["tiempo"]])
	_comprobar("Cap 3: el jefe gana al bot espejo (hacen falta las habilidades)",
		d3["ganador"] == "rival" and d3["hp_rival"] > 0,
		"ganador=%s hp=%d t=%.1f" % [d3["ganador"], d3["hp_rival"], d3["tiempo"]])
	_comprobar("todos los duelos terminan antes de 20 s (el HUD da 99 s)",
		d1["tiempo"] < 20.0 and d2["tiempo"] < 20.0 and d3["tiempo"] < 20.0,
		"%.1f / %.1f / %.1f s" % [d1["tiempo"], d2["tiempo"], d3["tiempo"]])
	_comprobar("ningun duelo acaba en un one-shot (todos duran mas de 3 s)",
		d1["tiempo"] > 3.0 and d2["tiempo"] > 3.0 and d3["tiempo"] > 3.0)
