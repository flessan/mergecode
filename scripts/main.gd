extends Control
## Merge Code - main gameplay scene.
##
## Board-first game-screen composition (not a stack of dashboard panels):
##   TopHUD            compact reserved strip (coins / level / menu)
##   CustomerCarousel  slim horizontal strip of compact customer cards
##   GameplayArea      the merge board on its workbench surface, inside
##                     its own clipped scrolling viewport (Board), with
##                     the generator dock beside it on wide screens
##   GeneratorDock     under the board as a horizontal carousel on
##                     narrow/portrait screens
##   SelectedItemOverlay  floating panel over the board, only visible
##                     while an item is selected (Board owns selection)
##   BottomNavigation  icon-first compact navigation
##   ModalLayer        dim + popup + toast
## The board receives the largest continuous area at every resolution;
## every other component has a small, bounded height/width.

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
var _gen_header: HBoxContainer
var _order_cards: Array = []
var _order_scroll: ScrollContainer
var _orders_panel: PanelContainer
var _order_row: GridContainer
var _mode: int = -1  # 0 narrow, 1 wide, 2 wide+short (landscape phone)
var _root_box: VBoxContainer
var _middle: HBoxContainer
var _board_panel: PanelContainer
var _hud_title: Label
var _sound_btn: Button
var _menu_btn: Button
var _board_hint: Label
var _gen_hint: Label
var _nav_buttons: Array = []
var _sel_overlay: PanelContainer
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
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)
	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 6)
	margin.add_child(_root_box)
	_build_hud(_root_box)
	_build_orders_strip(_root_box)
	_middle = HBoxContainer.new()
	_middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_middle.add_theme_constant_override("separation", 6)
	_root_box.add_child(_middle)
	_build_board_area(_middle)
	_build_generator_dock()
	_middle.add_child(_gen_panel)
	_build_bottom_nav(_root_box)
	_build_overlay()
	var autosave := Timer.new()
	autosave.wait_time = 10.0
	autosave.autostart = true
	autosave.timeout.connect(_on_autosave_timeout)
	add_child(autosave)

func _panel(content_margin: float = 8.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiStyle.Kenney_texture_style("grey_panel.png", 18.0, content_margin))
	return p

