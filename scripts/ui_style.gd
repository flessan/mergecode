class_name UiStyle
extends RefCounted
## Shared rounded, colourful (non-neon) styling helpers for all UI.

const BG := Color("FFF6EC")
const PANEL := Color("FFFFFF")
const INK := Color("2E2A26")
const MUTED := Color("8A8073")
const ACCENT := Color("E8873A")
const GREEN := Color("4CAF7D")
const RED := Color("D9604A")
const CELL_EMPTY := Color("F1E7D8")
const CELL_LOCKED := Color("DDD3C2")
const KENNEY_DIR := "res://assets/ui/Kenney/"

static func hex(h: String) -> Color:
	return Color.html("#" + h)

static func panel_style(bg: Color = PANEL, radius: int = 14, border: Color = Color(0, 0, 0, 0.06)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(12)
	s.shadow_color = Color(0.2, 0.12, 0.05, 0.10)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 2)
	return s

static func button_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(10)
	s.set_content_margin_all(8)
	return s


static func Kenney_path(file_name: String) -> String:
	return KENNEY_DIR + file_name

static func Kenney_texture_style(file_name: String, texture_margin: float = 18.0, content_margin: float = 10.0, tint: Color = Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load_tex(Kenney_path(file_name))
	style.texture_margin_left = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_bottom = texture_margin
	style.set_content_margin_all(content_margin)
	style.modulate_color = tint
	return style

static func Kenney_panel_style(color_name: String = "grey", tint: Color = Color.WHITE) -> StyleBoxTexture:
	return Kenney_texture_style(color_name + "_panel.png", 18.0, 12.0, tint)

static func Kenney_slot_style(locked: bool = false) -> StyleBoxTexture:
	# A warm, recessed-looking board slot made from Kenney's light grey panel.
	var tint := Color(0.52, 0.42, 0.30, 0.88) if locked else Color(0.78, 0.63, 0.43, 0.82)
	return Kenney_texture_style("grey_panel.png", 16.0, 4.0, tint)

static func _Kenney_button_styles(b: Button, color_name: String) -> void:
	var normal := Kenney_texture_style(color_name + "_button02.png", 22.0, 7.0)
	var hover := Kenney_texture_style(color_name + "_button02.png", 22.0, 7.0, Color(1.07, 1.07, 1.07, 1.0))
	var pressed := Kenney_texture_style(color_name + "_button05.png", 22.0, 7.0, Color(0.92, 0.92, 0.92, 1.0))
	var disabled := Kenney_texture_style("grey_button02.png", 22.0, 7.0, Color(0.82, 0.82, 0.82, 0.75))
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", Kenney_texture_style(color_name + "_button01.png", 22.0, 7.0))
	b.add_theme_stylebox_override("disabled", disabled)

static func make_Kenney_button(text: String, color_name: String = "blue", font_size: int = 14, dark_text: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	b.add_theme_font_size_override("font_size", font_size)
	var font_color := INK if dark_text else Color.WHITE
	var disabled_color := Color(0.35, 0.32, 0.28, 0.75)
	b.add_theme_color_override("font_color", font_color)
	b.add_theme_color_override("font_hover_color", font_color)
	b.add_theme_color_override("font_pressed_color", font_color)
	b.add_theme_color_override("font_focus_color", font_color)
	b.add_theme_color_override("font_disabled_color", disabled_color)
	b.add_theme_color_override("icon_normal_color", font_color)
	b.add_theme_color_override("icon_hover_color", font_color)
	b.add_theme_color_override("icon_pressed_color", font_color)
	b.add_theme_color_override("icon_disabled_color", disabled_color)
	_Kenney_button_styles(b, color_name)
	return b

static func make_Kenney_icon_button(icon_path: String, text: String, color_name: String = "blue", font_size: int = 14, dark_text: bool = false) -> Button:
	var b := make_Kenney_button(text, color_name, font_size, dark_text)
	b.icon = load_tex(icon_path)
	b.expand_icon = false
	return b

static func style_Kenney_progress(bar: ProgressBar, fill_color_name: String = "blue") -> void:
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", Kenney_texture_style("grey_panel.png", 10.0, 2.0, Color(0.86, 0.82, 0.74, 1.0)))
	bar.add_theme_stylebox_override("fill", Kenney_texture_style(fill_color_name + "_panel.png", 10.0, 2.0))

static func make_button(text: String, bg: Color = ACCENT, font_size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", button_style(bg))
	b.add_theme_stylebox_override("hover", button_style(bg.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", button_style(bg.darkened(0.12)))
	b.add_theme_stylebox_override("disabled", button_style(Color("CFC6B8")))
	b.custom_minimum_size = Vector2(0, 38)
	return b

static func label(text: String, size: int = 15, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_size_override("font_size", size)  # default font; size conveys emphasis
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func load_tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func icon_rect(path: String, min_size: Vector2, tint: Color = Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load_tex(path)
	t.custom_minimum_size = min_size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

## Button with a leading icon (TextureButton can't show text, so this is a
## regular Button using its built-in icon support).
static func make_icon_button(icon_path: String, text: String, bg: Color = ACCENT, font_size: int = 14) -> Button:
	var b := make_button(text, bg, font_size)
	b.icon = load_tex(icon_path)
	b.expand_icon = false
	return b

static func chip(text: String, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg, 9, Color(0, 0, 0, 0.04)))
	var l := label(text, 12, Color.WHITE)
	p.add_child(l)
	return p
