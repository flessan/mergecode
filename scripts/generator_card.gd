class_name GeneratorCard
extends PanelContainer
## Compact generator: machine artwork, energy bar and ONE prominent
## production action. Level/status/upgrade live in a toggleable Details
## section so the card never forces a tall dock. Locked generators show
## Unlock as their primary action instead of Make.
## Economy/energy rules are unchanged (GameStateStore owns the state).

signal produce_requested(generator_id: String)
signal changed

const COIN_ICON := "res://assets/sprites/game_icons/lorc_crown-coin.svg"
const ENERGY_ICON := "res://assets/sprites/game_icons/lorc_focused-lightning.svg"
const LOCK_ICON := "res://assets/sprites/game_icons/lorc_padlock.svg"

var generator_id: String = ""
var _energy_bar: ProgressBar
var _status: Label
var _produce_btn: Button
var _upgrade_btn: Button
var _unlock_btn: Button
var _machine: TextureRect
var _level_badge: Label
var _title_label: Label
var _extra: VBoxContainer
var _details_btn: Button

func setup(p_id: String) -> void:
	generator_id = p_id
	_build()
	refresh()

func _build() -> void:
	var def: Dictionary = ItemDatabase.instance.generators[generator_id]
	custom_minimum_size = Vector2(140, 0)
	add_theme_stylebox_override("panel", UiStyle.Kenney_texture_style("grey_panel.png", 18.0, 8.0))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	add_child(body)
	_machine = UiStyle.icon_rect(str(def.get("art", "")), Vector2(118, 54), Color.WHITE)
	_machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_machine.mouse_filter = MOUSE_FILTER_STOP
	_machine.tooltip_text = "Tap to produce"
	_machine.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_produce_pressed())
	body.add_child(_machine)
	_title_label = UiStyle.label(str(def.get("name", generator_id)), 12, UiStyle.INK)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.clip_text = true
	body.add_child(_title_label)
	var energy_head := HBoxContainer.new()
	energy_head.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_head.add_theme_constant_override("separation", 4)
	body.add_child(energy_head)
	energy_head.add_child(UiStyle.icon_rect(ENERGY_ICON, Vector2(13, 13), UiStyle.hex("E8A33D")))
	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size = Vector2(0, 11)
	_energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.style_Kenney_progress(_energy_bar, "yellow")
	energy_head.add_child(_energy_bar)
	_level_badge = UiStyle.label("", 10, UiStyle.MUTED)
	energy_head.add_child(_level_badge)
	var start_item := ItemDatabase.instance.chain_start_item(str(def.get("chain_id", "")))
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 4)
	body.add_child(action_row)
	_produce_btn = UiStyle.make_Kenney_icon_button(str(ItemDatabase.instance.get_item(start_item).get("icon", "")), "Make", "green", 12)
	_produce_btn.custom_minimum_size = Vector2(0, 34)
	_produce_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_produce_btn.pressed.connect(_on_produce_pressed)
	action_row.add_child(_produce_btn)
	_unlock_btn = UiStyle.make_Kenney_icon_button(LOCK_ICON, "Unlock", "blue", 12)
	_unlock_btn.custom_minimum_size = Vector2(0, 34)
	_unlock_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unlock_btn.pressed.connect(_on_unlock)
	action_row.add_child(_unlock_btn)
	_details_btn = UiStyle.make_Kenney_button("Details", "grey", 10, true)
	_details_btn.custom_minimum_size = Vector2(58, 34)
	_details_btn.tooltip_text = "Level, energy status and upgrade"
	_details_btn.pressed.connect(func() -> void:
		_extra.visible = not _extra.visible
		_details_btn.text = "Hide" if _extra.visible else "Details")
	action_row.add_child(_details_btn)
	# Contextual details: hidden until requested, so the dock stays short.
	_extra = VBoxContainer.new()
	_extra.add_theme_constant_override("separation", 3)
	_extra.visible = false
	body.add_child(_extra)
	_status = UiStyle.label("", 10, UiStyle.MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_extra.add_child(_status)
	_upgrade_btn = UiStyle.make_Kenney_icon_button(COIN_ICON, "Upgrade", "yellow", 11, true)
	_upgrade_btn.custom_minimum_size = Vector2(0, 32)
	_upgrade_btn.pressed.connect(_on_upgrade)
	_extra.add_child(_upgrade_btn)
	tooltip_text = str(def.get("description", ""))

func set_dock_compact(compact: bool) -> void:
	# Horizontal mobile dock: shorter machine, no title line (name is in
	# the tooltip and on the Make button), details stay one tap away.
	custom_minimum_size = Vector2(128, 0) if compact else Vector2(140, 0)
	if _machine:
		_machine.custom_minimum_size = Vector2(104, 40) if compact else Vector2(118, 54)
	if _title_label:
		_title_label.visible = not compact

func _on_produce_pressed() -> void:
	# Little machine bounce so production feels physical.
	pivot_offset = size * 0.5
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.06)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	produce_requested.emit(generator_id)

