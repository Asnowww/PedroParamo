class_name UiTheme
## 共享 UI 主题：老纸墨色 + 烛金边框

static func build() -> Theme:
	var th := Theme.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.085, 0.07, 0.96)
	sb.border_color = Color(0.78, 0.62, 0.32)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	sb.set_corner_radius_all(4)
	th.set_stylebox("panel", "TooltipPanel", sb)
	th.set_color("font_color", "TooltipLabel", Color(0.93, 0.89, 0.80))
	th.set_font_size("font_size", "TooltipLabel", 26)
	return th

static func panel_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.045, 0.06, 0.85)
	sb.border_color = Color(0.55, 0.48, 0.36)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(24)
	return sb

static func glass_box() -> StyleBoxFlat:
	## 卡片详情面板：不透明深墨底 + 烛金细边
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.075, 0.065, 1.0)
	sb.border_color = Color(0.82, 0.68, 0.40)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(28)
	sb.set_corner_radius_all(8)
	return sb

static func slot_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.07, 0.6)
	sb.border_color = Color(0.55, 0.48, 0.36)
	sb.set_border_width_all(2)
	return sb