func _build_hud(root: VBoxContainer) -> void:
	var panel := _panel()
	root.add_child(panel)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	panel.add_child(bar)
	_hud_title = UiStyle.label("Merge Code", 17, UiStyle.ACCENT)
	bar.add_child(_hud_title)
	var coin_chip := PanelContainer.new()
	coin_chip.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 11))
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 4)
	coin_chip.add_child(coin_row)
	coin_row.add_child(UiStyle.icon_rect(COIN_ICON, Vector2(18, 18), UiStyle.hex("E8A33D")))
	_coins_label = UiStyle.label("0", 16, UiStyle.INK)
	coin_row.add_child(_coins_label)
	bar.add_child(coin_chip)
	var level_chip := PanelContainer.new()
	level_chip.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("EAF3FF"), 11))
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 4)
	level_chip.add_child(level_row)
	level_row.add_child(UiStyle.icon_rect(STAR_ICON, Vector2(16, 16), UiStyle.hex("E8A33D")))
	_level_label = UiStyle.label("Lv 1", 14, UiStyle.INK)
	level_row.add_child(_level_label)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(90, 13)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiStyle.style_Kenney_progress(_xp_bar, "blue")
	level_row.add_child(_xp_bar)
	bar.add_child(level_chip)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_sound_btn = UiStyle.make_Kenney_icon_button(GEAR_ICON, "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off", "grey", 11, true)
	_sound_btn.custom_minimum_size = Vector2(0, 36)
	_sound_btn.tooltip_text = "Toggle sound"
	_sound_btn.pressed.connect(func() -> void:
		GameStateStore.instance.sound_enabled = not GameStateStore.instance.sound_enabled
		_sound_btn.text = "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off"
		_apply_layout()
		_mark_dirty())
	bar.add_child(_sound_btn)
	_menu_btn = UiStyle.make_Kenney_button("Main Menu", "grey", 11, true)
	_menu_btn.custom_minimum_size = Vector2(0, 36)
	_menu_btn.pressed.connect(func() -> void: _save(); get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	bar.add_child(_menu_btn)

func _build_orders_strip(root: VBoxContainer) -> void:
	# No header row: the cards themselves (portrait + wants + reward)
	# explain the strip, and the saved pixels go to the board. The panel
	# is reparented by _apply_layout: top strip normally, left rail on
	# short wide screens.
	_orders_panel = _panel()
	root.add_child(_orders_panel)
	_order_scroll = ScrollContainer.new()
	_order_scroll.custom_minimum_size = Vector2(0, 64)
	_order_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_order_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_order_scroll.tooltip_text = "Drag wanted items onto a customer, or press Deliver when ready"
	_orders_panel.add_child(_order_scroll)
	_order_row = GridContainer.new()
	_order_row.columns = GameStateStore.instance.MAX_ORDERS
	_order_row.add_theme_constant_override("h_separation", 6)
	_order_row.add_theme_constant_override("v_separation", 6)
	_order_scroll.add_child(_order_row)
	for i in GameStateStore.instance.MAX_ORDERS:
		var card := OrderCard.new()
		_order_row.add_child(card)
		card.setup(i)
		card.deliver_requested.connect(_on_deliver)
		card.dismiss_requested.connect(func(index: int) -> void:
			GameStateStore.instance.replace_order(index)
			SoundFx.instance.play("click")
			_mark_dirty()
			_refresh_orders())
		card.item_dropped.connect(_on_order_item_drop)
		_order_cards.append(card)

func _build_board_area(parent: HBoxContainer) -> void:
	_board_panel = _panel()
	_board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(_board_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_board_panel.add_child(vbox)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)
	header.add_child(UiStyle.label("Merge Board", 13, UiStyle.INK))
	_board_hint = UiStyle.label("Drag matching items together", 10, UiStyle.MUTED)
	header.add_child(_board_hint)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_expand_btn = UiStyle.make_Kenney_icon_button(COIN_ICON, "Expand", "yellow", 11, true)
	_expand_btn.custom_minimum_size = Vector2(0, 30)
	_expand_btn.pressed.connect(_on_expand_board)
	header.add_child(_expand_btn)
	# GameplayArea: workbench surface + board viewport + selection overlay.
	var area := Control.new()
	area.name = "GameplayArea"
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.clip_contents = true
	vbox.add_child(area)
	var surface := Panel.new()
	surface.set_anchors_preset(Control.PRESET_FULL_RECT)
	var surf_style := StyleBoxTexture.new()
	surf_style.texture = UiStyle.load_tex("res://assets/backgrounds/board_surface.svg")
	surf_style.texture_margin_left = 32.0
	surf_style.texture_margin_right = 32.0
	surf_style.texture_margin_top = 32.0
	surf_style.texture_margin_bottom = 32.0
	surf_style.set_content_margin_all(10)
	surface.add_theme_stylebox_override("panel", surf_style)
	area.add_child(surface)
	# Board is a clipped ScrollContainer viewport: it fills the surface,
	# centres the grid, and scrolls vertically rather than overflowing.
	board = Board.new()
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.offset_left = 6
	board.offset_top = 6
	board.offset_right = -6
	board.offset_bottom = -6
	area.add_child(board)
	_build_selected_overlay(area)

func _build_selected_overlay(area: Control) -> void:
	# Contextual: floats over the bottom of the board ONLY while an item
	# is selected. No selection = no reserved space, board keeps it all.
	_sel_overlay = PanelContainer.new()
	_sel_overlay.add_theme_stylebox_override("panel", UiStyle.Kenney_panel_style("grey", Color(1.0, 0.94, 0.80, 1.0)))
	_sel_overlay.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sel_overlay.offset_left = -176
	_sel_overlay.offset_right = 176
	_sel_overlay.offset_top = -72
	_sel_overlay.offset_bottom = -8
	_sel_overlay.visible = false
	area.add_child(_sel_overlay)
	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 6)
	_sel_overlay.add_child(sel_row)
	_selected_icon = PanelContainer.new()
	_selected_icon.custom_minimum_size = Vector2(40, 40)
	_selected_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_selected_icon.add_theme_stylebox_override("panel", UiStyle.panel_style(Color(0, 0, 0, 0.06), 9))
	sel_row.add_child(_selected_icon)
	var sel_text := VBoxContainer.new()
	sel_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sel_row.add_child(sel_text)
	_selected_title = UiStyle.label("No item selected", 12, UiStyle.INK)
	_selected_title.clip_text = true
	sel_text.add_child(_selected_title)
	_selected_desc = UiStyle.label("", 10, UiStyle.MUTED)
	_selected_desc.clip_text = true
	sel_text.add_child(_selected_desc)
	_sell_btn = UiStyle.make_Kenney_icon_button(COIN_ICON, "Sell", "red", 12)
	_sell_btn.custom_minimum_size = Vector2(0, 34)
	_sell_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sell_btn.disabled = true
	_sell_btn.pressed.connect(_on_sell_selected)
	sel_row.add_child(_sell_btn)
	var close_btn := UiStyle.make_Kenney_icon_button(CLOSE_ICON, "", "red", 11)
	close_btn.custom_minimum_size = Vector2(36, 34)
	close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_btn.tooltip_text = "Dismiss"
	close_btn.pressed.connect(_clear_selection)
	sel_row.add_child(close_btn)

