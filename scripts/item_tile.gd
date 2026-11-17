class_name ItemTile
extends PanelContainer
## One item instance on the board, image-first: the item's illustration
## (downloaded Game-Icons silhouette, tinted white) fills the tile on a
## chain-coloured rounded background, with rarity frame, tier pips and a
## small name caption. Supports native Godot drag-and-drop (mouse + touch)
## and click-to-select.

signal tile_clicked(tile: ItemTile)

var item_id: String = ""
var cell_index: int = -1

func setup(p_item_id: String, p_cell: int) -> void:
	item_id = p_item_id
	cell_index = p_cell
	_build()

func _def() -> Dictionary:
	return ItemDatabase.instance.get_item(item_id)

func _tile_style(highlight: bool = false, ok: bool = true, selected: bool = false) -> StyleBoxFlat:
	var def := _def()
	var color := UiStyle.hex(str(def.get("color", "4A90D9")))
	var border := rarity_frame(str(def.get("rarity", "Common")))
	if highlight:
		border = UiStyle.GREEN if ok else UiStyle.RED
	elif selected:
		border = Color.WHITE
	var s := UiStyle.panel_style(color.lightened(0.05), 12, border)
	s.set_border_width_all(4 if (highlight or selected) else 2)
	return s

static func rarity_frame(rarity: String) -> Color:
	match rarity:
		"Uncommon": return UiStyle.hex("6BCB77")
		"Rare": return UiStyle.hex("4A90D9")
		"Epic": return UiStyle.hex("9B6BD9")
		"Legendary", "Crafted": return UiStyle.hex("E8A33D")
		_: return Color(0, 0, 0, 0.10)

func _build() -> void:
	var def := _def()
	add_theme_stylebox_override("panel", _tile_style())
	tooltip_text = "%s (Tier %s)\n%s" % [str(def.get("name", item_id)), str(def.get("tier", "-")), str(def.get("description", ""))]
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(vbox)
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2(44, 44), Color.WHITE)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(icon)
	var name_label := UiStyle.label(str(def.get("name", item_id)), 9, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = MOUSE_FILTER_IGNORE
	name_label.clip_text = true
	vbox.add_child(name_label)
	# Tier pips: one gold dot per tier (crafted items get a single star dot).
	var tier := int(def.get("tier", 0))
	var pips := HBoxContainer.new()
	pips.alignment = BoxContainer.ALIGNMENT_CENTER
	pips.add_theme_constant_override("separation", 2)
	pips.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(pips)
	var pip_count := tier if tier > 0 else 1
	for i in mini(pip_count, 8):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(6, 6)
		var ds := StyleBoxFlat.new()
		ds.bg_color = UiStyle.hex("FFD94A") if tier > 0 else UiStyle.hex("FFFFFF")
		ds.set_corner_radius_all(3)
		dot.add_theme_stylebox_override("panel", ds)
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		pips.add_child(dot)

func set_highlight(active: bool, ok: bool) -> void:
	add_theme_stylebox_override("panel", _tile_style(active, ok))

func set_selected(selected: bool) -> void:
	add_theme_stylebox_override("panel", _tile_style(false, true, selected))

func pop_animation() -> void:
	# Deferred pivot: the tile only has a real size after layout.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		tile_clicked.emit(self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var def := _def()
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(72, 72)
	preview.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(def.get("color", "4A90D9"))), 12, Color.WHITE))
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2(56, 56), Color.WHITE)
	preview.add_child(icon)
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
