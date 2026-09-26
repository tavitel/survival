extends Node2D
## Главная сцена: собирает карту, объекты (деревья), игрока, камеру и UI.

@onready var _map: GameGrid = $World/Map
@onready var _objects: Node2D = $World/Objects
@onready var _player: CommonWalker = $World/Player
@onready var _camera: GameCamera = $World/Player/Camera
@onready var _ui: GameUI = $CanvasLayer/UI


func _ready() -> void:
	_player.map = _map
	_camera.setup(_player, _map.world_bounds())

	# Стартовая позиция игрока уже выбрана в _place_at_start; сажаем рядом
	# два дерева (в 2-3 плитках от пути), чтобы было видно ходьбу и что рубить.
	_map.spawn_start_trees(_map.world_to_cell(_player.global_position))

	# Инвентарь игрока + привязка UI (хотбар, «предмет в руке», панель E).
	_ui.inventory = _player.inventory
	_player.ui = _ui

	# Камера мгновенно встаёт за игроком (без стартового «наезда»).
	_camera.snap()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
