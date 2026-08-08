extends Control
## 通用碎片播放器：读取 data/fragments/<ID>.json 顺序执行操作码
## 操作码：bg / who+text / whisper / meet / card / puzzle / title / next
## 测试参数：--fragment=F0N 直接跳碎片；--shot=path 截图退出；--fastclick 自动快进

const INK := Color(0.93, 0.89, 0.80)
const DIM := Color(0.93, 0.89, 0.80, 0.55)
const MARIGOLD := Color(0.91, 0.57, 0.18)

var ops: Array = []
var op_index := -1
var waiting_click := false
var puzzle_active := false

var bg_a: TextureRect
var bg_b: TextureRect
var erosion: ColorRect
var dlg_panel: PanelContainer
var name_label: Label
var text_label: RichTextLabel
var toast: Label
var note_btn: Button
var note_panel: PanelContainer
var note_list: VBoxContainer
var cards_btn: Button
var album: Control
var cards_grid: GridContainer
var card_detail: PanelContainer = null
var overlay_label: Label

var slots: Array = []
var cards: Array = []
var candles: Array = []
var puzzle_order: Array = []
var puzzle_root: Control = null
var drag_card: TextureRect = null
var drag_offset := Vector2.ZERO

func _ready() -> void:
	theme = UiTheme.build()
	_build_layers()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--fragment="):
			GameState.current_fragment = a.substr(11)
	_load_fragment(GameState.current_fragment)
	if "--givecards" in args:                      # 自测：解锁全部已录卡并打开卡册
		for id in CardDb.cards.keys():
			GameState.unlock_card(id)
		_toggle_cards()
	if "--carddetail" in args:
		_show_card_detail("card_16_rebozo")
	if "--shownotes" in args:
		GameState.meet("阿文迪奥")
		GameState.meet("爱杜薇海斯")
		_toggle_notebook()
	for a in args:
		if a.begins_with("--shot="):
			await get_tree().create_timer(2.0).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()

