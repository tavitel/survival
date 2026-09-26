class_name ItemStack
extends RefCounted
## Стак одинаковых предметов в одном слоте инвентаря.
## Пустой стак: id == "".

var id: String = ""
var count: int = 0
## Прочность инструмента (актуально только если ItemDB.has_durability(id)).
var durability: int = 0


func is_empty() -> bool:
	return id == "" or count <= 0


static func make(p_id: String, p_count: int = 1) -> ItemStack:
	var s := ItemStack.new()
	s.id = p_id
	s.count = p_count
	if ItemDB.has_durability(p_id):
		s.durability = ItemDB.max_durability(p_id)
	return s


## Можно ли докладывать такие же предметы в этот стак.
func can_merge_with(other: ItemStack) -> bool:
	return not is_empty() and not other.is_empty() \
		and id == other.id \
		and not ItemDB.has_durability(id) \
		and count < ItemDB.max_stack(id)


func copy() -> ItemStack:
	var s := ItemStack.new()
	s.id = id
	s.count = count
	s.durability = durability
	return s