func refresh() -> void:
	var def: Dictionary = ItemDatabase.instance.generators[generator_id]
	var state := GameStateStore.instance.generator_state(generator_id)
	var unlocked := bool(state.get("unlocked", false))
	var lvl := int(state.get("level", 1))
	var max_energy := GameStateStore.instance.generator_max_energy(generator_id)
	_energy_bar.min_value = 0.0
	_energy_bar.max_value = float(max_energy)
	_energy_bar.value = float(state.get("energy", 0.0))
	var filled := int(float(state.get("energy", 0.0)))
	_produce_btn.visible = unlocked
	_unlock_btn.visible = not unlocked
	_upgrade_btn.visible = unlocked
	if not unlocked:
		_machine.modulate = Color(0.42, 0.42, 0.42, 0.78)
	elif filled < 1:
		_machine.modulate = Color(0.68, 0.68, 0.68, 0.92)
	else:
		_machine.modulate = Color.WHITE
	if unlocked:
		_level_badge.text = "Lv %d" % lvl
		_status.text = ("Energy %d/%d - Ready!" % [filled, max_energy]) if filled > 0 else ("Energy %d/%d - Recharging..." % [filled, max_energy])
		if GameStateStore.instance.generator_bonus_chance(generator_id) > 0.0:
			_status.text += "  -  +%d%% tier-2" % int(GameStateStore.instance.generator_bonus_chance(generator_id) * 100.0)
		var start_item := ItemDatabase.instance.chain_start_item(str(def.get("chain_id", "")))
		_produce_btn.text = "Make %s" % ItemDatabase.instance.item_name(start_item)
		_produce_btn.disabled = filled < 1
		var cost := GameStateStore.instance.generator_upgrade_cost(generator_id)
		_upgrade_btn.text = "Upgrade Lv %d - %d" % [lvl + 1, cost]
		_upgrade_btn.disabled = GameStateStore.instance.coins < cost
	else:
		_level_badge.text = "Locked"
		_status.text = "Needs player Lv %d" % int(def.get("unlock_level", 1))
		_unlock_btn.text = "Unlock - %d" % int(def.get("unlock_cost", 0))
		_unlock_btn.disabled = GameStateStore.instance.level < int(def.get("unlock_level", 1)) or GameStateStore.instance.coins < int(def.get("unlock_cost", 0))

func _on_unlock() -> void:
	var def: Dictionary = ItemDatabase.instance.generators[generator_id]
	if GameStateStore.instance.level < int(def.get("unlock_level", 1)):
		SoundFx.instance.play("error")
		return
	if GameStateStore.instance.spend_coins(int(def.get("unlock_cost", 0))):
		GameStateStore.instance.generator_states[generator_id]["unlocked"] = true
		GameStateStore.instance.generator_states[generator_id]["energy"] = float(GameStateStore.instance.generator_max_energy(generator_id))
		SoundFx.instance.play("coin")
		changed.emit()
		refresh()

func _on_upgrade() -> void:
	var cost := GameStateStore.instance.generator_upgrade_cost(generator_id)
	if GameStateStore.instance.spend_coins(cost):
		GameStateStore.instance.generator_states[generator_id]["level"] = int(GameStateStore.instance.generator_state(generator_id).get("level", 1)) + 1
		SoundFx.instance.play("levelup")
		changed.emit()
		refresh()