func _build_layers() -> void:
	for i in range(2):
		var t := TextureRect.new()
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.set_anchors_preset(Control.PRESET_FULL_RECT)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.pivot_offset = Vector2(960, 540)
		add_child(t)
		if i == 0: bg_a = t
		else: bg_b = t
	bg_b.modulate.a = 0.0
	var tw := create_tween().set_loops()
	tw.tween_property(bg_a, "scale", Vector2(1.06, 1.06), 22.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bg_a, "scale", Vector2(1.0, 1.0), 22.0).set_trans(Tween.TRANS_SINE)
	erosion = ColorRect.new()
	erosion.set_anchors_preset(Control.PRESET_FULL_RECT)
	erosion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/erosion.gdshader")
	mat.set_shader_parameter("intensity", GameState.whisper)
	erosion.material = mat
	add_child(erosion)
	# 对话框
	dlg_panel = PanelContainer.new()
	dlg_panel.add_theme_stylebox_override("panel", UiTheme.panel_box())
	dlg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg_panel.offset_left = 240; dlg_panel.offset_right = -240
	dlg_panel.offset_top = -250; dlg_panel.offset_bottom = -56
	add_child(dlg_panel)
	var vb := VBoxContainer.new()
	dlg_panel.add_child(vb)
	name_label = Label.new()
	name_label.add_theme_color_override("font_color", MARIGOLD)
	name_label.add_theme_font_size_override("font_size", 30)
	vb.add_child(name_label)
	text_label = RichTextLabel.new()
	text_label.fit_content = true
	text_label.add_theme_color_override("default_color", INK)
	text_label.add_theme_font_size_override("normal_font_size", 34)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(text_label)
	var hint := Label.new()
	hint.text = "点击继续 ▸"
	hint.add_theme_color_override("font_color", DIM)
	hint.add_theme_font_size_override("font_size", 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(hint)
	# 碎片获得提示
	toast = Label.new()
	toast.add_theme_color_override("font_color", MARIGOLD)
	toast.add_theme_font_size_override("font_size", 26)
	toast.position = Vector2(48, 52)               # 左上角，与右上笔记按钮同高
	toast.modulate.a = 0.0
	add_child(toast)
	# 笔记按钮与面板
	note_btn = Button.new()
	note_btn.text = "笔 记"
	note_btn.position = Vector2(1740, 40)
	note_btn.size = Vector2(140, 56)
	note_btn.add_theme_font_size_override("font_size", 24)
	note_btn.pressed.connect(_toggle_notebook)
	add_child(note_btn)
	note_panel = PanelContainer.new()
	note_panel.add_theme_stylebox_override("panel", UiTheme.panel_box())
	note_panel.position = Vector2(1270, 40)        # 右缘贴笔记按钮左缘(1740)，顶与按钮平齐
	note_panel.size = Vector2(460, 500)
	note_panel.visible = false
	add_child(note_panel)
	var nv := VBoxContainer.new()
	note_panel.add_child(nv)
	var nt := Label.new()
	nt.text = "生者，还是死者？"
	nt.add_theme_color_override("font_color", INK)
	nt.add_theme_font_size_override("font_size", 28)
	nv.add_child(nt)
	var hintl := Label.new()
	hintl.text = "（点人名切换你的判断，无人验证对错）"
	hintl.add_theme_color_override("font_color", DIM)
	hintl.add_theme_font_size_override("font_size", 18)
	nv.add_child(hintl)
	note_list = VBoxContainer.new()
	nv.add_child(note_list)
	# 碎片卡册按钮与面板
	cards_btn = Button.new()
	cards_btn.text = "碎 片"
	cards_btn.position = Vector2(1740, 108)
	cards_btn.size = Vector2(140, 56)
	cards_btn.add_theme_font_size_override("font_size", 24)
	cards_btn.pressed.connect(_toggle_cards)
	add_child(cards_btn)
	# 全屏祭坛卡册
	album = Control.new()
	album.set_anchors_preset(Control.PRESET_FULL_RECT)
	album.visible = false
	add_child(album)
	var abg := TextureRect.new()
	abg.texture = Art.texture("ui_cardalbum_01")
	abg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	abg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	abg.set_anchors_preset(Control.PRESET_FULL_RECT)
	album.add_child(abg)
	var ct := Label.new()
	ct.text = "拾 得 的 记 忆"
	ct.add_theme_color_override("font_color", INK)
	ct.add_theme_font_size_override("font_size", 34)
	ct.position = Vector2(860, 190)
	album.add_child(ct)
	var back := Button.new()
	back.text = "返 回"
	back.position = Vector2(1730, 42)
	back.size = Vector2(150, 60)
	back.add_theme_font_size_override("font_size", 26)
	back.pressed.connect(_toggle_cards)
	album.add_child(back)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(500, 270)
	scroll.size = Vector2(920, 620)
	album.add_child(scroll)
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(900, 0)
	scroll.add_child(center)
	cards_grid = GridContainer.new()
	cards_grid.columns = 4
	cards_grid.add_theme_constant_override("h_separation", 36)
	cards_grid.add_theme_constant_override("v_separation", 26)
	center.add_child(cards_grid)
	# 全屏文字（章节标题/结束）
	overlay_label = Label.new()
	overlay_label.add_theme_color_override("font_color", INK)
	overlay_label.add_theme_font_size_override("font_size", 46)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_label.visible = false
	add_child(overlay_label)

func _load_fragment(id: String) -> void:
	var path := "res://data/fragments/%s.json" % id
	if not FileAccess.file_exists(path):
		push_error("碎片脚本缺失: " + id)
		return
	GameState.current_fragment = id
	if not GameState.seen_fragments.has(id):
		GameState.seen_fragments.append(id)
	GameState.save()
	ops = JSON.parse_string(FileAccess.get_file_as_string(path)).get("ops", [])
	op_index = -1
	_advance()

func _advance() -> void:
	while true:
		op_index += 1
		if op_index >= ops.size():
			return
		var op: Dictionary = ops[op_index]
		if op.has("bg"):
			_crossfade(op["bg"])
		elif op.has("whisper"):
			_set_whisper(GameState.whisper + float(op["whisper"]))
		elif op.has("meet"):
			GameState.meet(op["meet"])
		elif op.has("card"):
			GameState.unlock_card(op["card"])
			_show_toast("✚ 拾得记忆碎片 · " + CardDb.title_of(op["card"]))
		elif op.has("title"):
			dlg_panel.visible = false
			overlay_label.text = op["title"]
			overlay_label.visible = true
			waiting_click = true
			return
		elif op.has("puzzle"):
			dlg_panel.visible = false
			_build_puzzle(op["puzzle"])
			return
		elif op.has("text"):
			overlay_label.visible = false
			dlg_panel.visible = true
			name_label.text = op.get("who", "")
			name_label.visible = name_label.text != ""
			text_label.text = op["text"]
			_set_whisper(GameState.whisper + 0.002)   # 每句微升（全流程配速）
			waiting_click = true
			return
		elif op.has("next"):
			var nxt: String = op["next"]
			if nxt == "end":
				get_tree().change_scene_to_file("res://scenes/title.tscn")
			else:
				_load_fragment(nxt)
			return

func _crossfade(name: String) -> void:
	bg_b.texture = Art.texture(name)
	bg_b.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(bg_b, "modulate:a", 1.0, 0.9)
	tw.tween_callback(func():
		bg_a.texture = bg_b.texture
		bg_a.modulate.a = 1.0
		bg_b.modulate.a = 0.0)

func _set_whisper(v: float) -> void:
	GameState.whisper = clampf(maxf(GameState.whisper, v), 0.0, 1.0)
	var tw := create_tween()
	tw.tween_method(func(x): erosion.material.set_shader_parameter("intensity", x),
		erosion.material.get_shader_parameter("intensity"), GameState.whisper, 1.0)

func _show_toast(t: String) -> void:
	toast.text = t
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.6)