func _build_generator_dock() -> void:
	_gen_panel = _panel()
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_gen_panel.add_child(vbox)
	_gen_header = HBoxContainer.new()
	_gen_header.add_theme_constant_override("separation", 6)
	vbox.add_child(_gen_header)
	_gen_header.add_child(UiStyle.label("Generators", 13, UiStyle.INK))
	_gen_hint = UiStyle.label("tap Make", 10, UiStyle.MUTED)
	_gen_header.add_child(_gen_hint)
	_gen_scroll = ScrollContainer.new()
	_gen_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gen_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_gen_scroll)
	_gen_grid = GridContainer.new()
	_gen_grid.columns = 1
	_gen_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gen_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_gen_grid.add_theme_constant_override("h_separation", 6)
	_gen_grid.add_theme_constant_override("v_separation", 6)
	_gen_scroll.add_child(_gen_grid)
	for gen_id in ItemDatabase.instance.generator_order:
		var card := GeneratorCard.new()
		_gen_grid.add_child(card)
		card.setup(str(gen_id))
		card.produce_requested.connect(_on_produce)
		card.changed.connect(func() -> void: _mark_dirty(); _refresh_all())
		_gen_cards[str(gen_id)] = card

func _build_bottom_nav(root: VBoxContainer) -> void:
	var panel := _panel(6.0)
	root.add_child(panel)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	panel.add_child(nav)
	var entries := [
		["Crafting", "res://assets/sprites/game_icons/lorc_claw-hammer.svg", "craft", "blue", false],
		["Shop", "res://assets/sprites/game_icons/delapouite_shopping-cart.svg", "shop", "green", false],
		["Collection", "res://assets/sprites/game_icons/lorc_book-cover.svg", "catalog", "yellow", true],
		["Missions", "res://assets/sprites/game_icons/delapouite_diamond-trophy.svg", "missions", "red", false],
		["Help", "res://assets/sprites/game_icons/delapouite_present.svg", "help", "grey", true],
	]
	for entry in entries:
		var b := UiStyle.make_Kenney_icon_button(str(entry[1]), str(entry[0]), str(entry[3]), 13, bool(entry[4]))
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = str(entry[0])
		b.pressed.connect(_open_popup.bind(str(entry[2])))
		nav.add_child(b)
		_nav_buttons.append({"button": b, "name": str(entry[0])})

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
	_toast = UiStyle.label("", 14, Color.WHITE)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -280
	_toast.offset_right = 280
	_toast.offset_top = -118
	_toast.offset_bottom = -66
	_toast.add_theme_stylebox_override("normal", UiStyle.panel_style(UiStyle.INK, 10))
	_toast.visible = false
	add_child(_toast)

