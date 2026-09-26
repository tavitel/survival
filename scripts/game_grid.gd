class_name GameGrid
extends Node2D
## Плиточная карта мира 64x64.
##
## Хранит типы тайлов в клетках и отвечает на вопросы:
##   * что за тайл в клетке (в т.ч. "клетки нет" -> MISSING)
##   * проходима ли клетка (для игрока и, в будущем, для мобов)
##   * преобразование координат мир <-> клетка
##
## Отрисовка — TileMapLayer. Если атлас тайла не найден в тайлсете, вместо него
## подставляется прозрачная плитка-заглушка (см. _place), поэтому поле
## всегда заполнено полностью, даже когда текстур нет.

signal map_ready

const TILESET_PATH := "res://assets/tiles/map_tileset.tres"
const ATLAS_SOURCE_PATH := "res://assets/tiles/landscape_atlas.png"
const FALLBACK_TEXTURE_PATH := "res://assets/tiles/missing_tile.png"
const TREE_SCENE_PATH := "res://scenes/tree.tscn"

@export var tile_size: Vector2i = Config.TILE_SIZE
@export var map_size: Vector2i = Config.MAP_SIZE

var _cells := {}                 # Vector2i -> int (id тайла)
var _blocked := {}               # Vector2i -> true (клетки, перекрытые объектами: деревья)
var _tile_set: TileSet
var _layer: TileMapLayer
var _atlas_landscape: Array[Vector2i] = []   # реально существующие тайлы атласа ландшафта


func _ready() -> void:
	_build_tileset()
	_fill_map()
	_build_layer()
	map_ready.emit()


# ------------------------------------------------------------------ карта ---

## Тип тайла в клетке. Вне карты или если клетка не задана -> MISSING
## (отсутствующая клетка; отображается прозрачной заглушкой).
func get_tile(cell: Vector2i) -> int:
	return int(_cells.get(cell, TileDB.MISSING))


func set_tile(cell: Vector2i, tile_id: int) -> void:
	if not _in_bounds(cell):
		return
	_cells[cell] = tile_id
	if _layer:
		_place(cell)


func has_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


func in_bounds(cell: Vector2i) -> bool:
	return _in_bounds(cell)


## Проходимость клетки — единая точка истины для игрока и будущих мобов.
## Учитывает и тип тайла (вода — нельзя), и объекты, стоящие в клетке
## (деревья блокируют клетку через block_cell).
func is_cell_walkable(cell: Vector2i) -> bool:
	if _blocked.has(cell):
		return false
	return TileDB.is_walkable(get_tile(cell))


## Перекрыть/освободить клетку объектом (дерево, камень-бoulder и т.п.).
func block_cell(cell: Vector2i, blocked := true) -> void:
	if blocked:
		_blocked[cell] = true
	else:
		_blocked.erase(cell)


func is_cell_blocked(cell: Vector2i) -> bool:
	return _blocked.has(cell)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * Vector2(tile_size) + Vector2(tile_size) * 0.5


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2((pos - Vector2(tile_size) * 0.5) / Vector2(tile_size)).floor()


func clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, map_size.x - 1),
		clampi(cell.y, 0, map_size.y - 1),
	)


## Границы поля в мировых координатах (для ограничения камеры).
func world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_size) * Vector2(tile_size))


# ------------------------------------------------------------- генерация ----

## Заполняет всё поле 64x64. Пример процедурной генерации: земля, каменные
## россыпи и озеро (вода непроходима). Позже заменяется на карту из файла.
func _fill_map() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260926
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var id := TileDB.DIRT
			# озеро ближе к правому верхнему углу
			var d_pond := Vector2(cell - Vector2i(48, 14)).length()
			if d_pond < 7.0:
				id = TileDB.WATER
			elif d_pond < 8.5 and rnd.randf() < 0.4:
				id = TileDB.WATER
			# пара каменных россыпей
			elif Vector2(cell - Vector2i(12, 40)).length() < 5.0 and rnd.randf() < 0.7:
				id = TileDB.STONE
			elif Vector2(cell - Vector2i(34, 46)).length() < 4.0 and rnd.randf() < 0.6:
				id = TileDB.STONE
			_cells[cell] = id


