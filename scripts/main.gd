extends Node2D
## Главная сцена: собирает карту, игрока и камеру.

@onready var _map: GameGrid = $World/Map
@onready var _player: CommonWalker = $World/Player
@onready var _camera: GameCamera = $World/Player/Camera


func _ready() -> void:
	_player.map = _map
	_camera.setup(_player, _map.world_bounds())
	# Стартовая позиция уже выбрана игроком в _place_at_start — центрируем камеру.
	_camera.global_position = _player.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
