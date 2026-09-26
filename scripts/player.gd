extends CommonWalker
## Игрок: читает ввод (WASD/стрелки, Shift — бег), проецирует движение на карту
## и переключает анимации спрайт-атласа по направлению взгляда.

@onready var _sprite: AnimatedSprite2D = $Sprite

const SPRITE_SHEET := "res://assets/sprites/player.png"
const FRAME_SIZE := Vector2i(16, 20)   # размер одного кадра в атласе
const FRAMES_PER_DIR := 3
const WALK_FPS := 8.0                  # кадров/сек при ходьбе

# Порядок рядов в атласе совпадает с Facing: down, left, right, up
const DIRS := ["down", "left", "right", "up"]


func _ready() -> void:
	_build_animations()
	if map == null:
		# Если карта не назначена в редакторе — ищем GameGrid по группе.
		map = get_tree().get_first_node_in_group("grid_map") as GameGrid
	_place_at_start()


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_movement(input_dir, delta)
	_update_animation()


func _update_animation() -> void:
	var anim: String = "idle_" + DIRS[facing]
	if moving:
		anim = "walk_" + DIRS[facing]
	if _sprite.sprite_frames.has_animation(anim):
		if _sprite.animation != anim or not _sprite.is_playing():
			_sprite.play(anim)
	else:
		_sprite.play("idle_down")


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