## Деревья рядом со стартовой точкой игрока: два дерева в 2-3 плитках от пути,
## чтобы было видно, как персонаж ходит и что можно рубить.
func spawn_start_trees(pivot: Vector2i) -> void:
	var tree_scene := load(TREE_SCENE_PATH) as PackedScene
	if tree_scene == null:
		push_warning("GameGrid: сцена дерева не найдена: %s" % TREE_SCENE_PATH)
		return
	var parent := get_node_or_null("../Objects")
	if parent == null:
		parent = self
	for off in [Vector2i(2, 1), Vector2i(-1, 3)]:
		var cell: Vector2i = pivot + off
		if not _in_bounds(cell) or not is_cell_walkable(cell):
			continue
		var tree := tree_scene.instantiate() as GameTree
		tree.setup(self, cell)
		parent.add_child(tree)
		tree.place()


# ------------------------------------------------------------- отрисовка ----

func _build_tileset() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = tile_size

	var source := TileSetAtlasSource.new()
	source.texture = _load_or_null(ATLAS_SOURCE_PATH)
	source.texture_region_size = tile_size
	if source.texture:
		var cols := int(source.texture.get_width() / float(tile_size.x))
		var rows := int(source.texture.get_height() / float(tile_size.y))
		for r in range(rows):
			for c in range(cols):
				# 4-й аргумент — number_of_tiles (одиночная плитка).
				source.create_tile(Vector2i(c, r), Vector2i.ONE)
		# Запоминаем, какие тайлы реально есть в атласе ландшафта.
		for r in range(rows):
			for c in range(cols):
				_atlas_landscape.append(Vector2i(c, r))
		_tile_set.add_source(source, 0)

	# Служебный источник с прозрачной плиткой-заглушкой (атлас FALLBACK_TILE_ATLAS).
	# Используется, когда нужный атлас не найден в основном тайлсете.
	var fb := TileSetAtlasSource.new()
	fb.texture = _load_or_null(FALLBACK_TEXTURE_PATH)
	fb.texture_region_size = tile_size
	if fb.texture == null:
		# Совсем нет текстуры — создаём пустую прозрачную в рантайме.
		var img := Image.create(tile_size.x, tile_size.y, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		fb.texture = ImageTexture.create_from_image(img)
	fb.create_tile(Vector2i.ZERO, Vector2i.ONE)
	_tile_set.add_source(fb, Config.FALLBACK_TILE_ATLAS)


func _build_layer() -> void:
	_layer = TileMapLayer.new()
	_layer.name = "Tiles"
	_layer.tile_set = _tile_set
	add_child(_layer)
	var keys: Array = _cells.keys()
	for cell in keys:
		_place(cell)


## Ставит тайл клетки на визуальный слой; если атлас не найден в тайлсете —
## подставляется прозрачная плитка-заглушка (FALLBACK_TILE_ATLAS).
func _place(cell: Vector2i) -> void:
	var tile_id := get_tile(cell)
	var src_id: int = TileDB.source_of(tile_id)
	var atlas_coords: Vector2i = TileDB.atlas_of(tile_id)
	if not _has_atlas(src_id, atlas_coords):
		# Атлас не найден в тайлсете — клетку закрываем прозрачной заглушкой.
		src_id = Config.FALLBACK_TILE_ATLAS
		atlas_coords = Vector2i.ZERO
	_layer.set_cell(cell, src_id, atlas_coords)


## Есть ли у конкретного источника тайл с такими координатами атласа.
## Универсально для всех версий Godot/Redot 4.x: у источников из файлов
## (.tres) проверяем через get_tile_data(), а основной атлас ландшафта —
## по списку реально созданных тайлов (_atlas_landscape), т.к. часть методов
## (has_atlas_tile/get_atlas_tiles) появилась только в 4.4+.
func _has_atlas(source_id: int, atlas_coords: Vector2i) -> bool:
	if _tile_set == null:
		return false
	if source_id == 0:
		return _atlas_landscape.has(atlas_coords)
	var src := _tile_set.get_source(source_id) as TileSetAtlasSource
	if src == null:
		return false
	return src.get_tile_data(atlas_coords, 0) != null


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y


static func _load_or_null(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("GameGrid: ресурс не найден: %s" % path)
		return null
	var res := load(path)
	return res as Texture2D
