class_name GeneratorCard
extends PanelContainer
## One generator: tap to produce its chain's starter item (consumes energy,
## energy regenerates over time), unlock with coins, upgrade for more
## energy / faster regen / chance of a tier-2 item.

signal produce_requested(generator_id: String)
signal changed

var generator_id: String = ""
var _energy_bar: ProgressBar
var _status: Label
var _produce_btn: Button
var _upgrade_btn: Button
var _unlock_btn: Button
var _body: VBoxContainer

func setup(p_id: String) -> void:
	generator_id = p_id
	_build()
	refresh()

func _build() -> void:
	var def := ItemDatabase.instance.generators[generator_id]
	add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 14))
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	add_child(_body)
	var title := UiStyle.label(str(def.get("name", generator_id)), 16, UiStyle.INK)
	_body.add_child(title)
	_body.add_child(UiStyle.label(str(def.get("description", "")), 12, UiStyle.MUTED))
	_status = UiStyle.label("", 12, UiStyle.MUTED)
	_body.add_child(_status)
	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size = Vector2(0, 14)
	_energy_bar.show_percentage = false
	_body.add_child(_energy_bar)
	_produce_btn = UiStyle.make_button("Generate", UiStyle.hex(str(ItemDatabase.instance.get_item(ItemDatabase.instance.chain_start_item(str(def.get("chain_id", "")))).get("color", "4A90D9"))))
	_produce_btn.pressed.connect(func() -> void: produce_requested.emit(generator_id))
	_body.add_child(_produce_btn)
	_upgrade_btn = UiStyle.make_button("Upgrade", UiStyle.GREEN)
	_upgrade_btn.pressed.connect(_on_upgrade)
	_body.add_child(_upgrade_btn)
	_unlock_btn = UiStyle.make_button("Unlock", UiStyle.ACCENT)
	_unlock_btn.pressed.connect(_on_unlock)
	_body.add_child(_unlock_btn)

func refresh() -> void:
	var def := ItemDatabase.instance.generators[generator_id]
	var state := GameStateStore.instance.generator_state(generator_id)
	var unlocked := bool(state.get("unlocked", false))
	var lvl := int(state.get("level", 1))
	var max_energy := GameStateStore.instance.generator_max_energy(generator_id)
	_energy_bar.max_value = max_energy
	_energy_bar.value = float(state.get("energy", 0.0))
	_produce_btn.visible = unlocked
	_energy_bar.visible = unlocked
	_upgrade_btn.visible = unlocked
	_unlock_btn.visible = not unlocked
	if unlocked:
		_status.text = "Level %d  •  Energy %d/%d%s" % [lvl, int(float(state.get("energy", 0.0))), max_energy, ("  •  Tier-2 chance %d%%" % int(GameStateStore.instance.generator_bonus_chance(generator_id) * 100.0)) if GameStateStore.instance.generator_bonus_chance(generator_id) > 0.0 else ""]
		_produce_btn.disabled = float(state.get("energy", 0.0)) < 1.0
		_produce_btn.text = "Generate %s" % ItemDatabase.instance.item_name(ItemDatabase.instance.chain_start_item(str(def.get("chain_id", ""))))
		var cost := GameStateStore.instance.generator_upgrade_cost(generator_id)
		_upgrade_btn.text = "Upgrade to Lv %d  (%d coins)" % [lvl + 1, cost]
		_upgrade_btn.disabled = GameStateStore.instance.coins < cost
	else:
		_status.text = "Requires player level %d" % int(def.get("unlock_level", 1))
		_unlock_btn.text = "Unlock (%d coins)" % int(def.get("unlock_cost", 0))
		_unlock_btn.disabled = GameStateStore.instance.level < int(def.get("unlock_level", 1)) or GameStateStore.instance.coins < int(def.get("unlock_cost", 0))

func _on_unlock() -> void:
	var def := ItemDatabase.instance.generators[generator_id]
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
