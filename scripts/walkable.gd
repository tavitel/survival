class_name Walkable
extends RefCounted
## Абстрактный маркер "сущность может ходить по клеткам".
##
## Любая сущность, которой нужна проверка проходимости клеток (игрок, мобы, NPC),
## реализует этот интерфейс. Мобе достаточно наследовать CommonWalker (или сам
## интерфейс) — тогда его ИИ сможет спрашивать "можно ли мне шагнуть в клетку",
## не зная ничего о том, кто именно это считает.
##
## Реализующие классы ОБЯЗАНЫ переопределить:
##   can_enter_cell(cell)  - можно ли войти в клетку
##   can_occupy_cell(cell) - можно ли в ней находиться/стоять
##
## ВАЖНО: метод get_map() НЕ объявлен здесь как абстрактный, т.к. RefCounted
## не поддерживает virtual/abstract. Динамическая типизация GDScript позволяет
## вызвать map = entity.get_map() у любого объекта, где этот метод определён
## (Player, Mob, ...). При вызове у объекта без такого метода будет ошибка —
## поэтому все пользователи интерфейса должны также реализовать get_map().

## Клетка, в которой сущность стоит сейчас.
func get_cell() -> Vector2i:
	assert(false, "Walkable.get_cell() должен быть переопределён")
	return Vector2i.ZERO


## Карта (GameGrid), по которой ходит сущность. Требуется от реализации.
func get_map() -> GameGrid:
	assert(false, "Walkable.get_map() должен быть переопределён")
	return null


## Можно ли войти в клетку cell.
func can_enter_cell(_cell: Vector2i) -> bool:
	assert(false, "Walkable.can_enter_cell() должен быть переопределён")
	return false


## Можно ли находиться в клетке cell.
func can_occupy_cell(_cell: Vector2i) -> bool:
	assert(false, "Walkable.can_occupy_cell() должен быть переопределён")
	return false
