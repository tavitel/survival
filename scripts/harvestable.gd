class_name Harvestable
extends Node2D
## Абстрактный «объект, который можно добыть» (дерево, руда и т.п.).
##
## Сущность хранит клетку карты, на которой стоит, делает её непроходимой
## (через GameGrid.block_cell) и снимает блокировку при удалении. Урон наносится
## методом hit(); когда хп кончается — emit signal depleted и queue_free().
##
## Проходимость для мобов: им достаточно спрашивать map.is_cell_walkable(cell)
## — блокировка клетки общая для всех (см. интерфейс Walkable).

signal depleted(harvestable: Harvestable)

@export var map: GameGrid = null

var cell := Vector2i.ZERO
var hp := 1
var max_hp := 1


func setup(p_map: GameGrid, p_cell: Vector2i) -> void:
	map = p_map
	cell = p_cell


func place() -> void:
	if map == null:
		return
	global_position = map.cell_to_world(cell) + Vector2(0, -Config.TILE_SIZE.y * 0.5)
	map.block_cell(cell, true)
	z_index = int(global_position.y)


func _exit_tree() -> void:
	# При удалении объекта клетка снова становится проходимой.
	if map != null and is_instance_valid(map):
		map.block_cell(cell, false)


## Нанести урон; возвращает true, если объект уничтожен этим ударом.
func hit(damage: int) -> bool:
	hp -= damage
	on_hit()
	if hp <= 0:
		depleted.emit(self)
		queue_free()
		return true
	return false


## Переопределяется потомками: визуальный отклик на удар.
func on_hit() -> void:
	pass


## Что игрок получает при добыче: массив {id, count}.
func drops() -> Array:
	return []