func _toggle_notebook() -> void:
	note_panel.visible = not note_panel.visible
	album.visible = false
	if note_panel.visible:
		_refresh_notebook()

func _toggle_cards() -> void:
	album.visible = not album.visible
	note_panel.visible = false
	if album.visible:
		_refresh_cards()
	elif card_detail != null:
		card_detail.queue_free()
		card_detail = null

func _refresh_cards() -> void:
	for c in cards_grid.get_children():
		c.queue_free()
	if GameState.unlocked_cards.is_empty():
		var empty := Label.new()
		empty.text = "还没有拾得任何碎片。"
		empty.add_theme_color_override("font_color", DIM)
		empty.add_theme_font_size_override("font_size", 24)
		cards_grid.add_child(empty)
		return
	for id in GameState.unlocked_cards:
		var box := VBoxContainer.new()
		var thumb := TextureButton.new()
		thumb.texture_normal = Art.texture(id)
		thumb.ignore_texture_size = true
		thumb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
		thumb.custom_minimum_size = Vector2(150, 230)
		thumb.pressed.connect(_show_card_detail.bind(id))
		box.add_child(thumb)
		var t := Label.new()
		t.text = CardDb.title_of(id)
		t.add_theme_color_override("font_color", INK)
		t.add_theme_font_size_override("font_size", 22)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(t)
		cards_grid.add_child(box)

func _show_card_detail(id: String) -> void:
	if card_detail != null:
		card_detail.queue_free()
	# 背景压暗（不模糊），把注意力收到详情框上
	var blur := ColorRect.new()
	blur.color = Color(0.02, 0.02, 0.03, 0.72)
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blur)
	card_detail = PanelContainer.new()
	card_detail.add_theme_stylebox_override("panel", UiTheme.glass_box())
	card_detail.position = Vector2(460, 190)
	card_detail.size = Vector2(1000, 700)
	add_child(card_detail)
	card_detail.tree_exiting.connect(func():
		if is_instance_valid(blur):
			blur.queue_free())
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	card_detail.add_child(hb)
	var big := TextureRect.new()
	big.texture = Art.texture(id)
	big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	big.custom_minimum_size = Vector2(400, 620)
	hb.add_child(big)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var tt := Label.new()
	tt.text = CardDb.title_of(id)
	tt.add_theme_color_override("font_color", MARIGOLD)
	tt.add_theme_font_size_override("font_size", 36)
	right.add_child(tt)
	var lore := RichTextLabel.new()
	lore.text = CardDb.lore_of(id)
	lore.fit_content = true
	lore.add_theme_color_override("default_color", INK)
	lore.add_theme_font_size_override("normal_font_size", 28)
	lore.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(lore)
	var close := Button.new()
	close.text = "合 上"
	close.add_theme_font_size_override("font_size", 24)
	close.custom_minimum_size = Vector2(140, 52)
	close.pressed.connect(func():
		card_detail.queue_free()
		card_detail = null)
	right.add_child(close)

const MARKS := ["？ 说不清", "☀ 活人", "✝ 死人"]

func _refresh_notebook() -> void:
	for c in note_list.get_children():
		c.queue_free()
	for person in GameState.notebook.keys():
		var b := Button.new()
		b.text = "%s　—— %s" % [person, MARKS[int(GameState.notebook[person])]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 26)
		b.pressed.connect(func():
			GameState.cycle_mark(person)
			GameState.save()
			_refresh_notebook())
		note_list.add_child(b)