# --- Responsive layout ---------------------------------------------------------

func _apply_layout() -> void:
	if not is_inside_tree() or board == null:
		return
	var vp := get_viewport_rect().size
	# Three compositions, chosen from the real viewport:
	#  0 narrow/portrait: customers top strip, board centre, generator
	#    carousel under the board, icon-first bottom navigation.
	#  1 wide: customers top strip, board centre, generator dock right.
	#  2 wide + short (landscape phones): customers as a LEFT rail and
	#    generators right, so the board keeps usable height instead of
	#    being crushed between two horizontal strips.
	var wide := (vp.x >= 900.0 and vp.x >= vp.y * 0.85) or (vp.x >= 740.0 and vp.x >= vp.y * 1.6)
	var mode := 0
	if wide:
		mode = 2 if vp.y < 520.0 else 1
	if mode != _mode:
		_mode = mode
		_apply_mode(mode)
	if mode == 2:
		_orders_panel.custom_minimum_size = Vector2(228, 0)
		_gen_panel.custom_minimum_size = Vector2(164, 0)
		_gen_grid.columns = 1
	elif mode == 1:
		_gen_panel.custom_minimum_size = Vector2(296, 0) if vp.x >= 1440.0 else Vector2(164, 0)
		_gen_grid.columns = 2 if vp.x >= 1440.0 else 1
	else:
		_orders_panel.custom_minimum_size = Vector2.ZERO
		_gen_panel.custom_minimum_size = Vector2.ZERO
	for card in _gen_cards.values():
		(card as GeneratorCard).set_dock_compact(mode == 0)
	var compact_orders := vp.x < 760.0 or vp.y < 700.0
	for card in _order_cards:
		(card as OrderCard).set_compact(compact_orders)
	# HUD: hide title first, then shorten buttons; chips always stay.
	var compact := vp.x < 680.0
	if _hud_title:
		_hud_title.visible = not compact
	if _board_hint:
		_board_hint.visible = vp.x >= 760.0
	if _gen_hint:
		_gen_hint.visible = vp.x >= 900.0
	if _sound_btn:
		_sound_btn.text = "" if compact else ("Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off")
	if _menu_btn:
		_menu_btn.text = "Menu" if compact else "Main Menu"
	_xp_bar.custom_minimum_size = Vector2(52, 13) if compact else Vector2(90, 13)
	# Bottom navigation: icon-first on narrow screens, labels return on
	# wide ones. Buttons keep >=40px touch targets either way.
	var icon_only := vp.x < 640.0
	for entry in _nav_buttons:
		var b: Button = entry["button"]
		b.text = "" if icon_only else str(entry["name"])

