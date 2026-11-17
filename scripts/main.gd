extends Control
## Merge Code — main gameplay scene (visual redesign).
##
## Board-first layout, all containers/anchors (no fixed three-column widths):
##   HUD (coins / level / sound / menu)
##   Customer strip (horizontal, portraits + wanted item icons)
##   Board (dominant, workbench surface) + generator dock
##   Bottom navigation (Crafting / Shop / Catalog / Missions / Help)
## Layout adapts to viewport: wide screens get a vertical generator dock
## beside the board; narrow/portrait screens get a horizontal generator
## dock under the board and the board cell size is recomputed on resize.

const COIN_ICON := "res://assets/sprites/game_icons/lorc_crown-coin.svg"
const STAR_ICON := "res://assets/sprites/game_icons/lorc_flat-star.svg"
const GEAR_ICON := "res://assets/sprites/game_icons/delapouite_gear-stick.svg"
const CLOSE_ICON := "res://assets/sprites/game_icons/lorc_cross-mark.svg"

var board: Board
var popup: MergePopupPanel
var _dim: ColorRect
var _coins_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _gen_cards: Dictionary = {}
var _gen_grid: GridContainer
var _gen_panel: PanelContainer
var _gen_scroll: ScrollContainer
var _order_cards: Array = []
var _middle: HBoxContainer
var _board_col: VBoxContainer
var _wide_mode: bool = true
var _selected_cell: int = -1
var _selected_icon: PanelContainer
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
	_apply_layout.call_deferred()
	get_tree().root.size_changed.connect(_apply_layout)
	_show_toast("Tap a generator's Make button, then drag matching items together to merge!")

# --- Layout construction -------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := UiStyle.icon_rect("res://assets/backgrounds/workshop.svg", Vector2.ZERO, Color.WHITE)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	_build_hud(root)
	_build_orders_strip(root)
	_middle = HBoxContainer.new()
	_middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_middle.add_theme_constant_override("separation", 8)
	root.add_child(_middle)
	_board_col = VBoxContainer.new()
	_board_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_col.add_theme_constant_override("separation", 8)
	_middle.add_child(_board_col)
	_build_board_area(_board_col)
	_build_generator_dock()
	_middle.add_child(_gen_panel)
	_build_bottom_nav(root)
	_build_overlay()
	var autosave := Timer.new()
	autosave.wait_time = 10.0
	autosave.autostart = true
	autosave.timeout.connect(_on_autosave_timeout)
	add_child(autosave)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var s := UiStyle.panel_style(Color(1, 1, 1, 0.92), 16)
	p.add_theme_stylebox_override("panel", s)
	return p

