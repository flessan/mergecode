class_name OrderCard
extends PanelContainer
## Compact image-first customer: portrait, wanted-item chips with
## progress badges, coin reward and one Deliver action. Readiness is
## shown by the green tint + enabled Deliver (details in the tooltip),
## not by a permanent text line. Items can also be dragged straight
## from the board onto the card (fulfilled counts persist).

signal deliver_requested(index: int)
signal dismiss_requested(index: int)
signal item_dropped(index: int, from_cell: int)

const COIN_ICON := "res://assets/sprites/game_icons/lorc_crown-coin.svg"
const CHECK_ICON := "res://assets/sprites/game_icons/delapouite_check-mark.svg"

var order_index: int = -1
var _portrait: TextureRect
var _name_label: Label
var _reward_label: Label
var _wants_row: HBoxContainer
var _deliver_btn: Button
var _compact: bool = false
var _board_ref: Board

func setup(p_index: int) -> void:
	order_index = p_index
	_build()
	refresh(_board_ref)

func _build() -> void:
	custom_minimum_size = Vector2(236, 0)
	add_theme_stylebox_override("panel", UiStyle.Kenney_texture_style("grey_panel.png", 18.0, 8.0))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	add_child(hbox)
	_portrait = UiStyle.icon_rect("", Vector2(44, 44), Color.WHITE)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_portrait)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 5)
	vbox.add_child(head)
	_name_label = UiStyle.label("", 12, UiStyle.INK)
	head.add_child(_name_label)
	head.add_child(UiStyle.icon_rect(COIN_ICON, Vector2(13, 13), UiStyle.hex("E8A33D")))
	_reward_label = UiStyle.label("", 11, UiStyle.INK)
	head.add_child(_reward_label)
	_wants_row = HBoxContainer.new()
	_wants_row.add_theme_constant_override("separation", 4)
	vbox.add_child(_wants_row)
	var actions := VBoxContainer.new()
	actions.custom_minimum_size = Vector2(74, 0)
	actions.add_theme_constant_override("separation", 3)
	hbox.add_child(actions)
	_deliver_btn = UiStyle.make_Kenney_icon_button(CHECK_ICON, "Deliver", "green", 11)
	_deliver_btn.custom_minimum_size = Vector2(0, 32)
	_deliver_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deliver_btn.pressed.connect(func() -> void: deliver_requested.emit(order_index))
	actions.add_child(_deliver_btn)
	var dismiss := UiStyle.make_Kenney_button("New", "grey", 9, true)
	dismiss.custom_minimum_size = Vector2(0, 24)
	dismiss.tooltip_text = "Replace this customer"
	dismiss.pressed.connect(func() -> void: dismiss_requested.emit(order_index))
	actions.add_child(dismiss)

func refresh(board: Board) -> void:
	if board != null:
		_board_ref = board
	elif _board_ref != null:
		board = _board_ref
	if order_index < 0 or order_index >= GameStateStore.instance.orders.size():
		return
	var order: Dictionary = GameStateStore.instance.orders[order_index]
	var customer := ItemDatabase.instance.customer_by_id(str(order.get("customer_id", "")))
	_portrait.texture = UiStyle.load_tex(str(customer.get("portrait", "")))
	_name_label.text = str(order.get("customer_name", "Customer")).split(" the ")[0]
	_name_label.tooltip_text = "%s - %s" % [str(order.get("customer_name", "")), str(order.get("customer_role", ""))]
	_reward_label.text = "%d  +%d XP" % [int(order.get("reward_coins", 0)), int(order.get("reward_xp", 0))]
	for child in _wants_row.get_children():
		child.queue_free()
	var fulfilled: Dictionary = order.get("fulfilled", {})
	var all_ready := true
	for item_id in order.get("requirements", {}):
		var need := int(order["requirements"][item_id])
		var handed := int(fulfilled.get(str(item_id), 0))
		var on_board := board.item_count(str(item_id)) if board else 0
		var have := mini(need, handed + on_board)
		if handed + on_board < need:
			all_ready = false
		_wants_row.add_child(_want_chip(str(item_id), have, need, handed >= need))
	tooltip_text = "Ready to deliver!" if all_ready else "Drag wanted items here, or use Deliver when ready"
	if all_ready:
		add_theme_stylebox_override("panel", UiStyle.Kenney_texture_style("grey_panel.png", 18.0, 8.0, Color(0.82, 1.0, 0.86, 1.0)))
	else:
		add_theme_stylebox_override("panel", UiStyle.Kenney_texture_style("grey_panel.png", 18.0, 8.0))
	_deliver_btn.disabled = not all_ready

func celebrate() -> void:
	# A quick portrait/card bounce used by Main immediately before payout.
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.045, 1.045), 0.09)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)

func _want_chip(item_id: String, have: int, need: int, done: bool) -> Control:
	var def := ItemDatabase.instance.get_item(item_id)
	var chip := PanelContainer.new()
	var px := 30 if _compact else 34
	chip.custom_minimum_size = Vector2(px, px)
	var bg := UiStyle.hex(str(def.get("color", "999999"))).lightened(0.05)
	chip.add_theme_stylebox_override("panel", UiStyle.panel_style(bg, 9, UiStyle.GREEN if done else Color(0, 0, 0, 0.10)))
	chip.tooltip_text = "%s: %d/%d" % [ItemDatabase.instance.item_name(item_id), have, need]
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2(px - 8, px - 8), Color.WHITE)
	chip.add_child(icon)
	var badge := UiStyle.label("%d/%d" % [have, need], 9, Color.WHITE)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	chip.add_child(badge)
	return chip

func set_compact(compact: bool) -> void:
	# Narrow/short screens: smaller portrait and chips, tighter card.
	_compact = compact
	custom_minimum_size = Vector2(216, 0) if compact else Vector2(236, 0)
	if _portrait:
		_portrait.custom_minimum_size = Vector2(38, 38) if compact else Vector2(44, 44)
	refresh(_board_ref)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or str(data.get("type", "")) != "board_item":
		return false
	if order_index < 0 or order_index >= GameStateStore.instance.orders.size():
		return false
	var order: Dictionary = GameStateStore.instance.orders[order_index]
	var req: Dictionary = order.get("requirements", {})
	var item_id := str(data.get("item_id", ""))
	if not req.has(item_id):
		return false
	var fulfilled: Dictionary = order.get("fulfilled", {})
	return int(fulfilled.get(item_id, 0)) < int(req[item_id])

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		item_dropped.emit(order_index, int(data.get("from_cell", -1)))
