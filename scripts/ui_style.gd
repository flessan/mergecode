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

static func chip(text: String, bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg, 9, Color(0, 0, 0, 0.04)))
	var l := label(text, 12, Color.WHITE)
	p.add_child(l)
	return p
