extends Control
## Main menu: Continue / New Game (with overwrite confirmation), How to Play,
## sound toggle and Quit (hidden on web, where quitting isn't applicable).

var _confirming_new := false
var _new_btn: Button
var _help: MergePopupPanel

func _ready() -> void:
	GameBootstrap.ensure_managers(get_tree())
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL, 20))
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.custom_minimum_size = Vector2(420, 0)
	panel.add_child(vbox)
	var title := UiStyle.label("Merge Code", 42, UiStyle.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var subtitle := UiStyle.label("Merge your way from a tiny dev workshop to a complete software ecosystem.", 14, UiStyle.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	var continue_btn := UiStyle.make_button("Continue", UiStyle.GREEN, 18)
	continue_btn.disabled = not GameStateStore.instance.has_save
	continue_btn.pressed.connect(func() -> void:
		SaveGame.instance.load_existing = true
		SoundFx.instance.play("click")
		get_tree().change_scene_to_file("res://scenes/game.tscn"))
	vbox.add_child(continue_btn)
	_new_btn = UiStyle.make_button("New Game", UiStyle.ACCENT, 18)
	_new_btn.pressed.connect(_on_new_game)
	vbox.add_child(_new_btn)
	var help_btn := UiStyle.make_button("How to Play", Color("4A90D9"), 16)
	help_btn.pressed.connect(func() -> void: _help.show_help())
	vbox.add_child(help_btn)
	var sound_btn := UiStyle.make_button("Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off", Color("B9AC97"), 16)
	sound_btn.pressed.connect(func() -> void:
		GameStateStore.instance.sound_enabled = not GameStateStore.instance.sound_enabled
		sound_btn.text = "Sound: On" if GameStateStore.instance.sound_enabled else "Sound: Off")
	vbox.add_child(sound_btn)
	if not OS.has_feature("web"):
		var quit_btn := UiStyle.make_button("Quit", Color("B9AC97"), 16)
		quit_btn.pressed.connect(func() -> void: get_tree().quit())
		vbox.add_child(quit_btn)
	var version := UiStyle.label("Single-player • Saves locally • Works offline", 11, UiStyle.MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)
	_help = MergePopupPanel.new()
	_help.set_anchors_preset(Control.PRESET_CENTER)
	_help.custom_minimum_size = Vector2(620, 520)
	add_child(_help)

func _on_new_game() -> void:
	if GameStateStore.instance.has_save and not _confirming_new:
		_confirming_new = true
		_new_btn.text = "Overwrite existing save? Click again to confirm"
		SoundFx.instance.play("error")
		return
	SaveGame.instance.delete_save()
	SaveGame.instance.load_existing = false
	GameStateStore.instance.reset_new_game()
	SoundFx.instance.play("click")
	get_tree().change_scene_to_file("res://scenes/game.tscn")
