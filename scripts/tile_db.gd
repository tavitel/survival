extends Node
## Реестр типов тайлов и их свойств (проходимость и пр.).
## Автозагрузка: TileDB (имя синглтона в коде: `TileDB`).
##
## Каждый тип тайла имеет id (int), имя, номер атласа в тайлсете и флаг
## проходимости. Проходимость хранится ЗДЕСЬ (а не в самом тайлсете), чтобы
## и игрок, и будущие мобы проверяли её через один источник истины.

const DIRT := 0
const STONE := 1
const WATER := 2
const MISSING := 3   # отсутствующая клетка карты -> прозрачная плитка-заглушка

var _defs := {
	MISSING: {"name": "missing", "source": Config.FALLBACK_TILE_ATLAS, "atlas": Vector2i.ZERO, "walkable": true},
	DIRT:    {"name": "dirt",    "source": 0, "atlas": Vector2i(0, 0), "walkable": true},
	STONE:   {"name": "stone",   "source": 0, "atlas": Vector2i(1, 0), "walkable": true},
	WATER:   {"name": "water",   "source": 0, "atlas": Vector2i(2, 0), "walkable": false},
}


func exists(id: int) -> bool:
	return _defs.has(id)


func name_of(id: int) -> String:
	return String(_defs.get(id, {}).get("name", "?"))


## Индекс TileSetAtlasSource, в котором лежит тайл.
func source_of(id: int) -> int:
	return int(_defs.get(id, {}).get("source", Config.FALLBACK_TILE_ATLAS))


## Координаты плитки внутри атласа источника.
func atlas_of(id: int) -> Vector2i:
	return _defs.get(id, {}).get("atlas", Vector2i.ZERO)


func is_walkable(id: int) -> bool:
	# Неизвестного типа тайла нет на карте — считаем непроходимым.
	return bool(_defs.get(id, {}).get("walkable", false))
