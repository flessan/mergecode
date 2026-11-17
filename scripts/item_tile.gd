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
var _name_label: Label
var _pips: HBoxContainer

func setup(p_item_id: String, p_cell: int) -> void:
	item_id = p_item_id
	cell_index = p_cell
	_build()

func _def() -> Dictionary:
	return ItemDatabase.instance.get_item(item_id)

var _compact: bool = false

func _tile_style(highlight: bool = false, ok: bool = true, selected: bool = false) -> StyleBoxFlat:
	var def := _def()
	var color := UiStyle.hex(str(def.get("color", "4A90D9")))
	var border := rarity_frame(str(def.get("rarity", "Common")))
	if highlight:
		border = UiStyle.GREEN if ok else UiStyle.RED
	elif selected:
		border = Color(1, 0.85, 0.3)
	var s := UiStyle.panel_style(color.lightened(0.58), 12, border)
	s.set_border_width_all(4 if (highlight or selected) else 2)
	# Padding shrinks with the cell so content never forces the tile bigger
	# than the board's measured cell size.
	s.set_content_margin_all(2.0 if _compact else 6.0)
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
	var def_color := UiStyle.hex(str(def.get("color", "4A90D9")))
	var plate := PanelContainer.new()
	plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plate.mouse_filter = MOUSE_FILTER_IGNORE
	var plate_style := UiStyle.panel_style(Color(1, 1, 1, 0.55), 9, Color(0, 0, 0, 0.04))
	plate_style.set_content_margin_all(3.0)
	plate.add_theme_stylebox_override("panel", plate_style)
	vbox.add_child(plate)
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2.ZERO, def_color.darkened(0.12))
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plate.add_child(icon)
	_name_label = UiStyle.label(str(def.get("name", item_id)), 9, UiStyle.INK)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = MOUSE_FILTER_IGNORE
	_name_label.clip_text = true
	vbox.add_child(_name_label)
	# Tier pips: one gold dot per tier (crafted items get a single star dot).
	var tier := int(def.get("tier", 0))
	_pips = HBoxContainer.new()
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.add_theme_constant_override("separation", 2)
	_pips.mouse_filter = MOUSE_FILTER_IGNORE
	vbox.add_child(_pips)
	var pip_count := tier if tier > 0 else 1
	for i in mini(pip_count, 8):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(5, 5)
		var ds := StyleBoxFlat.new()
		ds.bg_color = UiStyle.hex("FFD94A") if tier > 0 else UiStyle.hex("FFFFFF")
		ds.set_corner_radius_all(3)
		dot.add_theme_stylebox_override("panel", ds)
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		_pips.add_child(dot)


func set_compact(compact: bool) -> void:
	# On small cells the illustration stays dominant and padding shrinks;
	# tier/name details remain in the selection bar and tooltip.
	_compact = compact
	if _name_label:
		_name_label.visible = not compact
	if _pips:
		_pips.visible = not compact
	add_theme_stylebox_override("panel", _tile_style())

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
	preview.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(def.get("color", "4A90D9"))).lightened(0.58), 12, Color.WHITE))
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2(56, 56), UiStyle.hex(str(def.get("color", "4A90D9"))).darkened(0.12))
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
		var cell := get_parent()
		if cell and cell.get_parent() and cell.get_parent().has_method("clear_highlights"):
			cell.get_parent().clear_highlights()
