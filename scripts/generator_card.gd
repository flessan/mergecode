class_name GeneratorCard
extends PanelContainer
## Visual generator: illustrated machine (original artwork in
## assets/sprites/generators), its product icon, energy pips, level badge.
## Tap the machine / Produce to generate (consumes 1 energy, regenerated
## over time by the main scene); upgrade and unlock use coins.

signal produce_requested(generator_id: String)
signal changed

const COIN_ICON := "res://assets/sprites/game_icons/lorc_crown-coin.svg"
const ENERGY_ICON := "res://assets/sprites/game_icons/lorc_focused-lightning.svg"
const LOCK_ICON := "res://assets/sprites/game_icons/lorc_padlock.svg"
const STAR_ICON := "res://assets/sprites/game_icons/lorc_flat-star.svg"

var generator_id: String = ""
var _energy_row: HBoxContainer
var _status: Label
var _produce_btn: Button
var _upgrade_btn: Button
var _unlock_btn: Button
var _machine: TextureRect
var _level_badge: Label

func setup(p_id: String) -> void:
	generator_id = p_id
	_build()
	refresh()

func _build() -> void:
	var def: Dictionary = ItemDatabase.instance.generators[generator_id]
	custom_minimum_size = Vector2(158, 0)
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 14))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 4)
	add_child(body)
	_machine = UiStyle.icon_rect(str(def.get("art", "")), Vector2(132, 92), Color.WHITE)
	_machine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_machine.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			produce_requested.emit(generator_id))
	body.add_child(_machine)
	var title := UiStyle.label(str(def.get("name", generator_id)), 13, UiStyle.INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	_level_badge = UiStyle.label("", 11, UiStyle.MUTED)
	_level_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_level_badge)
	var energy_head := HBoxContainer.new()
	energy_head.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_head.add_theme_constant_override("separation", 4)
	body.add_child(energy_head)
	energy_head.add_child(UiStyle.icon_rect(ENERGY_ICON, Vector2(14, 14), UiStyle.hex("E8A33D")))
	_energy_row = HBoxContainer.new()
	_energy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_energy_row.add_theme_constant_override("separation", 2)
	energy_head.add_child(_energy_row)
	_status = UiStyle.label("", 10, UiStyle.MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)
	var start_item := ItemDatabase.instance.chain_start_item(str(def.get("chain_id", "")))
	_produce_btn = UiStyle.make_icon_button(str(ItemDatabase.instance.get_item(start_item).get("icon", "")), "Make", UiStyle.hex(str(ItemDatabase.instance.get_item(start_item).get("color", "4A90D9"))), 13)
	_produce_btn.pressed.connect(_on_produce_pressed)
	body.add_child(_produce_btn)
	_upgrade_btn = UiStyle.make_icon_button(COIN_ICON, "Upgrade", UiStyle.GREEN, 12)
	_upgrade_btn.custom_minimum_size = Vector2(0, 32)
	_upgrade_btn.pressed.connect(_on_upgrade)
	body.add_child(_upgrade_btn)
	_unlock_btn = UiStyle.make_icon_button(LOCK_ICON, "Unlock", UiStyle.ACCENT, 12)
	_unlock_btn.pressed.connect(_on_unlock)
	body.add_child(_unlock_btn)
	tooltip_text = str(def.get("description", ""))

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
	# Energy pips.
	for child in _energy_row.get_children():
		child.queue_free()
	var filled := int(float(state.get("energy", 0.0)))
	for i in max_energy:
		var pip := PanelContainer.new()
		pip.custom_minimum_size = Vector2(13, 9)
		var s := StyleBoxFlat.new()
		s.bg_color = UiStyle.hex("FFD94A") if i < filled else Color(0, 0, 0, 0.12)
		s.set_corner_radius_all(4)
		pip.add_theme_stylebox_override("panel", s)
		_energy_row.add_child(pip)
	_produce_btn.visible = unlocked
	_upgrade_btn.visible = unlocked
	_unlock_btn.visible = not unlocked
	_machine.modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.45)
	if unlocked:
		_level_badge.text = "Level %d" % lvl
		_status.text = "Ready!" if filled > 0 else "Recharging..."
		if GameStateStore.instance.generator_bonus_chance(generator_id) > 0.0:
			_status.text += "  •  +%d%% tier-2" % int(GameStateStore.instance.generator_bonus_chance(generator_id) * 100.0)
		var start_item := ItemDatabase.instance.chain_start_item(str(def.get("chain_id", "")))
		_produce_btn.text = "Make %s" % ItemDatabase.instance.item_name(start_item)
		_produce_btn.disabled = filled < 1
		var cost := GameStateStore.instance.generator_upgrade_cost(generator_id)
		_upgrade_btn.text = "Lv %d • %d" % [lvl + 1, cost]
		_upgrade_btn.disabled = GameStateStore.instance.coins < cost
	else:
		_level_badge.text = "Locked"
		_status.text = "Needs player Lv %d" % int(def.get("unlock_level", 1))
		_unlock_btn.text = "Unlock • %d" % int(def.get("unlock_cost", 0))
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