func _build_hud(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	panel.add_child(bar)
	bar.add_child(UiStyle.label("Merge Code", 20, UiStyle.ACCENT))
	var coin_chip := PanelContainer.new()
	coin_chip.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 5)
	coin_chip.add_child(coin_row)
	coin_row.add_child(UiStyle.icon_rect(COIN_ICON, Vector2(20, 20), UiStyle.hex("E8A33D")))
	_coins_label = UiStyle.label("0", 17, UiStyle.INK)
	coin_row.add_child(_coins_label)
	bar.add_child(coin_chip)
	var level_chip := PanelContainer.new()
	level_chip.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("EAF3FF"), 12))
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 5)
	level_chip.add_child(level_row)
	level_row.add_child(UiStyle.icon_rect(STAR_ICON, Vector2(18, 18), UiStyle.hex("E8A33D")))
	_level_label = UiStyle.label("Lv 1", 15, UiStyle.INK)
	level_row.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(90, 12)
	_xp_bar.show_percentage = false
	level_row.add_child(_xp_bar)
	bar.add_child(level_chip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var sound_btn := UiStyle.make_icon_button(GEAR_ICON, "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off", Color("B9AC97"), 12)
	sound_btn.pressed.connect(func() -> void:
		GameStateStore.instance.sound_enabled = not GameStateStore.instance.sound_enabled
		sound_btn.text = "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off"
		_mark_dirty())
	bar.add_child(sound_btn)
	var menu_btn := UiStyle.make_button("Main Menu", Color("B9AC97"), 12)
	menu_btn.pressed.connect(func() -> void: _save(); get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	bar.add_child(menu_btn)

func _build_orders_strip(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	var head := HBoxContainer.new()
	vbox.add_child(head)
	head.add_child(UiStyle.label("Customers", 15, UiStyle.INK))
	head.add_child(UiStyle.label("— drag items onto a customer to hand them over, or press Deliver", 11, UiStyle.MUTED))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 132)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	scroll.add_child(row)
	for i in GameStateStore.instance.MAX_ORDERS:
		var card := OrderCard.new()
		row.add_child(card)
		card.setup(i)
		card.deliver_requested.connect(_on_deliver)
		card.dismiss_requested.connect(func(index: int) -> void:
			GameStateStore.instance.replace_order(index)
			SoundFx.instance.play("click")
			_mark_dirty()
			_refresh_orders())
		card.item_dropped.connect(_on_order_item_drop)
		_order_cards.append(card)

func _build_board_area(parent: VBoxContainer) -> void:
	var panel := _panel()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	header.add_child(UiStyle.label("Merge Board", 16, UiStyle.INK))
	header.add_child(UiStyle.label("Drag items together to merge them", 11, UiStyle.MUTED))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_expand_btn = UiStyle.make_icon_button(COIN_ICON, "Expand", UiStyle.GREEN, 12)
	_expand_btn.pressed.connect(_on_expand_board)
	header.add_child(_expand_btn)
	# Workbench surface with the grid centred on it.
	var surface := PanelContainer.new()
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var surf_style := StyleBoxTexture.new()
	surf_style.texture = UiStyle.load_tex("res://assets/backgrounds/board_surface.svg")
	surf_style.set_content_margin_all(18)
	surface.add_theme_stylebox_override("panel", surf_style)
	vbox.add_child(surface)
	var center := CenterContainer.new()
	surface.add_child(center)
	board = Board.new()
	center.add_child(board)
	# Selected item bar (icon-first, compact).
	var selected_panel := PanelContainer.new()
	selected_panel.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
	vbox.add_child(selected_panel)
	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 8)
	selected_panel.add_child(sel_row)
	_selected_icon = PanelContainer.new()
	_selected_icon.custom_minimum_size = Vector2(44, 44)
	_selected_icon.add_theme_stylebox_override("panel", UiStyle.panel_style(Color(0, 0, 0, 0.06), 10))
	sel_row.add_child(_selected_icon)
	var sel_text := VBoxContainer.new()
	sel_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_row.add_child(sel_text)
	_selected_title = UiStyle.label("No item selected", 14, UiStyle.INK)
	sel_text.add_child(_selected_title)
	_selected_desc = UiStyle.label("Tap a board item to see it here. Drag items to move, swap or merge.", 11, UiStyle.MUTED)
	_selected_desc.clip_text = true
	sel_text.add_child(_selected_desc)
	_sell_btn = UiStyle.make_icon_button(COIN_ICON, "Sell", UiStyle.RED, 13)
	_sell_btn.disabled = true
	_sell_btn.pressed.connect(_on_sell_selected)
	sel_row.add_child(_sell_btn)
	var close_btn := UiStyle.make_icon_button(CLOSE_ICON, "", Color("B9AC97"), 12)
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(_clear_selection)
	sel_row.add_child(close_btn)

func _build_generator_dock() -> void:
	_gen_panel = _panel()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_gen_panel.add_child(vbox)
	var head := HBoxContainer.new()
	vbox.add_child(head)
	head.add_child(UiStyle.label("Generators", 15, UiStyle.INK))
	head.add_child(UiStyle.label("tap Make to produce", 11, UiStyle.MUTED))
	_gen_scroll = ScrollContainer.new()
	_gen_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gen_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_gen_scroll)
	_gen_grid = GridContainer.new()
	_gen_grid.columns = 1
	_gen_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gen_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gen_grid.add_theme_constant_override("h_separation", 8)
	_gen_grid.add_theme_constant_override("v_separation", 8)
	_gen_scroll.add_child(_gen_grid)
	for gen_id in ItemDatabase.instance.generator_order:
		var card := GeneratorCard.new()
		_gen_grid.add_child(card)
		card.setup(str(gen_id))
		card.produce_requested.connect(_on_produce)
		card.changed.connect(func() -> void: _mark_dirty(); _refresh_all())
		_gen_cards[str(gen_id)] = card