func _gui_input(event: InputEvent) -> void:
	if puzzle_active:
		if event is InputEventMouseButton and not event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT and drag_card != null:
			_drop_card(drag_card)
			drag_card = null
		elif event is InputEventMouseMotion and drag_card != null:
			drag_card.global_position = get_global_mouse_position() - drag_offset
		return
	if album.visible or note_panel.visible:        # 卡册/笔记打开时不推进剧情
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and waiting_click:
		accept_event()
		waiting_click = false
		_advance()

# ---------- 拼图板（通用 N 卡） ----------

func _build_puzzle(cfg: Dictionary) -> void:
	puzzle_active = true
	puzzle_order = cfg.get("order", [])
	var lore: Dictionary = cfg.get("lore", {})
	var n := puzzle_order.size()
	puzzle_root = Control.new()
	puzzle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(puzzle_root)
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.025, 0.04, 0.72)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puzzle_root.add_child(veil)
	var title := Label.new()
	title.text = cfg.get("title", "把记忆按发生的先后摆上祭坛")
	title.add_theme_color_override("font_color", INK)
	title.add_theme_font_size_override("font_size", 40)
	title.position = Vector2(960 - 260, 80)
	puzzle_root.add_child(title)
	var total_w := n * 280 + (n - 1) * 60
	var x0 := (1920 - total_w) / 2.0
	slots = []; cards = []; candles = []
	for i in range(n):
		var slot := Panel.new()
		slot.add_theme_stylebox_override("panel", UiTheme.slot_box())
		slot.position = Vector2(x0 + i * 340, 260)
		slot.size = Vector2(280, 420)
		puzzle_root.add_child(slot)
		slots.append(slot)
		var cn := TextureRect.new()
		cn.texture = load("res://assets/candle_unlit.png")
		cn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		cn.size = Vector2(84, 126)
		cn.position = slot.position + Vector2(98, -134)
		cn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puzzle_root.add_child(cn)
		candles.append(cn)
	var shuffled := puzzle_order.duplicate()
	shuffled.shuffle()
	if shuffled == puzzle_order:
		shuffled.reverse()
	for i in range(n):
		var card := TextureRect.new()
		card.texture = Art.texture(shuffled[i])
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		card.size = Vector2(240, 370)
		card.position = Vector2(x0 + 20 + i * 340, 692)
		card.set_meta("id", shuffled[i])
		card.tooltip_text = lore.get(shuffled[i],
			CardDb.title_of(shuffled[i]) + "\n\n" + CardDb.lore_of(shuffled[i]))
		card.gui_input.connect(_on_card_input.bind(card))
		puzzle_root.add_child(card)
		cards.append(card)

func _on_card_input(event: InputEvent, card: TextureRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_card = card
			drag_offset = card.get_global_mouse_position() - card.global_position
			card.move_to_front()
			card.set_meta("slot", -1)
			_update_candles()
		else:
			if drag_card == card:
				_drop_card(card)
			drag_card = null
	elif event is InputEventMouseMotion and drag_card == card:
		card.global_position = card.get_global_mouse_position() - drag_offset

func _drop_card(card: TextureRect) -> void:
	for slot in slots:
		if slot.get_global_rect().has_point(card.get_global_mouse_position()):
			var idx := slots.find(slot)
			for other in cards:
				if other != card and other.has_meta("slot") and int(other.get_meta("slot")) == idx:
					card.set_meta("slot", -1)
					card.position += Vector2(0, 48)
					return
			card.global_position = slot.global_position + (slot.size - card.size) / 2.0
			card.set_meta("slot", idx)
			if String(card.get_meta("id")) != puzzle_order[idx]:
				_set_whisper(GameState.whisper + 0.03)
			_update_candles()
			return
	card.set_meta("slot", -1)
	_update_candles()

func _update_candles() -> void:
	var lit := load("res://assets/candle_lit.png")
	var unlit := load("res://assets/candle_unlit.png")
	var correct := 0
	for i in range(puzzle_order.size()):
		var good := false
		for card in cards:
			if card.has_meta("slot") and int(card.get_meta("slot")) == i \
					and String(card.get_meta("id")) == puzzle_order[i]:
				good = true
				break
		candles[i].texture = lit if good else unlit
		if good:
			correct += 1
	if correct == puzzle_order.size():
		puzzle_active = false
		_set_whisper(GameState.whisper + 0.15)
		await get_tree().create_timer(1.4).timeout
		puzzle_root.queue_free()
		_advance()