func _apply_mode(mode: int) -> void:
	# Generator dock placement + scroll direction per mode.
	if mode == 0:
		if _gen_panel.get_parent() != _root_box:
			_gen_panel.reparent(_root_box)
		_root_box.move_child(_gen_panel, _middle.get_index() + 1)
		_gen_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_gen_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_gen_grid.columns = maxi(1, ItemDatabase.instance.generator_order.size())
		_gen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_gen_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		# Bounded carousel height: compact cards, controlled strip.
		_gen_scroll.custom_minimum_size = Vector2(0, 118)
		_gen_header.visible = false
	else:
		if _gen_panel.get_parent() != _middle:
			_gen_panel.reparent(_middle)
		_middle.move_child(_gen_panel, _middle.get_child_count() - 1)
		_gen_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_gen_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_gen_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_gen_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_gen_scroll.custom_minimum_size = Vector2.ZERO
		_gen_header.visible = true
	# Customer strip/rail placement + scroll direction per mode.
	if mode == 2:
		if _orders_panel.get_parent() != _middle:
			_orders_panel.reparent(_middle)
		_middle.move_child(_orders_panel, 0)
		_orders_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_orders_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_order_row.columns = 1
		_order_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_order_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_order_scroll.custom_minimum_size = Vector2.ZERO
	else:
		if _orders_panel.get_parent() != _root_box:
			_orders_panel.reparent(_root_box)
		_root_box.move_child(_orders_panel, 1)
		_orders_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_orders_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_order_row.columns = GameStateStore.instance.MAX_ORDERS
		_order_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_order_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_order_scroll.custom_minimum_size = Vector2(0, 64)

# --- Signals / shared logic (unchanged gameplay) --------------------------------

func _connect_signals() -> void:
	GameStateStore.instance.coins_changed.connect(func(amount: int) -> void: _coins_label.text = "%d" % amount; _refresh_expand())
	GameStateStore.instance.xp_changed.connect(func(xp: int, needed: int, lvl: int) -> void:
		_level_label.text = "Lv %d" % lvl
		_xp_bar.max_value = needed
		_xp_bar.value = xp)
	GameStateStore.instance.leveled_up.connect(func(lvl: int) -> void:
		SoundFx.instance.play("levelup")
		_show_toast("Level %d reached! Bonus coins awarded - check Generators for new unlocks." % lvl)
		_refresh_all())
	GameStateStore.instance.orders_changed.connect(_refresh_orders)
	board.board_changed.connect(func() -> void: _mark_dirty(); _refresh_orders(); _refresh_expand(); _sync_selection_from_board())
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
		_show_toast("That generator is locked - unlock it first.")
		SoundFx.instance.play("error")
		return
	if float(state.get("energy", 0.0)) < 1.0:
		_show_toast("Generator is recharging - energy refills over time.")
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
	if index < _order_cards.size():
		(_order_cards[index] as OrderCard).celebrate()
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
	SoundFx.instance.play("click")
	_show_selected_item(tile.item_id)

func _show_selected_item(item_id: String) -> void:
	var def := ItemDatabase.instance.get_item(item_id)
	for child in _selected_icon.get_children():
		child.queue_free()
	_selected_icon.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex(str(def.get("color", "999999"))), 9))
	_selected_icon.add_child(UiStyle.icon_rect(str(def.get("icon", "")), Vector2(32, 32), Color.WHITE))
	_selected_title.text = "%s - Tier %s - %s" % [str(def.get("name", item_id)), str(def.get("tier", "-")), str(def.get("rarity", ""))]
	_selected_desc.text = str(def.get("description", ""))
	_selected_desc.tooltip_text = _selected_desc.text
	_sell_btn.text = "Sell %d" % int(def.get("sell_value", 0))
	_sell_btn.disabled = false
	_sel_overlay.visible = true

func _sync_selection_from_board() -> void:
	var selected: int = board.selected_cell()
	if selected < 0 or not board.cells_items.has(selected):
		_clear_selection()
	else:
		_show_selected_item(str(board.cells_items[selected]))

func _clear_selection() -> void:
	# Contextual overlay: hiding it returns its space to the board.
	# Selection itself stays owned by Board (single source of truth).
	board.set_selected_cell(-1)
	_sell_btn.disabled = true
	if _sel_overlay:
		_sel_overlay.visible = false

func _on_sell_selected() -> void:
	var selected: int = board.selected_cell()
	if selected < 0 or not board.cells_items.has(selected):
		return
	var item_id := str(board.cells_items[selected])
	var value := int(ItemDatabase.instance.get_item(item_id).get("sell_value", 0))
	board.remove_at(selected)
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
