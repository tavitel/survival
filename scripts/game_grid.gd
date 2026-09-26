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
const ATLAS_SOURCE_PATH := "res://assets/tiles/grass_atlas.png"
const FALLBACK_TEXTURE_PATH := "res://assets/tiles/missing_tile.png"

@export var tile_size: Vector2i = Config.TILE_SIZE
@export var map_size: Vector2i = Config.MAP_SIZE

var _cells := {}                 # Vector2i -> int (id тайла)
var _tile_set: TileSet
var _layer: TileMapLayer


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
func is_cell_walkable(cell: Vector2i) -> bool:
	return TileDB.is_walkable(get_tile(cell))


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

## Заполняет всё поле 64x64. Пример процедурной генерации: трава, каменные
## россыпи и озеро (вода непроходима). Позже заменяется на карту из файла.
func _fill_map() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 20260926
	for y in range(map_size.y):
		for x in range(map_size.x):
			var cell := Vector2i(x, y)
			var id := TileDB.GRASS
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
	for cell in _cells.keys():
		_place(cell)


## Ставит тайл клетки на визуальный слой; если атлас не найден в тайлсете —
## подставляется прозрачная плитка-заглушка (FALLBACK_TILE_ATLAS).
func _place(cell: Vector2i) -> void:
	var tile_id := get_tile(cell)
	var atlas_coords := Vector2i(TileDB.atlas_of(tile_id), 0)
	if not _has_atlas(atlas_coords):
		atlas_coords = Vector2i(Config.FALLBACK_TILE_ATLAS, 0)
	_layer.set_cell(cell, atlas_coords.x, Vector2i(atlas_coords.y, 0))


func _has_atlas(atlas_coords: Vector2i) -> bool:
	if _tile_set == null:
		return false
	for i in range(_tile_set.get_source_count()):
		var sid := _tile_set.get_source_id(i)
		var src := _tile_set.get_source(sid) as TileSetAtlasSource
		if src and src.has_atlas_tile(atlas_coords):
			return true
	return false


func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < map_size.x and cell.y < map_size.y


static func _load_or_null(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("GameGrid: ресурс не найден: %s" % path)
		return null
	var res := load(path)
	return res as Texture2D
