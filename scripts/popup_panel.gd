class_name PopupPanel
extends PanelContainer
## Modal overlay content: Crafting, Collection Catalog, Missions, Shop, Help.
## Every button performs its real action against Board/GameState.

signal changed   # state mutated (craft/buy/claim) -> main should refresh + save

var board: Board
var _title: Label
var _content: VBoxContainer
var _scroll: ScrollContainer

func _ready() -> void:
	visible = false
	# Centre a 620x520 modal on its parent regardless of who instantiated us.
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = -310
	offset_top = -260
	offset_right = 310
	offset_bottom = 260
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 18))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	var head := HBoxContainer.new()
	vbox.add_child(head)
	_title = UiStyle.label("", 22, UiStyle.INK)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	var close_btn := UiStyle.make_button("Close", Color("B9AC97"))
	close_btn.pressed.connect(func() -> void: visible = false)
	head.add_child(close_btn)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(560, 420)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 8)
	_scroll.add_child(_content)

func _clear() -> void:
	for child in _content.get_children():
		child.queue_free()

func open(title: String) -> void:
	_title.text = title
	_clear()
	visible = true

# --- Crafting ---------------------------------------------------------------

func show_crafting() -> void:
	open("Crafting — combine different items")
	_content.add_child(UiStyle.label("Crafting consumes one of each ingredient from the board and places the result in a free cell.", 12, UiStyle.MUTED))
	for recipe in ItemDB.recipes:
		var result_id := str(recipe.get("result_id", ""))
		var def := ItemDB.get_item(result_id)
		var ingredients: Array = recipe.get("ingredient_ids", [])
		var known := GameState.is_discovered(result_id)
		for ing in ingredients:
			if GameState.is_discovered(str(ing)):
				known = true
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text)
		if known:
			text.add_child(UiStyle.label(str(def.get("name", result_id)), 15, UiStyle.INK))
			var parts: Array = []
			for ing in ingredients:
				parts.append("%s (%d on board)" % [ItemDB.item_name(str(ing)), board.item_count(str(ing)) if board else 0])
			text.add_child(UiStyle.label("Needs: " + " + ".join(parts), 12, UiStyle.MUTED))
			if GameState.crafted_recipes.has(str(recipe.get("id", ""))):
				text.add_child(UiStyle.label("Crafted before", 11, UiStyle.GREEN))
		else:
			text.add_child(UiStyle.label("Undiscovered Recipe", 15, UiStyle.MUTED))
			text.add_child(UiStyle.label("Discover its ingredients to reveal this recipe.", 12, UiStyle.MUTED))
		var btn := UiStyle.make_button("Craft", UiStyle.ACCENT)
		var req: Dictionary = {}
		for ing in ingredients:
			req[str(ing)] = 1
		btn.disabled = not known or board == null or not board.has_requirements(req) or board.find_empty_cell() < 0
		btn.pressed.connect(_on_craft.bind(recipe, req))
		hbox.add_child(btn)
		_content.add_child(row)

func _on_craft(recipe: Dictionary, req: Dictionary) -> void:
	if board == null or not board.consume_requirements(req):
		SoundManager.play("error")
		return
	var result_id := str(recipe.get("result_id", ""))
	if board.place_item(result_id):
		GameState.crafted_recipes[str(recipe.get("id", ""))] = true
		GameState.bump_stat("crafts")
		GameState.add_xp(15)
		SoundManager.play("craft")
		changed.emit()
		show_crafting()
	else:
		SoundManager.play("error")

# --- Catalog ------------------------------------------------------------------

func show_catalog() -> void:
	open("Collection Catalog — %d / %d discovered" % [GameState.discovered.size(), ItemDB.items.size()])
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	for item_id in ItemDB.item_order:
		var def := ItemDB.get_item(str(item_id))
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(128, 84)
		var found := GameState.is_discovered(str(item_id))
		var bg := UiStyle.hex(str(def.get("color", "999999"))).lightened(0.62) if found else UiStyle.CELL_LOCKED
		cell.add_theme_stylebox_override("panel", UiStyle.panel_style(bg, 10))
		var vbox := VBoxContainer.new()
		cell.add_child(vbox)
		vbox.add_child(UiStyle.label(str(def.get("short", "?")) if found else "???", 16, UiStyle.INK))
		vbox.add_child(UiStyle.label(str(def.get("name", "")) if found else "Undiscovered", 10, UiStyle.INK))
		vbox.add_child(UiStyle.label(("%s • Tier %s" % [str(def.get("category", "")), str(def.get("tier", "-"))]) if found else str(def.get("category", "")), 9, UiStyle.MUTED))
		grid.add_child(cell)

