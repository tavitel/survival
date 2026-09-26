class_name GameUI
extends Control
## Интерфейс в стиле Minecraft: хотбар (9 слотов, цифры 1-9 / колесо мыши),
## «предмет в руке», подсказка и открываемый по E полный инвентарь (3x9).
##
## UI только читает/меняет выбранный слот и перерисовывается по сигналу
## inventory.changed — вся логика хранения живёт в Inventory.

const SLOT_PX := 40
const ICON_PX := 28
const PADDING := 6.0
const FONT_SIZE := 14

var inventory: Inventory = null

var _hotbar: HBoxContainer
var _panel: PanelContainer
var _main_grid: GridContainer
var _held_label: Label
var _hint_label: Label
var _slot_icons: Array[Control] = []   # все визуальные слоты (хотбар + панель)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hotbar()
	_build_panel()
	if inventory != null:
		inventory.changed.connect(_refresh)
	_refresh()


# ------------------------------------------------------------- сборка UI ----

func _build_hotbar() -> void:
	var box := VBoxContainer.new()
	box.name = "Bottom"
	box.alignment = BoxContainer.ALIGNMENT_END
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_held_label = Label.new()
	_held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_held_label.add_theme_font_size_override("font_size", FONT_SIZE + 2)
	_held_label.add_theme_color_override("font_color", Color(1, 1, 0.85))
	box.add_child(_held_label)

	_hint_label = Label.new()
	_hint_label.text = "ЛКМ — рубить дерево · 1-9/колесо — выбор предмета · E — инвентарь"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", FONT_SIZE - 2)
	_hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	box.add_child(_hint_label)

	_hotbar = HBoxContainer.new()
	_hotbar.name = "Hotbar"
	_hotbar.alignment = BoxContainer.ALIGNMENT_CENTER
	_hotbar.add_theme_constant_override("separation", 2)
	box.add_child(_hotbar)

	for i in range(Config.HOTBAR_SLOTS):
		var slot := _make_slot(i)
		_hotbar.add_child(slot)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "InventoryPanel"
	_panel.visible = false
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -SLOT_PX * 4.5 - PADDING
	_panel.offset_right = SLOT_PX * 4.5 + PADDING
	_panel.offset_top = -SLOT_PX * 2.0 - PADDING
	_panel.offset_bottom = SLOT_PX * 2.0 + PADDING
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.92)
	style.border_color = Color(0.5, 0.5, 0.55)
	style.set_border_width_all(2)
	style.set_content_margin_all(PADDING)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "Инвентарь"
	title.add_theme_font_size_override("font_size", FONT_SIZE + 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_main_grid = GridContainer.new()
	_main_grid.columns = 9
	_main_grid.add_theme_constant_override("h_separation", 2)
	_main_grid.add_theme_constant_override("v_separation", 2)
	vb.add_child(_main_grid)

	for i in range(inventory.main_start(), inventory.total_slots()):
		_main_grid.add_child(_make_slot(i))


func _make_slot(index: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.15, 0.15, 0.18, 0.85)
	st.border_color = Color(0.45, 0.45, 0.5)
	st.set_border_width_all(1)
	panel.add_theme_stylebox_override("normal", st)

	var icon := TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)

	var count := Label.new()
	count.name = "Count"
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.offset_left = -ICON_PX
	count.offset_top = -FONT_SIZE - 2
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.add_theme_font_size_override("font_size", FONT_SIZE)
	count.add_theme_color_override("font_color", Color(1, 1, 1))
	count.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	count.add_theme_constant_override("outline_size", 4)
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(count)

	_slot_icons.append(icon)
	panel.meta["slot"] = index
	return panel


# ------------------------------------------------------------ обновление ----

func toggle_panel() -> void:
	_panel.visible = not _panel.visible


func panel_visible() -> bool:
	return _panel.visible


func _refresh() -> void:
	if inventory == null:
		return
	for i in range(_slot_icons.size()):
		var slot_index := _slot_icon_slot(i)
		var stack := inventory.get_slot(slot_index)
		var icon := _slot_icons[i]
		if stack == null or stack.is_empty():
			icon.texture = null
		else:
			var broken := ItemDB.has_durability(stack.id) \
				and stack.durability <= 0
			icon.texture = ItemDB.icon(stack.id, broken)
			var sib := icon.get_parent().get_node_or_null("Count") as Label
			if sib:
				sib.text = str(stack.count) if stack.count > 1 else ""
		# рамка выбранного слота хотбара — белая жирная (как в Minecraft)
		if i < Config.HOTBAR_SLOTS:
			var panel := icon.get_parent() as Panel
			var sb := panel.get_theme_stylebox("normal") as StyleBoxFlat
			if sb:
				sb.border_color = Color(1, 1, 1) if slot_index == inventory.selected \
					else Color(0.45, 0.45, 0.5)
				sb.set_border_width_all(3 if slot_index == inventory.selected else 1)

	var held := inventory.held()
	if held != null and not held.is_empty():
		var extra := ""
		if ItemDB.has_durability(held.id):
			extra = "  [%d/%d]" % [held.durability, ItemDB.max_durability(held.id)]
		_held_label.text = "%s%s" % [ItemDB.name_of(held.id), extra]
	else:
		_held_label.text = "Пустые руки"


func _slot_icon_slot(icon_index: int) -> int:
	# Первые HOTBAR_SLOTS иконок — хотбар; остальные — ячейки панели.
	if icon_index < Config.HOTBAR_SLOTS:
		return icon_index
	return inventory.main_start() + (icon_index - Config.HOTBAR_SLOTS)
