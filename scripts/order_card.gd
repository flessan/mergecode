class_name OrderCard
extends PanelContainer
## One customer order. Deliver is enabled only when the board holds every
## required item; delivering consumes the items and pays coins + XP.

signal deliver_requested(index: int)
signal dismiss_requested(index: int)

var order_index: int = -1
var _req_label: Label
var _deliver_btn: Button

func setup(p_index: int) -> void:
	order_index = p_index
	_build()
	refresh(null)

func _build() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 14))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)
	var head := HBoxContainer.new()
	vbox.add_child(head)
	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(44, 44)
	head.add_child(avatar)
	var who := VBoxContainer.new()
	head.add_child(who)
	who.add_child(UiStyle.label("", 14, UiStyle.INK))      # name (set in refresh via meta below)
	who.add_child(UiStyle.label("", 11, UiStyle.MUTED))    # role
	set_meta("avatar", avatar)
	set_meta("name_label", who.get_child(0))
	set_meta("role_label", who.get_child(1))
	_req_label = UiStyle.label("", 13, UiStyle.INK)
	vbox.add_child(_req_label)
	var reward := UiStyle.label("", 12, UiStyle.MUTED)
	vbox.add_child(reward)
	set_meta("reward_label", reward)
	_deliver_btn = UiStyle.make_button("Deliver Order", UiStyle.GREEN)
	_deliver_btn.pressed.connect(func() -> void: deliver_requested.emit(order_index))
	vbox.add_child(_deliver_btn)
	var dismiss := UiStyle.make_button("Dismiss (new customer)", Color("B9AC97"), 12)
	dismiss.custom_minimum_size = Vector2(0, 30)
	dismiss.pressed.connect(func() -> void: dismiss_requested.emit(order_index))
	vbox.add_child(dismiss)

func refresh(board: Board) -> void:
	if order_index < 0 or order_index >= GameStateStore.instance.orders.size():
		return
	var order: Dictionary = GameStateStore.instance.orders[order_index]
	(get_meta("name_label") as Label).text = str(order.get("customer_name", "Customer"))
	(get_meta("role_label") as Label).text = str(order.get("customer_role", ""))
	(get_meta("reward_label") as Label).text = "Reward: %d coins  •  %d XP" % [int(order.get("reward_coins", 0)), int(order.get("reward_xp", 0))]
	var avatar := get_meta("avatar") as PanelContainer
	avatar.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(order.get("customer_color", "4A90D9"))).lightened(0.25), 10))
	for child in avatar.get_children():
		child.queue_free()
	var initials := UiStyle.label(str(order.get("customer_initials", "?")), 15, Color.WHITE)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(initials)
	var lines: Array = []
	var can_fulfill := board != null
	for item_id in order.get("requirements", {}):
		var need := int(order["requirements"][item_id])
		var have := board.item_count(str(item_id)) if board else 0
		lines.append("%s  %d/%d" % [ItemDatabase.instance.item_name(str(item_id)), mini(have, need), need])
		if have < need:
			can_fulfill = false
	_req_label.text = "Wants:\n" + "\n".join(lines)
	_deliver_btn.disabled = not can_fulfill
