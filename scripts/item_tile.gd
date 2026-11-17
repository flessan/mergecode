class_name ItemTile
extends PanelContainer
## One item instance on the board. Definition data comes from ItemDB;
## the tile only stores item_id + cell index. Supports native Godot
## drag-and-drop (mouse + touch) and click-to-select.

signal tile_clicked(tile: ItemTile)

var item_id: String = ""
var cell_index: int = -1
var _name_label: Label
var _short_label: Label
var _tier_label: Label

static func rarity_frame(rarity: String) -> Color:
	match rarity:
		"Uncommon": return UiStyle.hex("6BCB77")
		"Rare": return UiStyle.hex("4A90D9")
		"Epic": return UiStyle.hex("9B6BD9")
		"Legendary", "Crafted": return UiStyle.hex("E8A33D")
		_: return Color(0, 0, 0, 0.08)

func setup(p_item_id: String, p_cell: int) -> void:
	item_id = p_item_id
	cell_index = p_cell
	_build()

func _build() -> void:
	var def := ItemDatabase.instance.get_item(item_id)
	var color := UiStyle.hex(str(def.get("color", "4A90D9")))
	var style := UiStyle.panel_style(color.lightened(0.62), 12, rarity_frame(str(def.get("rarity", "Common"))))
	add_theme_stylebox_override("panel", style)
	tooltip_text = "%s (Tier %s)\n%s" % [str(def.get("name", item_id)), str(def.get("tier", "-")), str(def.get("description", ""))]
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(vbox)
	_short_label = UiStyle.label(str(def.get("short", "?")), 22, color.darkened(0.25))
	_short_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_short_label.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(_short_label)
	_name_label = UiStyle.label(str(def.get("name", item_id)), 10, UiStyle.INK)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(_name_label)
	var tier := int(def.get("tier", 0))
	_tier_label = UiStyle.label(("Tier %d" % tier) if tier > 0 else "Crafted", 9, UiStyle.MUTED)
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tier_label.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(_tier_label)

func set_highlight(active: bool, ok: bool) -> void:
	var def := ItemDatabase.instance.get_item(item_id)
	var color := UiStyle.hex(str(def.get("color", "4A90D9")))
	var border := UiStyle.GREEN if ok else UiStyle.RED
	var style := UiStyle.panel_style(color.lightened(0.45 if active else 0.62), 12, border if active else rarity_frame(str(def.get("rarity", "Common"))))
	add_theme_stylebox_override("panel", style)

func pop_animation() -> void:
	scale = Vector2(0.6, 0.6)
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tile_clicked.emit(self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var def := ItemDatabase.instance.get_item(item_id)
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(76, 76)
	preview.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(def.get("color", "4A90D9"))).lightened(0.4), 12))
	var l := UiStyle.label(str(def.get("short", "?")), 20, UiStyle.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_child(l)
	set_drag_preview(preview)
	modulate = Color(1, 1, 1, 0.45)
	return {"type": "board_item", "from_cell": cell_index, "item_id": item_id}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var cell := get_parent()
	if cell and cell.has_method("_can_drop_data"):
		return cell._can_drop_data(at_position, data)
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var cell := get_parent()
	if cell and cell.has_method("_drop_data"):
		cell._drop_data(at_position, data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate = Color.WHITE
		if get_parent() and get_parent().has_method("clear_highlights"):
			get_parent().clear_highlights()