# --- Missions -------------------------------------------------------------------

func show_missions() -> void:
	open("Missions & Achievements")
	for mission in ItemDB.missions:
		var mid := str(mission.get("id", ""))
		var progress := GameState.stat_value(str(mission.get("stat", "")))
		var target := int(mission.get("target", 1))
		var claimed := GameState.claimed_missions.has(mid)
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
		var hbox := HBoxContainer.new()
		row.add_child(hbox)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(text)
		text.add_child(UiStyle.label(str(mission.get("name", mid)), 15, UiStyle.INK))
		text.add_child(UiStyle.label("%s — %d / %d   Reward: %d coins, %d XP" % [str(mission.get("description", "")), mini(progress, target), target, int(mission.get("reward_coins", 0)), int(mission.get("reward_xp", 0))], 12, UiStyle.MUTED))
		var btn := UiStyle.make_button("Claimed" if claimed else "Claim", UiStyle.GREEN)
		btn.disabled = claimed or progress < target
		btn.pressed.connect(_on_claim.bind(mission))
		hbox.add_child(btn)
		_content.add_child(row)

func _on_claim(mission: Dictionary) -> void:
	GameState.claimed_missions[str(mission.get("id", ""))] = true
	GameState.add_coins(int(mission.get("reward_coins", 0)))
	GameState.add_xp(int(mission.get("reward_xp", 0)))
	SoundManager.play("coin")
	changed.emit()
	show_missions()

# --- Shop -----------------------------------------------------------------------

func show_shop() -> void:
	open("Item Shop — buy items straight onto the board")
	_content.add_child(UiStyle.label("Higher generator levels unlock higher shop tiers. Prices are higher than merging yourself — convenience costs coins.", 12, UiStyle.MUTED))
	for gen_id in ItemDB.generator_order:
		var state := GameState.generator_state(str(gen_id))
		if not bool(state.get("unlocked", false)):
			continue
		var gen_def: Dictionary = ItemDB.generators[gen_id]
		var chain_id := str(gen_def.get("chain_id", ""))
		var ids: Array = ItemDB.chains.get(chain_id, [])
		var lvl := int(state.get("level", 1))
		var max_tier := 1
		if lvl >= 3:
			max_tier = 2
		if lvl >= 5:
			max_tier = 3
		for t in max_tier:
			if t >= ids.size():
				continue
			var item_id := str(ids[t])
			var def := ItemDB.get_item(item_id)
			var price := maxi(10, int(def.get("sell_value", 5)) * 6)
			var row := PanelContainer.new()
			row.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.hex("FFF1DE"), 12))
			var hbox := HBoxContainer.new()
			row.add_child(hbox)
			var text := VBoxContainer.new()
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(text)
			text.add_child(UiStyle.label(str(def.get("name", item_id)), 15, UiStyle.INK))
			text.add_child(UiStyle.label("%s • Tier %d" % [str(def.get("category", "")), int(def.get("tier", 0))], 12, UiStyle.MUTED))
			var btn := UiStyle.make_button("Buy %d" % price, UiStyle.ACCENT)
			btn.disabled = GameState.coins < price or board == null or board.find_empty_cell() < 0
			btn.pressed.connect(_on_buy.bind(item_id, price))
			hbox.add_child(btn)
			_content.add_child(row)
	if _content.get_child_count() <= 1:
		_content.add_child(UiStyle.label("Unlock a generator first.", 13, UiStyle.MUTED))

func _on_buy(item_id: String, price: int) -> void:
	if board and GameState.spend_coins(price) and board.place_item(item_id):
		SoundManager.play("coin")
		changed.emit()
		show_shop()
	else:
		SoundManager.play("error")

# --- Help -------------------------------------------------------------------------

func show_help() -> void:
	open("How to Play")
	var lines := [
		"1. Tap a generator on the left to produce items. Generators use energy, which refills over time.",
		"2. Drag an item onto another identical item to merge them into the next tier.",
		"3. Drag items onto empty cells to move them, or onto different items to swap.",
		"4. Watch the customer orders on the right — deliver the requested items for coins and XP.",
		"5. Spend coins on generator upgrades, new generators, board expansion and the shop.",
		"6. Combine different items in Crafting to create software products, and complete Missions for bonuses.",
		"7. Click any board item to see its details and sell it. Your game saves automatically.",
	]
	for line in lines:
		_content.add_child(UiStyle.label(line, 14, UiStyle.INK))
