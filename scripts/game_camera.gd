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


## Мгновенная привязка камеры к цели (при старте/телепорте игрока).
func snap() -> void:
	if target == null or _bounds.size == Vector2.ZERO:
		return
	global_position = _clamped_target_pos()


func _process(delta: float) -> void:
	if target == null or _bounds.size == Vector2.ZERO:
		return
	global_position = global_position.lerp(_clamped_target_pos(), clampf(follow_speed * delta, 0.0, 1.0))


func _clamped_target_pos() -> Vector2:
	var limit := Vector2(edge_tiles * Config.TILE_SIZE.x, edge_tiles * Config.TILE_SIZE.y)
	var lo := _bounds.position + limit
	var hi := _bounds.end - limit
	var want := target.global_position
	# Ограничиваем центр камеры так, чтобы он не выходил за [lo, hi].
	# Если поле меньше окна обзора по какой-то оси — центрируем по этой оси.
	want.x = clampf(want.x, minf(lo.x, hi.x), maxf(lo.x, hi.x))
	want.y = clampf(want.y, minf(lo.y, hi.y), maxf(lo.y, hi.y))
	return want
