extends RefCounted
## Utilidades compartidas por los generadores de niveles (tools/crear_nivel_*.gd).
##
## Todo es estatico y no depende del arbol: los generadores solo componen nodos y los
## guardan. Se usa asi:
##   const Util := preload("res://tools/utilidades_nivel.gd")


## Cuerpo estatico en la capa Ground, sin mascara: no detecta nada, solo es detectado.
## [param una_via] hace la colision de UN SOLO SENTIDO (plataforma que se atraviesa por
## debajo y de lado, y se pisa por encima).
static func cuerpo_estatico(raiz: Node, nombre: String, tamano: Vector2, pos: Vector2,
		una_via: bool = false) -> StaticBody2D:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = nombre
	cuerpo.position = pos
	cuerpo.collision_layer = Personaje.CAPA_GROUND
	cuerpo.collision_mask = 0

	var forma := CollisionShape2D.new()
	forma.name = "Colision"
	var rect := RectangleShape2D.new()
	rect.size = tamano
	forma.shape = rect
	forma.one_way_collision = una_via
	cuerpo.add_child(forma)

	raiz.add_child(cuerpo)
	cuerpo.owner = _duenyo(raiz)
	forma.owner = _duenyo(raiz)
	return cuerpo


static func marcador(raiz: Node, nombre: String, pos: Vector2) -> void:
	var m := Marker2D.new()
	m.name = nombre
	m.position = pos
	raiz.add_child(m)
	m.owner = _duenyo(raiz)


static func franja(padre: Node, nombre: String, rect: Rect2, color: Color) -> ColorRect:
	var f := ColorRect.new()
	f.name = nombre
	f.position = rect.position
	f.size = rect.size
	f.color = color
	padre.add_child(f)
	f.owner = _duenyo(padre)
	return f


## Poligono de color (siluetas de montanas, etc.) para las ambientaciones placeholder.
static func poligono(padre: Node, nombre: String, puntos: PackedVector2Array,
		color: Color) -> Polygon2D:
	var poli := Polygon2D.new()
	poli.name = nombre
	poli.polygon = puntos
	poli.color = color
	padre.add_child(poli)
	poli.owner = _duenyo(padre)
	return poli


## Plataforma de UN SOLO SENTIDO con su visual: cuerpo estatico en la capa Ground mas un
## [ColorRect] del tamano exacto de la colision y una franja [param color_tope] encima.
## Visual y colision salen del mismo [Rect2], asi que no se pueden desfasar.
## [param rect] viene de [method NivelArena.rect_plataforma].
static func plataforma_una_via(padre: Node, nombre: String, rect: Rect2,
		color_cuerpo: Color, color_tope: Color, nombre_cuerpo: String = "Cuerpo",
		nombre_tope: String = "Tope", grosor_tope: float = 4.0) -> StaticBody2D:
	var cuerpo := cuerpo_estatico(padre, nombre, rect.size, rect.get_center(), true)

	var visual := ColorRect.new()
	visual.name = nombre_cuerpo
	visual.position = -rect.size * 0.5
	visual.size = rect.size
	visual.color = color_cuerpo
	cuerpo.add_child(visual)
	visual.owner = cuerpo.owner

	var tope := ColorRect.new()
	tope.name = nombre_tope
	tope.position = -rect.size * 0.5
	tope.size = Vector2(rect.size.x, grosor_tope)
	tope.color = color_tope
	cuerpo.add_child(tope)
	tope.owner = cuerpo.owner
	return cuerpo


static func guardar(raiz: Node, ruta: String) -> bool:
	var escena := PackedScene.new()
	var err := escena.pack(raiz)
	if err != OK:
		printerr("  pack(%s) -> %s" % [ruta, error_string(err)])
		return false
	err = ResourceSaver.save(escena, ruta)
	print("  escena %s -> %s" % [ruta, error_string(err)])
	if err != OK:
		return false
	_quitar_unique_ids(ruta)
	return true


## Sin los unique_id, regenerar no deja cambios falsos en git.
static func _quitar_unique_ids(ruta: String) -> void:
	var regex := RegEx.new()
	regex.compile(" unique_id=\\d+")
	var original := FileAccess.get_file_as_string(ruta)
	var limpio := regex.sub(original, "", true)
	if limpio == original:
		return
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		printerr("  no se pudo limpiar %s" % ruta)
		return
	archivo.store_string(limpio)
	archivo.close()


## Dueno de la escena: la raiz si el padre es ella, o el dueno ya fijado del padre
## (para nodos anidados, p.ej. una plataforma dentro de "Plataformas").
static func _duenyo(nodo: Node) -> Node:
	return nodo.owner if nodo.owner != null else nodo
