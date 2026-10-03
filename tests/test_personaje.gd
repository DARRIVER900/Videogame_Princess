extends SceneTree
## Suite de pruebas headless para OUFW-1 (clase base Personaje).
##
## Ejecutar:
##   godot --headless --script res://tests/test_personaje.gd
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	print("=== OUFW-1: Clase base Personaje ===\n")

	_prueba_inicializacion()
	_prueba_recibir_dano()
	_prueba_muerte()
	_prueba_aplicar_curacion()
	_prueba_atributos_gdd()
	_prueba_herencia_polimorfismo()

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


## Instancia un personaje y simula el arranque que Unity/Godot haria al anadirlo
## al arbol. Las clases son nodos, asi que liberamos con free().
func _nuevo(tipo: Script) -> Personaje:
	var p: Personaje = tipo.new()
	p._ready()
	return p


func _prueba_inicializacion() -> void:
	print("-- Inicializacion --")
	var p := _nuevo(PrincesaDulcecito)

	_comprobar("current_hp arranca en hp_max", p.current_hp == p.hp_max,
		"%d/%d" % [p.current_hp, p.hp_max])
	_comprobar("no arranca muerto", not p.esta_muerto)
	_comprobar("ratio_hp arranca en 1.0", is_equal_approx(p.ratio_hp, 1.0),
		str(p.ratio_hp))

	p.free()


func _prueba_recibir_dano() -> void:
	print("-- Recibir dano --")
	var p := _nuevo(PrincesaDulcecito)

	# OJO: las lambdas de GDScript capturan las variables locales POR VALOR, asi que
	# un contador `cambios += 1` dentro del callback modificaria una copia. Por eso el
	# registro es un Dictionary, que si es un tipo de referencia.
	var reg := {"hp": -1, "cambios": 0}
	p.health_changed.connect(
		func(hp: int, _max: int) -> void:
			reg["hp"] = hp
			reg["cambios"] += 1
	)

	p.recibir_dano(30, Personaje.TipoAtaque.GOLPE_NORMAL)
	_comprobar("resta el dano", p.current_hp == 70, "hp=%d" % p.current_hp)
	_comprobar("emite health_changed", reg["hp"] == 70 and reg["cambios"] == 1,
		"cambios=%d" % reg["cambios"])
	_comprobar("ratio_hp correcto", is_equal_approx(p.ratio_hp, 0.7),
		str(p.ratio_hp))

	p.recibir_dano(-5, Personaje.TipoAtaque.GOLPE_FUERTE)
	_comprobar("ignora dano negativo", p.current_hp == 70, "hp=%d" % p.current_hp)

	p.recibir_dano(0, Personaje.TipoAtaque.GOLPE_FUERTE)
	_comprobar("ignora dano cero", p.current_hp == 70, "hp=%d" % p.current_hp)

	p.free()


func _prueba_muerte() -> void:
	print("-- Muerte --")
	var p := _nuevo(PrincesaChocolatito)

	var muertes := [0]
	p.died.connect(func() -> void: muertes[0] += 1)

	p.recibir_dano(999, Personaje.TipoAtaque.SUPER_PESADO_CARGA)
	_comprobar("HP nunca baja de 0", p.current_hp == 0, "hp=%d" % p.current_hp)
	_comprobar("marca esta_muerto", p.esta_muerto)
	_comprobar("died se dispara 1 vez", muertes[0] == 1, "muertes=%d" % muertes[0])

	p.recibir_dano(50, Personaje.TipoAtaque.GOLPE_NORMAL)
	_comprobar("no vuelve a morir", muertes[0] == 1, "muertes=%d" % muertes[0])
	_comprobar("ignora dano tras morir", p.current_hp == 0, "hp=%d" % p.current_hp)
	_comprobar("ratio_hp en 0 al morir", is_equal_approx(p.ratio_hp, 0.0),
		str(p.ratio_hp))

	var curado := p.aplicar_curacion(50)
	_comprobar("no cura tras morir", curado == 0 and p.current_hp == 0,
		"hp=%d" % p.current_hp)

	p.free()


