extends Control
## 标题画面：开始 / 继续 / 退出

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
	vb.position = Vector2(860, 740)
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)
	_mk_btn(vb, "开 始", func():
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/story.tscn"))
	var cont := _mk_btn(vb, "继 续", func():
		GameState.load_save()
		get_tree().change_scene_to_file("res://scenes/story.tscn"))
	cont.disabled = not GameState.has_save()
	_mk_btn(vb, "离 开", func(): get_tree().quit())
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--fragment="):        # 测试直跳
			get_tree().change_scene_to_file.call_deferred("res://scenes/story.tscn")
		if a.begins_with("--shot="):
			await get_tree().create_timer(1.5).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()

func _mk_btn(parent: Control, label: String, fn: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 34)
	b.custom_minimum_size = Vector2(200, 64)
	b.pressed.connect(fn)
	parent.add_child(b)
	return b
