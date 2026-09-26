class_name GameCamera
extends Camera2D
## Камера, следующая за целью с ограничением по границам поля.
##
## Пока цель в центре карты — камера идёт за ней. Когда цель подходит ближе
## чем на edge_tiles плиток к любому краю поля, камера "смещается": её центр
## доупирается в границу (плюс небольшой отступ) и останавливается, а персонаж
## продолжает двигаться к самому краю — то есть экран смещается относительно
## персонажа.

@export var target: Node2D
@export var edge_tiles: int = Config.CAMERA_EDGE_TILES
@export var follow_speed := 12.0   # жёсткость слежения (0 = мгновенно)

var _bounds := Rect2()


func setup(p_target: Node2D, p_bounds: Rect2) -> void:
	target = p_target
	_bounds = p_bounds


func _ready() -> void:
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	if target == null or _bounds.size == Vector2.ZERO:
		return
	var limit := Vector2(edge_tiles * Config.TILE_SIZE.x, edge_tiles * Config.TILE_SIZE.y)
	var lo := _bounds.position + limit
	var hi := _bounds.end - limit
	var want := target.global_position
	# Ограничиваем центр камеры так, чтобы он не выходил за [lo, hi].
	# Если поле меньше окна обзора по какой-то оси — центрируем по этой оси.
	var min_c := minf(lo.x, hi.x)
	var max_c := maxf(lo.x, hi.x)
	want.x = clampf(want.x, min_c, max_c)
	min_c = minf(lo.y, hi.y)
	max_c = maxf(lo.y, hi.y)
	want.y = clampf(want.y, min_c, max_c)
	global_position = global_position.lerp(want, clampf(follow_speed * delta, 0.0, 1.0))