func _prueba_aplicar_curacion() -> void:
	print("-- Aplicar curacion (vivo) --")
	var p := _nuevo(PrincesaDulcecito)

	# Mismo detalle que en _prueba_recibir_dano: Dictionary para poder contar de verdad.
	var reg := {"hp": 0}
	p.health_changed.connect(func(hp: int, _max: int) -> void: reg["hp"] = hp)

	var recuperado := p.aplicar_curacion(15)
	_comprobar("no supera hp_max", p.current_hp == 100 and recuperado == 0,
		"hp=%d recup=%d" % [p.current_hp, recuperado])
	_comprobar("no emite si no hubo cambio", reg["hp"] == 0,
		"notificado=%d" % reg["hp"])

	p.recibir_dano(40, Personaje.TipoAtaque.VENENO)
	recuperado = p.aplicar_curacion(15)
	_comprobar("curacion tras dano", p.current_hp == 75 and recuperado == 15,
		"hp=%d recup=%d" % [p.current_hp, recuperado])
	_comprobar("emite tras curar", reg["hp"] == 75,
		"notificado=%d" % reg["hp"])

	recuperado = p.aplicar_curacion(999)
	_comprobar("curacion respeta hp_max", p.current_hp == 100,
		"hp=%d" % p.current_hp)
	_comprobar("devuelve solo el exceso real", recuperado == 25,
		"recup=%d" % recuperado)

	_comprobar("curacion negativa ignorada",
		p.aplicar_curacion(-10) == 0 and p.current_hp == 100,
		"hp=%d" % p.current_hp)

	p.free()


func _prueba_atributos_gdd() -> void:
	print("-- Atributos por defecto (GDD seccion 8) --")
	var d := _nuevo(PrincesaDulcecito)
	var c := _nuevo(PrincesaChocolatito)

	_comprobar("Dulcecito: AGIL_DISTANCIA",
		d.modset_clase == Personaje.Modset.AGIL_DISTANCIA, str(d.modset_clase))
	_comprobar("Chocolatito: PESADO_PESA",
		c.modset_clase == Personaje.Modset.PESADO_PESA, str(c.modset_clase))
	_comprobar("Dulcecito: skin Candyr",
		d.id_skin_activa == "SKIN_CANDYR_DEFAULT", d.id_skin_activa)
	_comprobar("Chocolatito: skin Chocolate",
		c.id_skin_activa == "SKIN_CHOCOLATE_DEFAULT", c.id_skin_activa)
	_comprobar("nombre de Dulcecito", d.nombre == "Princesa Dulcecito", d.nombre)
	_comprobar("nombre de Chocolatito",
		c.nombre == "Princesa Chocolatito", c.nombre)

	for p: Personaje in [d, c]:
		_comprobar("%s: hp_max=100" % p.nombre, p.hp_max == 100, str(p.hp_max))
		_comprobar("%s: multiplicador_dano=1.0" % p.nombre,
			is_equal_approx(p.multiplicador_dano, 1.0), str(p.multiplicador_dano))
		_comprobar("%s: pociones=3" % p.nombre,
			p.cantidad_pociones == 3, str(p.cantidad_pociones))

	d.free()
	c.free()


func _prueba_herencia_polimorfismo() -> void:
	print("-- Herencia y polimorfismo --")
	var p := _nuevo(PrincesaDulcecito)

	# Ambos lados del HUD (OUFW-5) deben poder tratar a las dos princesas igual.
	var lista: Array[Personaje] = [_nuevo(PrincesaDulcecito), _nuevo(PrincesaChocolatito)]
	for personaje: Personaje in lista:
		personaje.recibir_dano(40, Personaje.TipoAtaque.GOLPE_FUERTE)
		personaje.aplicar_curacion(15)

	var ambos_vivos := true
	for personaje: Personaje in lista:
		ambos_vivos = ambos_vivos and personaje.current_hp == 75 \
			and not personaje.esta_muerto

	_comprobar("ambas princesas comparten la misma API", ambos_vivos,
		str(lista.map(func(x: Personaje) -> int: return x.current_hp)))

	# Aislamiento de estado: el dano a una no debe tocar a la otra.
	lista[0].recibir_dano(999, Personaje.TipoAtaque.SUPER_PESADO_CARGA)
	_comprobar("el estado es independiente por instancia",
		lista[0].esta_muerto and not lista[1].esta_muerto,
		"d=%s c=%s" % [lista[0].esta_muerto, lista[1].esta_muerto])

	_comprobar("Personaje es la clase base de ambas",
		lista[0] is Personaje and lista[1] is Personaje)

	for personaje: Personaje in lista:
		personaje.free()
	p.free()
