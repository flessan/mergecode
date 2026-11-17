class_name OrderCard
extends PanelContainer
## Visual customer order: character portrait (original artwork), wanted
## items as icons with progress badges, coin reward, Deliver button.
## Items can also be dragged straight from the board onto the card to
## hand them over one at a time (fulfilled counts persist in the order).

signal deliver_requested(index: int)
signal dismiss_requested(index: int)
signal item_dropped(index: int, from_cell: int)

const COIN_ICON := "res://assets/sprites/game_icons/lorc_crown-coin.svg"
const CHECK_ICON := "res://assets/sprites/game_icons/delapouite_check-mark.svg"

var order_index: int = -1
var _portrait: TextureRect
var _name_label: Label
var _wants_row: HBoxContainer
var _state_label: Label
var _deliver_btn: Button

func setup(p_index: int) -> void:
	order_index = p_index
	_build()
	refresh(null)

func _build() -> void:
	custom_minimum_size = Vector2(248, 0)
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 14))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	add_child(hbox)
	_portrait = UiStyle.icon_rect("", Vector2(62, 62), Color.WHITE)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(_portrait)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(vbox)
	_name_label = UiStyle.label("", 13, UiStyle.INK)
	vbox.add_child(_name_label)
	_wants_row = HBoxContainer.new()
	_wants_row.add_theme_constant_override("separation", 5)
	vbox.add_child(_wants_row)
	_state_label = UiStyle.label("", 11, UiStyle.MUTED)
	vbox.add_child(_state_label)
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 4)
	vbox.add_child(reward_row)
	reward_row.add_child(UiStyle.icon_rect(COIN_ICON, Vector2(15, 15), UiStyle.hex("E8A33D")))
	var reward := UiStyle.label("", 12, UiStyle.INK)
	reward_row.add_child(reward)
	set_meta("reward_label", reward)
	var star := UiStyle.label("", 11, UiStyle.MUTED)
	reward_row.add_child(star)
	set_meta("xp_label", star)
	_deliver_btn = UiStyle.make_icon_button(CHECK_ICON, "Deliver", UiStyle.GREEN, 13)
	_deliver_btn.custom_minimum_size = Vector2(0, 34)
	_deliver_btn.pressed.connect(func() -> void: deliver_requested.emit(order_index))
	vbox.add_child(_deliver_btn)
	var dismiss := UiStyle.make_button("New customer", Color("B9AC97"), 11)
	dismiss.custom_minimum_size = Vector2(0, 26)
	dismiss.pressed.connect(func() -> void: dismiss_requested.emit(order_index))
	vbox.add_child(dismiss)

func refresh(board: Board) -> void:
	if order_index < 0 or order_index >= GameStateStore.instance.orders.size():
		return
	var order: Dictionary = GameStateStore.instance.orders[order_index]
	var customer := ItemDatabase.instance.customer_by_id(str(order.get("customer_id", "")))
	_portrait.texture = UiStyle.load_tex(str(customer.get("portrait", "")))
	_name_label.text = str(order.get("customer_name", "Customer")).split(" the ")[0]
	_name_label.tooltip_text = "%s — %s" % [str(order.get("customer_name", "")), str(order.get("customer_role", ""))]
	(get_meta("reward_label") as Label).text = "%d" % int(order.get("reward_coins", 0))
	(get_meta("xp_label") as Label).text = "• %d XP" % int(order.get("reward_xp", 0))
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
	_state_label.text = "Ready to deliver!" if all_ready else "Drag items here or use Deliver"
	_state_label.add_theme_color_override("font_color", UiStyle.GREEN if all_ready else UiStyle.MUTED)
	_deliver_btn.disabled = not all_ready

func _want_chip(item_id: String, have: int, need: int, done: bool) -> Control:
	var def := ItemDatabase.instance.get_item(item_id)
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(46, 46)
	var bg := UiStyle.hex(str(def.get("color", "999999"))).lightened(0.05)
	chip.add_theme_stylebox_override("panel", UiStyle.panel_style(bg, 10, UiStyle.GREEN if done else Color(0, 0, 0, 0.10)))
	chip.tooltip_text = "%s: %d/%d" % [ItemDatabase.instance.item_name(item_id), have, need]
	var icon := UiStyle.icon_rect(str(def.get("icon", "")), Vector2(30, 30), Color.WHITE)
	chip.add_child(icon)
	var badge := UiStyle.label("%d/%d" % [have, need], 10, Color.WHITE)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	chip.add_child(badge)
	return chip

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
