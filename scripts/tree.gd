class_name GameTree
extends Harvestable
## Дерево: сущность на клетке карты. Непроходимо, рубится топором (hit),
## при спиле даёт брёвна (drops) и освобождает клетку.

const SHEET := "res://assets/sprites/tree.png"
const FRAME_W := 32
const FRAME_H := 48
const HIT_FPS := 10.0   # частота кадров «тряски» при ударе

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	max_hp = Config.TREE_HP
	hp = max_hp
	_build_animations()


func on_hit() -> void:
	if _sprite == null:
		return
	# Проигрываем короткий «отклик» (тряска) — кадры 0..2 в ряду 0.
	_sprite.stop()
	_sprite.play("hit")


func drops() -> Array:
	return [{"id": ItemDB.LOG, "count": 2}]


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var sheet := load(SHEET) as Texture2D
	if sheet == null:
		push_warning("GameTree: не найден спрайт %s" % SHEET)
		return
	frames.add_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", HIT_FPS)
	for col in range(3):
		var tex := AtlasTexture.new()
		tex.atlas = sheet
		tex.region = Rect2(col * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("hit", tex)
	# Стоячее дерево — первый кадр (без тряски).
	var still := AtlasTexture.new()
	still.atlas = sheet
	still.region = Rect2(0, 0, FRAME_W, FRAME_H)
	frames.add_animation("idle")
	frames.set_animation_loop("idle", false)
	frames.add_frame("idle", still)
	_sprite.sprite_frames = frames
	_sprite.play("idle")
