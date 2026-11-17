extends Control
## Merge Code — main gameplay scene. Builds the whole HUD in code:
## top bar (currencies / level / menus), left generators, centre merge board,
## right customer orders, plus modal panels, toasts and autosave.

var board: Board
var popup: MergePopupPanel
var _dim: ColorRect
var _coins_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _gen_cards: Dictionary = {}
var _order_cards: Array = []
var _selected_cell: int = -1
var _selected_box: VBoxContainer
var _selected_title: Label
var _selected_desc: Label
var _sell_btn: Button
var _expand_btn: Button
var _toast: Label
var _dirty: bool = false
var _regen_accum: float = 0.0
var _ui_accum: float = 0.0

func _ready() -> void:
	GameBootstrap.ensure_managers(self)
	_build_ui()
	_connect_signals()
	# Load existing save (chosen in the main menu) or start a fresh workshop.
	var saved_board: Array = []
	if SaveGame.instance.load_existing and GameStateStore.instance.has_save:
		saved_board = SaveGame.instance.load_game()
		board.load_items(saved_board)
	else:
		GameStateStore.instance.reset_new_game()
		board.refresh_locks()
		board.place_item("language_1", -1, false)
		board.place_item("language_1", -1, false)
		board.place_item("editor_1", -1, false)
		board.place_item("editor_1", -1, false)
		_mark_dirty()
	_refresh_all()
	_show_toast("Welcome to your workshop! Tap a generator, then drag matching items together to merge.")

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	_build_hud(root)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)
	_build_generators(body)
	_build_board_area(body)
	_build_orders(body)
	_build_overlay()
	var autosave := Timer.new()
	autosave.wait_time = 10.0
	autosave.autostart = true
	autosave.timeout.connect(_on_autosave_timeout)
	add_child(autosave)

