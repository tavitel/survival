class_name CommonWalker
extends CharacterBody2D
## Базовый класс сущности, которая ходит по плиточной карте.
## Реализует интерфейс Walkable: проверка проходимости клеток в двух вариантах —
## дискретном (клеточном) и непрерывном (по хитбоксу).
##
## Игрок наследуется от него напрямую; будущие мобы — тоже (или получают
## проходимость через свой компонент ИИ, спрашивая map.is_cell_walkable()).

@export var map: GameGrid = null
@export var walk_speed := Config.PLAYER_SPEED_WALK
@export var run_speed := Config.PLAYER_SPEED_RUN
@export var can_run := true

enum Facing { DOWN = 0, LEFT = 1, RIGHT = 2, UP = 3 }

var facing: int = Facing.DOWN
var moving := false


# ------------------------------------------------------------- Walkable -----

func get_cell() -> Vector2i:
	if map == null:
		return Vector2i.ZERO
	return map.world_to_cell(global_position)


func get_map() -> GameGrid:
	return map


## Дискретная проверка: можно ли сущности занять клетку cell.
func can_enter_cell(cell: Vector2i) -> bool:
	if map == null:
		return false
	# Вышли за пределы поля ("клетки нет") — идти туда нельзя.
	if not map.in_bounds(cell):
		return false
	return map.is_cell_walkable(cell)


## Можно ли в клетке находиться (стоять). Для базового хока совпадает с входом.
func can_occupy_cell(cell: Vector2i) -> bool:
	return can_enter_cell(cell)


# ---------------------------------------------------------------- движение --

## Непрерывная проверка: можно ли телу (хитбоксу) находиться в точке pos.
## Проверяются все клетки, которых касается прямоугольник тела.
func can_stand_at(pos: Vector2) -> bool:
	if map == null:
		return false
	var shape := _body_rect(pos)
	var c0: Vector2i = map.world_to_cell(shape.position)
	var c1: Vector2i = map.world_to_cell(shape.end - Vector2.ONE)
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			if not can_enter_cell(Vector2i(cx, cy)):
				return false
	return true


func current_speed() -> float:
	return run_speed if (can_run and Input.is_action_pressed("run")) else walk_speed


## Расчёт velocity из input_dir с учётом проходимости (скольжение вдоль стен).
func apply_movement(input_dir: Vector2, delta: float) -> void:
	moving = input_dir.length_squared() > 0.01
	if moving:
		input_dir = input_dir.normalized()
		facing = _dir_to_facing(input_dir)
	velocity = input_dir * current_speed()

	if not moving:
		move_and_slide()
		return

	var old_pos := global_position
	move_and_slide()
	# Если упёрлись — попробовали проскользнуть вдоль стены (move_and_slide
	# делает это сам); дополнительно проверяем, не "застряли" ли в непроходимой
	# клетке (например, карта изменилась под ногами), и откатываемся.
	if not can_stand_at(global_position):
		global_position = old_pos
		velocity = Vector2.ZERO


func _dir_to_facing(dir: Vector2) -> int:
	if absf(dir.x) > absf(dir.y):
		return Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
	return Facing.DOWN if dir.y > 0.0 else Facing.UP


func _body_rect(pos: Vector2) -> Rect2:
	var half := Vector2(6, 4)  # полуразмер "ногой" зоны (нижняя часть спрайта)
	var center := pos + Vector2(0, 6)
	return Rect2(center - half, half * 2.0)