func _build_bottom_nav(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	panel.add_child(nav)
	var entries := [
		["Crafting", "res://assets/sprites/game_icons/lorc_claw-hammer.svg", "craft"],
		["Shop", "res://assets/sprites/game_icons/delapouite_shopping-cart.svg", "shop"],
		["Collection", "res://assets/sprites/game_icons/lorc_book-cover.svg", "catalog"],
		["Missions", "res://assets/sprites/game_icons/delapouite_diamond-trophy.svg", "missions"],
		["Help", "res://assets/sprites/game_icons/delapouite_present.svg", "help"],
	]
	for entry in entries:
		var b := UiStyle.make_icon_button(str(entry[1]), str(entry[0]), UiStyle.ACCENT, 14)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_open_popup.bind(str(entry[2])))
		nav.add_child(b)

func _build_overlay() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.15, 0.1, 0.05, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	add_child(_dim)
	popup = MergePopupPanel.new()
	popup.board = board
	popup.changed.connect(func() -> void: _mark_dirty(); _refresh_all())
	add_child(popup)
	_toast = UiStyle.label("", 15, Color.WHITE)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.add_theme_stylebox_override("normal", UiStyle.panel_style(UiStyle.INK, 10))
	_toast.visible = false
	add_child(_toast)

# --- Responsive layout ---------------------------------------------------------

func _apply_layout() -> void:
	if not is_inside_tree() or board == null:
		return
	var vp := get_viewport_rect().size
	var wide := vp.x >= 980.0
	if wide != _wide_mode or true:
		_wide_mode = wide
		if wide:
			if _gen_panel.get_parent() != _middle:
				_gen_panel.reparent(_middle)
			_gen_panel.custom_minimum_size = Vector2(352 if vp.x >= 1250.0 else 190, 0)
			_gen_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_gen_grid.columns = 2 if vp.x >= 1250.0 else 1
			_gen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_gen_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			_gen_scroll.custom_minimum_size = Vector2.ZERO
		else:
			if _gen_panel.get_parent() != _board_col:
				_gen_panel.reparent(_board_col)
			_gen_panel.custom_minimum_size = Vector2(0, 238)
			_gen_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			_gen_grid.columns = ItemDatabase.instance.generator_order.size()
			_gen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			_gen_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			_gen_scroll.custom_minimum_size = Vector2(0, 188)
	# Board cell size from the space actually available.
	var reserved_w := (352.0 if (wide and vp.x >= 1250.0) else (190.0 if wide else 24.0)) + 90.0
	var reserved_h := 470.0 if wide else 700.0
	var cell_w := (vp.x - reserved_w) / 7.0
	var cell_h := (vp.y - reserved_h) / 7.0
	var cell := int(clampf(minf(cell_w, cell_h), 44.0, 116.0))
	board.set_cell_size(cell)

# --- Signals / shared logic (unchanged gameplay) --------------------------------

func _connect_signals() -> void:
	GameStateStore.instance.coins_changed.connect(func(amount: int) -> void: _coins_label.text = "%d" % amount; _refresh_expand())
	GameStateStore.instance.xp_changed.connect(func(xp: int, needed: int, lvl: int) -> void:
		_level_label.text = "Lv %d" % lvl
		_xp_bar.max_value = needed
		_xp_bar.value = xp)
	GameStateStore.instance.leveled_up.connect(func(lvl: int) -> void:
		SoundFx.instance.play("levelup")
		_show_toast("Level %d reached! Bonus coins awarded — check Generators for new unlocks." % lvl)
		_refresh_all())
	GameStateStore.instance.orders_changed.connect(_refresh_orders)
	board.board_changed.connect(func() -> void: _mark_dirty(); _refresh_orders(); _refresh_expand())
	board.item_selected.connect(_on_item_selected)
	board.invalid_action.connect(_show_toast)
	board.merge_performed.connect(func(_cell: int, new_item_id: String) -> void:
		_show_toast("Merged into %s!" % ItemDatabase.instance.item_name(new_item_id)))

