extends Node
## Реестр предметов игры. Автозагрузка: ItemDB (в коде — `ItemDB`).
##
## Каждый предмет имеет строковый id, имя, тип и параметры:
##   tool        — true: предмет можно держать в руке и использовать (ЛКМ);
##                 для инструментов задаются damage (урон по хп дерева) и durability;
##   stack       — максимальный размер стака;
##   atlas_row   — номер ряда в атласе спрайтов предметов;
##   atlas_col   — столбец: 0 = целый вид, 1 = «сломанный» вид (для инструментов).
##
## Спрайты берутся из res://assets/sprites/items.png (кадры 16x16).

const AXE := "axe"
const LOG := "log"

const SPRITE_SHEET := "res://assets/sprites/items.png"
const FRAME_SIZE := Vector2i(16, 16)

var _defs := {
	AXE: {
		"name": "Топор",
		"tool": true,
		"damage": 1,
		"durability": 20,
		"stack": 1,
		"atlas_row": 0,
	},
	LOG: {
		"name": "Бревно",
		"tool": false,
		"stack": Config.STACK_SIZE,
		"atlas_row": 1,
	},
}


func exists(id: String) -> bool:
	return _defs.has(id)


func name_of(id: String) -> String:
	return String(_defs.get(id, {}).get("name", "?"))


func is_tool(id: String) -> bool:
	return bool(_defs.get(id, {}).get("tool", false))


func max_stack(id: String) -> int:
	return int(_defs.get(id, {}).get("stack", 1))


func has_durability(id: String) -> bool:
	return _defs.get(id, {}).has("durability")


func max_durability(id: String) -> int:
	return int(_defs.get(id, {}).get("durability", 0))


func damage_of(id: String) -> int:
	return int(_defs.get(id, {}).get("damage", 0))


## Иконка предмета: кадр атласа. broken=true — «сломанный» вид (для инструментов).
func icon(id: String, broken: bool = false) -> Texture2D:
	var sheet := load(SPRITE_SHEET) as Texture2D
	if sheet == null:
		push_warning("ItemDB: не найден атлас предметов %s" % SPRITE_SHEET)
		return null
	var row := int(_defs.get(id, {}).get("atlas_row", 0))
	var col := 1 if (broken and is_tool(id)) else 0
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
	return tex
