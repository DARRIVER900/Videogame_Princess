extends SceneTree
## Suite de pruebas headless para los dialogos de Novela Visual.
##
## Ejecutar:
##   godot --headless --script res://tests/test_dialogos.gd
##
## Revisa TODOS los .json de datos/dialogos/, asi que cada capitulo nuevo se
## valida solo. Si cambias un dialogo y esta prueba pasa, el gestor de UI lo
## puede leer.
##
## Salida: codigo 0 si todas pasan, 1 si alguna falla.

const DIR_DIALOGOS := "res://datos/dialogos"
const MIN_LINEAS := 4
## Las unicas claves que lleva cada linea (formato que consume la UI).
const CLAVES := ["speaker", "text", "portrait"]

## Quien puede hablar y con que prefijo empiezan sus retratos.
## Para un personaje nuevo: agregarlo aqui.
const HABLANTES := {
	"Princesa Dulcecito": "dulcecito_",
	"Princesa Chocolatito": "chocolatito_",
}
## Su `nombre` en el juego debe ser igual al de HABLANTES.
const ESCENAS_PRINCESAS := [
	"res://escenas/princesa_dulcecito.tscn",
	"res://escenas/princesa_chocolatito.tscn",
]

var _fallos: int = 0
var _total: int = 0


func _init() -> void:
	_ejecutar()


func _ejecutar() -> void:
	await process_frame
	print("=== Dialogos de Novela Visual ===\n")

	_prueba_nombres_del_juego()

	var archivos := _archivos_json()
	print("-- Archivos de dialogo --")
	_comprobar("hay al menos un archivo en %s" % DIR_DIALOGOS, archivos.size() > 0,
		"%d archivos" % archivos.size())

	var retratos := {}
	for ruta in archivos:
		_prueba_archivo(ruta, retratos)

	var lista: Array = retratos.keys()
	lista.sort()
	print("\nRetratos que necesita la UI: %s" % ", ".join(PackedStringArray(lista)))

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


func _archivos_json() -> PackedStringArray:
	var salida := PackedStringArray()
	for archivo in DirAccess.get_files_at(DIR_DIALOGOS):
		if archivo.ends_with(".json"):
			salida.append("%s/%s" % [DIR_DIALOGOS, archivo])
	salida.sort()
	return salida


func _prueba_nombres_del_juego() -> void:
	print("-- Los hablantes coinciden con los nombres del juego --")
	for ruta in ESCENAS_PRINCESAS:
		var princesa := (load(ruta) as PackedScene).instantiate() as Personaje
		# _ready fija el nombre, asi que se mete al arbol antes de leerlo.
		root.add_child(princesa)
		var nombre_juego: String = princesa.nombre
		princesa.free()
		_comprobar("%s esta en HABLANTES" % ruta.get_file(), HABLANTES.has(nombre_juego),
			"nombre en el juego: '%s'" % nombre_juego)


func _prueba_archivo(ruta: String, retratos: Dictionary) -> void:
	print("-- %s --" % ruta.get_file())
	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(ruta))
	_comprobar("es JSON valido", err == OK,
		"ok" if err == OK else "linea %d: %s" % [json.get_error_line(), json.get_error_message()])
	if err != OK:
		return

	var datos: Variant = json.data
	_comprobar("es una lista de lineas [ ... ]", datos is Array)
	if not datos is Array:
		return
	var lineas: Array = datos
	_comprobar("tiene al menos %d lineas" % MIN_LINEAS, lineas.size() >= MIN_LINEAS,
		"%d lineas" % lineas.size())

	var problemas := PackedStringArray()
	for i in lineas.size():
		var problema := _problema_de_linea(lineas[i])
		if problema == "":
			retratos[(lineas[i] as Dictionary)["portrait"]] = true
		else:
			problemas.append("linea %d: %s" % [i + 1, problema])
	_comprobar("todas las lineas tienen el formato correcto", problemas.is_empty(),
		"ok" if problemas.is_empty() else "; ".join(problemas))


## Devuelve "" si la linea es valida, o que tiene mal.
func _problema_de_linea(linea: Variant) -> String:
	if not linea is Dictionary:
		return "no es un objeto { }"
	var d: Dictionary = linea

	for clave in CLAVES:
		if not d.has(clave):
			return "falta \"%s\"" % clave
		if not (d[clave] is String) or (d[clave] as String).strip_edges() == "":
			return "\"%s\" esta vacio o no es texto" % clave
	for clave in d:
		if not clave in CLAVES:
			return "clave de mas \"%s\" (la UI espera solo %s)" % [clave, ", ".join(PackedStringArray(CLAVES))]

	var hablante: String = d["speaker"]
	if not HABLANTES.has(hablante):
		return "hablante desconocido \"%s\" (si es un personaje nuevo, agregalo a HABLANTES en tests/test_dialogos.gd)" % hablante

	var retrato: String = d["portrait"]
	var regex := RegEx.create_from_string("^[a-z0-9_]+$")
	if regex.search(retrato) == null:
		return "retrato \"%s\" solo puede llevar minusculas, numeros y _" % retrato
	if not retrato.begins_with(HABLANTES[hablante]):
		return "retrato \"%s\" no es de %s (debe empezar con \"%s\")" % [retrato, hablante, HABLANTES[hablante]]
	return ""