class_name TemporizadorCombate
extends Label
## Cuenta regresiva del combate con alerta visual (OUFW-12).
##
## Muestra los segundos restantes en el HUD. Mientras queda mas de
## [member umbral_alerta] se ve blanco; al entrar en los ultimos segundos cambia a
## rojo y late con el pulso del corazon. Al llegar a cero se detiene y emite
## [signal tiempo_agotado] una sola vez.

signal tiempo_agotado

## Segundos de combate. El diseno usa 99, como el HUD de referencia.
@export var duracion: float = 99.0
## Segundos restantes a partir de los cuales el texto se vuelve rojo.
@export var umbral_alerta: float = 5.0

const COLOR_NORMAL := Color(1.0, 1.0, 1.0)
const COLOR_ALERTA := Color("#ff3b3b")

## Tiempo que queda. Se expone para el HUD y las pruebas.
var tiempo_restante: float = 99.0
## Si false, [_process] no descuenta tiempo (dialogos y fin de combate).
var activo: bool = true

var _emito_agotado: bool = false
var _pulso: float = 0.0


func _ready() -> void:
	tiempo_restante = duracion
	_refrescar()


func _process(delta: float) -> void:
	avanzar(delta)
	if activo and en_alerta():
		_pulso += delta * 7.0
		modulate.a = 0.62 + 0.38 * absf(sin(_pulso))
	elif not en_alerta():
		_pulso = 0.0
		modulate.a = 1.0


## Descuenta [param delta] segundos. Publico para que las pruebas no dependan del
## reloj real: llamar directamente mantiene el test determinista.
func avanzar(delta: float) -> void:
	if not activo:
		return
	tiempo_restante = maxf(0.0, tiempo_restante - maxf(delta, 0.0))
	_refrescar()
	if tiempo_restante <= 0.0 and not _emito_agotado:
		_emito_agotado = true
		activo = false
		tiempo_agotado.emit()


## Arranca (o reinicia) la cuenta. Sin argumento conserva [member duracion].
func iniciar(nueva_duracion: float = -1.0) -> void:
	if nueva_duracion > 0.0:
		duracion = nueva_duracion
	tiempo_restante = duracion
	_emito_agotado = false
	activo = true
	_pulso = 0.0
	_refrescar()


func detener() -> void:
	activo = false


func en_alerta() -> bool:
	return tiempo_restante <= umbral_alerta


func _refrescar() -> void:
	text = "%02d" % ceili(tiempo_restante)
	var color := COLOR_ALERTA if en_alerta() else COLOR_NORMAL
	add_theme_color_override("font_color", color)
	modulate.a = 1.0