func _build_hud(root: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	root.add_child(panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	panel.add_child(bar)
	var title := UiStyle.label("Merge Code", 22, UiStyle.ACCENT)
	bar.add_child(title)
	_coins_label = UiStyle.label("Coins: 0", 16, UiStyle.INK)
	bar.add_child(_coins_label)
	_level_label = UiStyle.label("Level 1", 16, UiStyle.INK)
	bar.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(140, 16)
	_xp_bar.show_percentage = false
	bar.add_child(_xp_bar)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	for entry in [["Crafting", "craft"], ["Catalog", "catalog"], ["Missions", "missions"], ["Shop", "shop"], ["Help", "help"]]:
		var b := UiStyle.make_button(str(entry[0]), UiStyle.ACCENT)
		b.pressed.connect(_open_popup.bind(str(entry[1])))
		bar.add_child(b)
	var sound_btn := UiStyle.make_button("Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off", Color("B9AC97"))
	sound_btn.pressed.connect(func() -> void:
		GameStateStore.instance.sound_enabled = not GameStateStore.instance.sound_enabled
		sound_btn.text = "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off"
		_mark_dirty())
	bar.add_child(sound_btn)
	var menu_btn := UiStyle.make_button("Main Menu", Color("B9AC97"))
	menu_btn.pressed.connect(func() -> void: _save(); get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	bar.add_child(menu_btn)

func _panel_with_title(parent: Container, title_text: String, min_width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	panel.custom_minimum_size = Vector2(min_width, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	vbox.add_child(UiStyle.label(title_text, 17, UiStyle.INK))
	return vbox

func _build_generators(body: HBoxContainer) -> void:
	var vbox := _panel_with_title(body, "Generators", 250.0)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for gen_id in ItemDatabase.instance.generator_order:
		var card := GeneratorCard.new()
		list.add_child(card)
		card.setup(str(gen_id))
		card.produce_requested.connect(_on_produce)
		card.changed.connect(func() -> void: _mark_dirty(); _refresh_all())
		_gen_cards[str(gen_id)] = card

func _build_board_area(body: HBoxContainer) -> void:
	var vbox := _panel_with_title(body, "Merge Board", 720.0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	header.add_child(UiStyle.label("Drag items together to merge. Click an item for details.", 12, UiStyle.MUTED))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_expand_btn = UiStyle.make_button("Expand Board", UiStyle.GREEN, 13)
	_expand_btn.pressed.connect(_on_expand_board)
	header.add_child(_expand_btn)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	board = Board.new()
	center.add_child(board)
	# Selected item details
	var selected_panel := PanelContainer.new()
	selected_panel.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
	vbox.add_child(selected_panel)
	_selected_box = VBoxContainer.new()
	selected_panel.add_child(_selected_box)
	_selected_title = UiStyle.label("No item selected", 15, UiStyle.INK)
	_selected_box.add_child(_selected_title)
	_selected_desc = UiStyle.label("Click a board item to see its description, source and sell value.", 12, UiStyle.MUTED)
	_selected_box.add_child(_selected_desc)
	_sell_btn = UiStyle.make_button("Sell", UiStyle.RED, 13)
	_sell_btn.disabled = true
	_sell_btn.pressed.connect(_on_sell_selected)
	_selected_box.add_child(_sell_btn)

func _build_orders(body: HBoxContainer) -> void:
	var vbox := _panel_with_title(body, "Customer Orders", 265.0)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for i in GameStateStore.instance.MAX_ORDERS:
		var card := OrderCard.new()
		list.add_child(card)
		card.setup(i)
		card.deliver_requested.connect(_on_deliver)
		card.dismiss_requested.connect(func(index: int) -> void:
			GameStateStore.instance.replace_order(index)
			SoundFx.instance.play("click")
			_mark_dirty()
			_refresh_orders())
		_order_cards.append(card)

func _build_overlay() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.15, 0.1, 0.05, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	add_child(_dim)
	popup = MergePopupPanel.new()
	popup.board = board
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.custom_minimum_size = Vector2(620, 520)
	popup.changed.connect(func() -> void: _mark_dirty(); _refresh_all())
	add_child(popup)
	_toast = UiStyle.label("", 15, Color.WHITE)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.add_theme_stylebox_override("normal", UiStyle.panel_style(UiStyle.INK, 10))
	_toast.visible = false
	add_child(_toast)

func _connect_signals() -> void:
	GameStateStore.instance.coins_changed.connect(func(amount: int) -> void: _coins_label.text = "Coins: %d" % amount)
	GameStateStore.instance.xp_changed.connect(func(xp: int, needed: int, lvl: int) -> void:
		_level_label.text = "Level %d" % lvl
		_xp_bar.max_value = needed
		_xp_bar.value = xp)
	GameStateStore.instance.leveled_up.connect(func(lvl: int) -> void:
		SoundFx.instance.play("levelup")
		_show_toast("Level %d reached! Bonus coins awarded and new content may be unlocked." % lvl)
		_refresh_all())
	GameStateStore.instance.orders_changed.connect(_refresh_orders)
	board.board_changed.connect(func() -> void: _mark_dirty(); _refresh_orders(); _refresh_expand())
	board.item_selected.connect(_on_item_selected)
	board.invalid_action.connect(_show_toast)
	board.merge_performed.connect(func(_cell: int, new_item_id: String) -> void:
		_show_toast("Merged into %s!" % ItemDatabase.instance.item_name(new_item_id)))

func _process(delta: float) -> void:
	_dim.visible = popup.visible
	_regen_accum += delta
	if _regen_accum >= 0.25:
		var step := _regen_accum
		_regen_accum = 0.0
		for gen_id in ItemDatabase.instance.generator_order:
			var state := GameStateStore.instance.generator_state(str(gen_id))
			if bool(state.get("unlocked", false)):
				var max_energy := float(GameStateStore.instance.generator_max_energy(str(gen_id)))
				state["energy"] = minf(max_energy, float(state.get("energy", 0.0)) + step / GameStateStore.instance.generator_regen_seconds(str(gen_id)))
				GameStateStore.instance.generator_states[str(gen_id)] = state
	_ui_accum += delta
	if _ui_accum >= 0.5:
		_ui_accum = 0.0
		for gen_id in _gen_cards:
			_gen_cards[gen_id].refresh()

func _on_produce(gen_id: String) -> void:
	var state := GameStateStore.instance.generator_state(gen_id)
	if not bool(state.get("unlocked", false)):
		return
	if float(state.get("energy", 0.0)) < 1.0:
		_show_toast("Generator is recharging — energy refills over time.")
		SoundFx.instance.play("error")
		return
	if board.find_empty_cell() < 0:
		_show_toast("Board is full! Merge, sell or deliver items, or expand the board.")
		SoundFx.instance.play("error")
		return
	var def: Dictionary = ItemDatabase.instance.generators[gen_id]
	var ids: Array = ItemDatabase.instance.chains.get(str(def.get("chain_id", "")), [])
	if ids.is_empty():
		return
	var item_id := str(ids[0])
	if ids.size() > 1 and randf() < GameStateStore.instance.generator_bonus_chance(gen_id):
		item_id = str(ids[1])
	state["energy"] = float(state.get("energy", 0.0)) - 1.0
	GameStateStore.instance.generator_states[gen_id] = state
	if board.place_item(item_id):
		GameStateStore.instance.bump_stat("generated")
		SoundFx.instance.play("generate")
		_mark_dirty()
	_gen_cards[gen_id].refresh()

func _on_deliver(index: int) -> void:
	if index < 0 or index >= GameStateStore.instance.orders.size():
		return
	var order: Dictionary = GameStateStore.instance.orders[index]
	if not board.has_requirements(order.get("requirements", {})):
		_show_toast("You don't have all the requested items yet.")
		SoundFx.instance.play("error")
		return
	board.consume_requirements(order.get("requirements", {}))
	GameStateStore.instance.complete_order(index)  # pays rewards and issues a fresh order
	SoundFx.instance.play("coin")
	_show_toast("Order delivered! +%d coins, +%d XP" % [int(order.get("reward_coins", 0)), int(order.get("reward_xp", 0))])
	_mark_dirty()
	_refresh_all()

func _on_item_selected(tile: ItemTile) -> void:
	_selected_cell = tile.cell_index
	var def := ItemDatabase.instance.get_item(tile.item_id)
	SoundFx.instance.play("click")
	_selected_title.text = "%s  •  %s  •  Tier %s  •  %s" % [str(def.get("name", tile.item_id)), str(def.get("category", "")), str(def.get("tier", "-")), str(def.get("rarity", ""))]
	var extra := ""
	if str(def.get("source_url", "")) != "":
		extra += "\nSource: " + str(def["source_url"])
	if str(def.get("software_license", "")) != "":
		extra += "\nSoftware license: " + str(def["software_license"])
	extra += "\nArtwork: " + str(def.get("artwork_license", "Original placeholder artwork."))
	_selected_desc.text = str(def.get("description", "")) + extra
	_sell_btn.text = "Sell for %d coins" % int(def.get("sell_value", 0))
	_sell_btn.disabled = false

func _on_sell_selected() -> void:
	if _selected_cell < 0 or not board.cells_items.has(_selected_cell):
		return
	var item_id := str(board.cells_items[_selected_cell])
	var value := int(ItemDatabase.instance.get_item(item_id).get("sell_value", 0))
	board.remove_at(_selected_cell)
	GameStateStore.instance.add_coins(value)
	GameStateStore.instance.bump_stat("items_sold")
	SoundFx.instance.play("coin")
	_show_toast("Sold %s for %d coins." % [ItemDatabase.instance.item_name(item_id), value])
	_selected_cell = -1
	_selected_title.text = "No item selected"
	_selected_desc.text = "Click a board item to see its description, source and sell value."
	_sell_btn.disabled = true
	_mark_dirty()

func _on_expand_board() -> void:
	if GameStateStore.instance.board_cells_unlocked >= GameStateStore.instance.BOARD_MAX_CELLS:
		return
	var cost := GameStateStore.instance.board_expansion_cost()
	if GameStateStore.instance.spend_coins(cost):
		GameStateStore.instance.board_cells_unlocked = mini(GameStateStore.instance.BOARD_MAX_CELLS, GameStateStore.instance.board_cells_unlocked + 7)
		board.refresh_locks()
		SoundFx.instance.play("levelup")
		_show_toast("Board expanded! A new row is unlocked.")
		_mark_dirty()
		_refresh_expand()
	else:
		SoundFx.instance.play("error")
		_show_toast("Not enough coins to expand the board.")

func _open_popup(kind: String) -> void:
	SoundFx.instance.play("click")
	popup.board = board
	match kind:
		"craft": popup.show_crafting()
		"catalog": popup.show_catalog()
		"missions": popup.show_missions()
		"shop": popup.show_shop()
		"help": popup.show_help()

func _refresh_orders() -> void:
	for card in _order_cards:
		card.refresh(board)

func _refresh_expand() -> void:
	if GameStateStore.instance.board_cells_unlocked >= GameStateStore.instance.BOARD_MAX_CELLS:
		_expand_btn.text = "Board fully expanded"
		_expand_btn.disabled = true
	else:
		var cost := GameStateStore.instance.board_expansion_cost()
		_expand_btn.text = "Expand Board (%d)" % cost
		_expand_btn.disabled = GameStateStore.instance.coins < cost

func _refresh_all() -> void:
	_coins_label.text = "Coins: %d" % GameStateStore.instance.coins
	_level_label.text = "Level %d" % GameStateStore.instance.level
	_xp_bar.max_value = GameStateStore.instance.xp_needed_for(GameStateStore.instance.level)
	_xp_bar.value = GameStateStore.instance.xp_into_level
	for gen_id in _gen_cards:
		_gen_cards[gen_id].refresh()
	_refresh_orders()
	_refresh_expand()

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _toast.visible = false)

func _on_autosave_timeout() -> void:
	if _dirty:
		_save()

func _mark_dirty() -> void:
	_dirty = true

func _save() -> void:
	SaveGame.instance.save_game(board.serialize())
	_dirty = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if board:
			_save()
