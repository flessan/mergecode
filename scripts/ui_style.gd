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
