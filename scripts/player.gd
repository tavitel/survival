extends CommonWalker
## Игрок: ввод движения (WASD/стрелки, Shift — бег), анимации спрайт-атласа,
## инвентарь в стиле Minecraft (хотбар + «предмет в руке») и рубка деревьев.
##
## Управление добычей: ЛКМ (или Space) — удар по ближайшему дереву в радиусе
## CHOP_RANGE_TILES; рубить можно только топором, прочность топора расходуется.

@onready var _sprite: AnimatedSprite2D = $Sprite

const SPRITE_SHEET := "res://assets/sprites/player.png"
const FRAME_SIZE := Vector2i(16, 20)   # размер одного кадра в атласе
const FRAMES_PER_DIR := 3
const WALK_FPS := 8.0                  # кадров/сек при ходьбе

# Порядок рядов в атласе совпадает с Facing: down, left, right, up
const DIRS := ["down", "left", "right", "up"]

var inventory: Inventory = null
var ui: GameUI = null

var _chop_cooldown := 0.0
var _swing_time := 0.0     # длительность визуального «замаха»


func _ready() -> void:
	_build_animations()
	if map == null:
		# Если карта не назначена в редакторе — ищем GameGrid по группе.
		map = get_tree().get_first_node_in_group("grid_map") as GameGrid
	_place_at_start()

	if inventory == null:
		inventory = Inventory.new()
	# Стартовый набор: топор в первом слоте хотбара (выживанию нужен инструмент).
	inventory.add_item(ItemDB.AXE, 1)
	inventory.select_slot(0)


func _physics_process(delta: float) -> void:
	_chop_cooldown = maxf(0.0, _chop_cooldown - delta)
	_swing_time = maxf(0.0, _swing_time - delta)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Пока открыт инвентарь — персонаж стоит.
	if ui != null and ui.panel_visible():
		input_dir = Vector2.ZERO
	apply_movement(input_dir, delta)
	_update_animation()
	_update_swing()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			if inventory:
				inventory.select_slot(k - KEY_1)   # цифры 1-9 = слоты хотбара
			return
		if k == KEY_E:
			if ui:
				ui.toggle_panel()                  # E — открыть/закрыть инвентарь
			return
		if k == KEY_SPACE:
			_try_chop()                            # Space — тоже удар
			return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_try_chop()                        # ЛКМ — рубать
			MOUSE_BUTTON_WHEEL_UP:
				if inventory:
					inventory.select_slot((inventory.selected - 1 + Config.HOTBAR_SLOTS) % Config.HOTBAR_SLOTS)
			MOUSE_BUTTON_WHEEL_DOWN:
				if inventory:
					inventory.select_slot((inventory.selected + 1) % Config.HOTBAR_SLOTS)


# ------------------------------------------------------------------- рубка --

## Удар топором по ближайшему дереву в радиусе досягаемости.
func _try_chop() -> void:
	if _chop_cooldown > 0.0 or inventory == null or map == null:
		return
	var held := inventory.held()
	if held == null or held.id != ItemDB.AXE:
		return          # рубить можно только топором
	if held.durability <= 0:
		return          # топор сломан

	var target := _nearest_tree_in_range()
	if target == null:
		return

	_chop_cooldown = Config.CHOP_COOLDOWN
	_swing_time = 0.18
	facing = _dir_to_facing((target.global_position - global_position).normalized())

	target.hit(ItemDB.damage_of(ItemDB.AXE))
	held.durability = maxi(0, held.durability - 1)
	inventory.changed.emit()


func _nearest_tree_in_range() -> GameTree:
	var best: GameTree = null
	var best_d := Config.CHOP_RANGE_TILES * float(Config.TILE_SIZE.x)
	for node in get_tree().get_nodes_in_group("harvestables"):
		var t := node as GameTree
		if t == null or not is_instance_valid(t):
			continue
		# Считаем расстояние до основания дерева (клетки), а не до верхушки.
		var d := global_position.distance_to(t.global_position + Vector2(0, 16))
		if d < best_d:
			best_d = d
			best = t
	return best


# --------------------------------------------------------------- анимация ---

func _update_animation() -> void:
	var frames := _sprite.sprite_frames
	if frames == null:
		return
	var anim: String = "idle_" + DIRS[facing]
	if moving:
		anim = "walk_" + DIRS[facing]
	# Анимация ещё не построена (первый кадр) — ждём, ошибок быть не должно.
	if not frames.has_animation(anim):
		return
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)


## Лёгкий визуальный «замах»: спрайт наклоняется в сторону удара топором.
func _update_swing() -> void:
	if _swing_time > 0.0:
		var lean := -14.0 if facing == Facing.LEFT else 14.0
		_sprite.rotation_degrees = lean * (_swing_time / 0.18)
	else:
		_sprite.rotation_degrees = 0.0


## Стартовая позиция: первая проходная клетка у левого верхнего угла.
func _place_at_start() -> void:
	if map == null:
		return
	for y in range(map.map_size.y):
		for x in range(map.map_size.x):
			var cell := Vector2i(x, y)
			if can_occupy_cell(cell):
				global_position = map.cell_to_world(cell)
				return
	global_position = map.cell_to_world(Vector2i(0, 0))


## Программно нарезает кадры из атласа и создаёт анимации idle/walk x 4 стороны.
func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_sprite.sprite_frames = frames

	var sheet := load(SPRITE_SHEET) as Texture2D
	if sheet == null:
		push_warning("Player: не найден атлас персонажа %s" % SPRITE_SHEET)
		return

	for row in range(DIRS.size()):
		var dir_name: String = DIRS[row]
		# --- idle: один кадр (первый в ряду) ---
		frames.add_animation("idle_" + dir_name)
		frames.set_animation_loop("idle_" + dir_name, false)
		frames.add_frame("idle_" + dir_name, _region(sheet, row, 0))
		# --- walk: три кадра шага по кругу ---
		frames.add_animation("walk_" + dir_name)
		frames.set_animation_loop("walk_" + dir_name, true)
		frames.set_animation_speed("walk_" + dir_name, WALK_FPS)
		for col in range(FRAMES_PER_DIR):
			frames.add_frame("walk_" + dir_name, _region(sheet, row, col))

	_sprite.play("idle_down")


func _region(sheet: Texture2D, row: int, col: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(col * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)
	return atlas
