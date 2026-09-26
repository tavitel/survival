extends Node
## Реестр типов тайлов и их свойств (проходимость и пр.).
## Автозагрузка: TileDB (имя синглтона в коде: `TileDB`).
##
## Каждый тип тайла имеет id (int), имя, номер атласа в тайлсете и флаг
## проходимости. Проходимость хранится ЗДЕСЬ (а не в самом тайлсете), чтобы
## и игрок, и будущие мобы проверяли её через один источник истины.

const GRASS := 0
const STONE := 1
const WATER := 2
const MISSING := 3   # отсутствующая клетка карты -> прозрачная плитка-заглушка

var _defs := {
	MISSING: {"name": "missing", "atlas": Config.FALLBACK_TILE_ATLAS, "walkable": true},
	GRASS:   {"name": "grass",   "atlas": 0, "walkable": true},
	STONE:   {"name": "stone",   "atlas": 1, "walkable": true},
	WATER:   {"name": "water",   "atlas": 2, "walkable": false},
}


func exists(id: int) -> bool:
	return _defs.has(id)


func name_of(id: int) -> String:
	return String(_defs.get(id, {}).get("name", "?"))


## Номер атласа тайла внутри тайлсета. Для MISSING возвращает служебный атлас
## заглушки (добавляется в тайлсет программно).
func atlas_of(id: int) -> int:
	return int(_defs.get(id, {}).get("atlas", Config.FALLBACK_TILE_ATLAS))


func is_walkable(id: int) -> bool:
	# Неизвестного типа тайла нет на карте — считаем непроходимым.
	return bool(_defs.get(id, {}).get("walkable", false))
