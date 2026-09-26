extends SceneTree
## Временный автотест: `godot --headless -s res://tests/test_smoke.gd`
## Проверяет загрузку main.tscn, заполнение поля 64x64, непроходимость воды
## и отсутствие клеток за пределами поля.

func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	# Дать кадрам отработать _ready/_physics_process.
	for i in range(10):
		await process_frame

	var map: GameGrid = scene.get_node("World/Map")
	var player: CommonWalker = scene.get_node("World/Player")
	var cam: GameCamera = scene.get_node("World/Player/Camera")

	var ok := true
	ok = ok and _check(map.get_tile(Vector2i(0, 0)) == TileDB.DIRT, "клетка (0,0) = трава")
	ok = ok and _check(map.get_tile(Vector2i(48, 14)) == TileDB.WATER, "центр озера = вода")
	ok = ok and _check(not map.is_cell_walkable(Vector2i(48, 14)), "вода непроходима")
	ok = ok and _check(not map.in_bounds(Vector2i(-1, 0)), "клетки вне поля нет")
	ok = ok and _check(player.map == map, "игрок привязан к карте")
	ok = ok and _check(cam.target == player, "камера следит за игроком")
	ok = ok and _check(player.can_occupy_cell(player.get_cell()), "игрок стоит на проходимой клетке")
	# Проверка смещения камеры у края: ставим камеру за пределы поля вручную.
	cam.global_position = Vector2(5000, 5000)
	cam._process(1.0)
	var max_c := map.world_bounds().end - Vector2(Config.CAMERA_EDGE_TILES * Config.TILE_SIZE.x, Config.CAMERA_EDGE_TILES * Config.TILE_SIZE.y)
	ok = ok and _check(cam.global_position == max_c, "камера упёрлась в край поля со смещением %s" % str(max_c))
	# В центре поля камера идёт точно за игроком.
	player.global_position = map.cell_to_world(Vector2i(32, 32))
	cam.global_position = player.global_position + Vector2(100, 100)
	cam._process(1.0)
	ok = ok and _check(cam.global_position == player.global_position, "в центре камера следует за игроком")

	print("SMOKE ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _check(cond: bool, msg: String) -> bool:
	print("  [%s] %s" % ["OK" if cond else "!!", msg])
	return cond