func _process(delta: float) -> void:
	if _dim and popup:
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
		_show_toast("That generator is locked — unlock it first.")
		SoundFx.instance.play("error")
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
	var cell := board.find_empty_cell()
	if board.place_item(item_id):
		GameStateStore.instance.bump_stat("generated")
		SoundFx.instance.play("generate")
		if cell >= 0:
			board.spawn_burst(cell)
		_mark_dirty()
	_gen_cards[gen_id].refresh()

func _on_deliver(index: int) -> void:
	if index < 0 or index >= GameStateStore.instance.orders.size():
		return
	var order: Dictionary = GameStateStore.instance.orders[index]
	var remaining: Dictionary = {}
	var fulfilled: Dictionary = order.get("fulfilled", {})
	for item_id in order.get("requirements", {}):
		var left := int(order["requirements"][item_id]) - int(fulfilled.get(str(item_id), 0))
		if left > 0:
			remaining[str(item_id)] = left
	if not board.has_requirements(remaining):
		_show_toast("You don't have all the requested items yet.")
		SoundFx.instance.play("error")
		return
	board.consume_requirements(remaining)
	GameStateStore.instance.complete_order(index)
	SoundFx.instance.play("coin")
	_show_toast("Order delivered! +%d coins, +%d XP" % [int(order.get("reward_coins", 0)), int(order.get("reward_xp", 0))])
	_mark_dirty()
	_refresh_all()

func _on_order_item_drop(index: int, from_cell: int) -> void:
	if index < 0 or index >= GameStateStore.instance.orders.size() or not board.cells_items.has(from_cell):
		return
	var order: Dictionary = GameStateStore.instance.orders[index]
	var item_id := str(board.cells_items[from_cell])
	var req: Dictionary = order.get("requirements", {})
	if not req.has(item_id):
		return
	var fulfilled: Dictionary = order.get("fulfilled", {}).duplicate()
	if int(fulfilled.get(item_id, 0)) >= int(req[item_id]):
		return
	fulfilled[item_id] = int(fulfilled.get(item_id, 0)) + 1
	order["fulfilled"] = fulfilled
	GameStateStore.instance.orders[index] = order
	board.remove_at(from_cell)
	SoundFx.instance.play("generate")
	_show_toast("Handed over %s (%d/%d)" % [ItemDatabase.instance.item_name(item_id), int(fulfilled[item_id]), int(req[item_id])])
	_mark_dirty()
	_refresh_orders()

func _on_item_selected(tile: ItemTile) -> void:
	_selected_cell = tile.cell_index
	var def := ItemDatabase.instance.get_item(tile.item_id)
	SoundFx.instance.play("click")
	for child in _selected_icon.get_children():
		child.queue_free()
	_selected_icon.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(def.get("color", "999999"))), 10))
	_selected_icon.add_child(UiStyle.icon_rect(str(def.get("icon", "")), Vector2(34, 34), Color.WHITE))
	_selected_title.text = "%s • Tier %s • %s" % [str(def.get("name", tile.item_id)), str(def.get("tier", "-")), str(def.get("rarity", ""))]
	var extra := ""
	if str(def.get("source_url", "")) != "":
		extra += "  Source: " + str(def["source_url"])
	_selected_desc.text = str(def.get("description", "")) + extra
	_selected_desc.tooltip_text = _selected_desc.text
	_sell_btn.text = "Sell %d" % int(def.get("sell_value", 0))
	_sell_btn.disabled = false

func _clear_selection() -> void:
	_selected_cell = -1
	board.set_selected_cell(-1)
	_selected_title.text = "No item selected"
	_selected_desc.text = "Tap a board item to see it here. Drag items to move, swap or merge."
	_sell_btn.disabled = true

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
	_clear_selection()
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
		_apply_layout.call_deferred()
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
		_expand_btn.text = "Board maxed"
		_expand_btn.disabled = true
	else:
		var cost := GameStateStore.instance.board_expansion_cost()
		_expand_btn.text = "Expand %d" % cost
		_expand_btn.disabled = GameStateStore.instance.coins < cost

func _refresh_all() -> void:
	_coins_label.text = "%d" % GameStateStore.instance.coins
	_level_label.text = "Lv %d" % GameStateStore.instance.level
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
