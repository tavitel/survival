class_name Inventory
extends RefCounted
## Инвентарь в стиле Minecraft:
##   * слоты 0..HOTBAR_SLOTS-1            — хотбар (быстрый доступ, клавиши 1-9);
##   * слоты HOTBAR_SLOTS..(все)          — основной инвентарь (3 ряда по 9);
##   * ровно один предмет «в руке»        — выбранный слот хотбара;
##   * стек-мердж одинаковых предметов, стаки до ItemDB.max_stack.
##
## Выбранный слот хранится здесь же (selected), чтобы игрок, UI и рубка
## читали «предмет в руке» из одного места.

signal changed

var hotbar_slots: int = Config.HOTBAR_SLOTS
var main_rows: int = Config.INV_ROWS
var slots: Array[ItemStack] = []
var selected: int = 0


func _init() -> void:
	resize(hotbar_slots + main_rows * 9)


func total_slots() -> int:
	return slots.size()


func main_start() -> int:
	# Начало основного инвентаря (после хотбара).
	return hotbar_slots


func resize(total: int) -> void:
	while slots.size() < total:
		slots.append(ItemStack.new())
	while slots.size() > total and not slots.back().is_empty():
		slots.pop_back()


func get_slot(i: int) -> ItemStack:
	if i < 0 or i >= slots.size():
		return null
	return slots[i]


## Предмет в руке (из выбранного слота хотбара) или null.
func held() -> ItemStack:
	return get_slot(selected)


func select_slot(i: int) -> void:
	if i < 0 or i >= hotbar_slots or i == selected:
		return
	selected = clampi(i, 0, hotbar_slots - 1)
	changed.emit()


## Кладёт предметы в инвентарь (сначала мержит стаки). Возвращает остаток,
## который не поместился.
func add_item(id: String, count: int = 1) -> int:
	var left := count
	var maxs := ItemDB.max_stack(id)
	# 1) доложить в существующие стаки
	for s in slots:
		if left <= 0:
			break
		if not s.is_empty() and s.id == id and not ItemDB.has_durability(id) \
				and s.count < maxs:
			var move := mini(maxs - s.count, left)
			s.count += move
			left -= move
	# 2) занять пустые слоты
	for i in range(slots.size()):
		if left <= 0:
			break
		if slots[i].is_empty():
			var put := mini(maxs, left)
			slots[i] = ItemStack.make(id, put)
			left -= put
	changed.emit()
	return left


## Убирает до `count` штук предмета `id`. Возвращает реально удалённое число.
func remove_item(id: String, count: int = 1) -> int:
	var removed := 0
	for s in slots:
		if removed >= count:
			break
		if not s.is_empty() and s.id == id:
			var take := mini(s.count, count - removed)
			s.count -= take
			removed += take
			if s.count <= 0:
				s.id = ""
	changed.emit()
	return removed


func count_of(id: String) -> int:
	var n := 0
	for s in slots:
		if not s.is_empty() and s.id == id:
			n += s.count
	return n
