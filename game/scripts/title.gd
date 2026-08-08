extends Control
## 标题画面：开始 / 继续 / 章节 / 离开

const INK := Color(0.93, 0.89, 0.80)
const DIM := Color(0.93, 0.89, 0.80, 0.55)
const MARIGOLD := Color(0.91, 0.57, 0.18)

## 章节 → 起始碎片（与各碎片的 title 操作码一致）
const CHAPTERS := [
	["序章 · 下山", "F01", "母亲的遗言，和一个自称同父的赶驴人"],
	["第一章 · 空村投宿", "F04", "爱杜薇海斯开门：是你母亲通知我的"],
	["第二章 · 回声", "F14", "安娜的控诉，神父的金币，满村的低语"],
	["第三章 · 塌了一半的屋顶", "F28", "多尼斯兄妹，与八月的闷热"],
	["第四章 · 坟中", "F33", "你已经死了。现在，学着用耳朵看"],
	["第五章 · 半月庄", "F18", "账本、婚事、界桩：一座庄园如何长大"],
	["第六章 · 苏萨娜", "F36", "他等了三十年的女人，从不属于他"],
	["第七章 · 钟声", "F55", "三日不停的钟，与一场错认的节日"],
	["第八章 · 崩塌", "F58", "石头一样的老人，和黎明的那把刀"],
]

var chapter_panel: PanelContainer

func _ready() -> void:
	theme = UiTheme.build()
	var bg := TextureRect.new()
	bg.texture = Art.texture("ui_titulo_01")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var vb := VBoxContainer.new()
	vb.position = Vector2(860, 700)
	vb.add_theme_constant_override("separation", 16)
	add_child(vb)
	_mk_btn(vb, "开 始", func():
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/story.tscn"))
	var cont := _mk_btn(vb, "继 续", func():
		GameState.load_save()
		get_tree().change_scene_to_file("res://scenes/story.tscn"))
	cont.disabled = not GameState.has_save()
	_mk_btn(vb, "章 节", _toggle_chapters)
	_mk_btn(vb, "离 开", func(): get_tree().quit())
	_build_chapter_panel()
	var args := OS.get_cmdline_user_args()
	if "--chapters" in args:
		_toggle_chapters()
	for a in args:
		if a.begins_with("--shot="):
			await get_tree().create_timer(1.5).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()

func _mk_btn(parent: Control, label: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 32)
	b.custom_minimum_size = Vector2(200, 58)
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

func _build_chapter_panel() -> void:
	chapter_panel = PanelContainer.new()
	chapter_panel.add_theme_stylebox_override("panel", UiTheme.panel_box())
	chapter_panel.position = Vector2(430, 120)
	chapter_panel.size = Vector2(1060, 840)
	chapter_panel.visible = false
	add_child(chapter_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	chapter_panel.add_child(vb)
	var t := Label.new()
	t.text = "从哪一段听起？"
	t.add_theme_color_override("font_color", INK)
	t.add_theme_font_size_override("font_size", 34)
	vb.add_child(t)
	var h := Label.new()
	h.text = "（跳章会自动补齐此前拾得的碎片与遇见的人，但那些声音你没有亲耳听过）"
	h.add_theme_color_override("font_color", DIM)
	h.add_theme_font_size_override("font_size", 19)
	vb.add_child(h)
	for ch in CHAPTERS:
		# 两列：章节名定宽 + 描述列，保证所有描述左边界严格对齐
		var row := Button.new()
		row.custom_minimum_size = Vector2(1000, 68)
		row.pressed.connect(func():
			GameState.fast_forward_to(ch[1])
			get_tree().change_scene_to_file("res://scenes/story.tscn"))
		vb.add_child(row)
		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 24
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_theme_constant_override("separation", 0)
		row.add_child(hb)
		var name_lbl := Label.new()
		name_lbl.text = ch[0]
		name_lbl.custom_minimum_size = Vector2(300, 0)   # 定宽列
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", INK)
		name_lbl.add_theme_font_size_override("font_size", 26)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = ch[2]
		desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_color_override("font_color", DIM)
		desc_lbl.add_theme_font_size_override("font_size", 24)
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(desc_lbl)
	var back := Button.new()
	back.text = "返 回"
	back.custom_minimum_size = Vector2(180, 54)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(_toggle_chapters)
	vb.add_child(back)

func _toggle_chapters() -> void:
	chapter_panel.visible = not chapter_panel.visible
