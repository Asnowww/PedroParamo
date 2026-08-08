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

# 坟中倾听
var listen_root: Control = null
var listen_cfg := {}
var listen_sources: Array = []      # [{data, player(AudioStreamPlayer2D), done}]
var listen_aim := 0.0               # -90..90 度
var listen_lock := 0.0
var listen_target := -1
var listen_compass: TextureRect
var listen_counter: Label
var listen_lines: Array = []        # 捕捉到声音后的台词队列
var listen_after_card := ""

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
	if "--listentest" in args:                       # 自测：对准声源→捕捉→连点推进台词
		await get_tree().create_timer(0.6).timeout
		get_viewport().warp_mouse(Vector2(373, 540)) # 对应 angle=-55 的雨声
		await get_tree().create_timer(2.2).timeout
		print("CAPTURED: ", text_label.text)
		for k in range(3):
			for pressed in [true, false]:
				var ev := InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = pressed
				ev.position = Vector2(960, 900)
				Input.parse_input_event(ev)
			await get_tree().create_timer(0.4).timeout
			print("AFTER CLICK %d: " % (k + 1), text_label.text if dlg_panel.visible else "(面板已关闭)")
	for a in args:
		if a.begins_with("--clicks="):               # 自测：先连点 N 下
			await get_tree().create_timer(1.0).timeout
			for k in range(int(a.substr(9))):
				for pressed in [true, false]:
					var ev := InputEventMouseButton.new()
					ev.button_index = MOUSE_BUTTON_LEFT
					ev.pressed = pressed
					ev.position = Vector2(960, 540)
					Input.parse_input_event(ev)
				await get_tree().create_timer(0.25).timeout
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
	# 低语值改为隐性数值（2026-08-08 用户决定砍掉常驻侵蚀可视化）；
	# erosion.gdshader 保留，仅供 M4 中点死亡的一次性吞噬演出使用。
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
		elif op.has("death"):
			_play_death()
			return
		elif op.has("ending"):
			_play_ending()
			return
		elif op.has("listen"):
			dlg_panel.visible = false
			_build_listen(op["listen"])
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
	if listen_root != null:                        # 倾听中：点击只推进捕捉到的台词
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT and dlg_panel.visible:
			accept_event()
			_show_listen_line()
		return
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if state_credits:
			accept_event()
			get_tree().change_scene_to_file("res://scenes/title.tscn")
			return
		if waiting_click:
			accept_event()
			waiting_click = false
			if _in_ending():
				_show_ending_line()
			else:
				_advance()

func _in_ending() -> bool:
	return op_index < ops.size() and ops[op_index].has("ending")

# ---------- 中点死亡演出 ----------

func _play_death() -> void:
	dlg_panel.visible = false
	note_btn.visible = false
	cards_btn.visible = false
	var hb := AudioStreamPlayer.new()
	hb.stream = load("res://assets/audio/latido.wav")
	add_child(hb)
	hb.play()
	var er := ColorRect.new()
	er.set_anchors_preset(Control.PRESET_FULL_RECT)
	er.mouse_filter = Control.MOUSE_FILTER_STOP
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/erosion.gdshader")
	mat.set_shader_parameter("intensity", 0.0)
	er.material = mat
	add_child(er)
	var tw := create_tween()
	tw.tween_method(func(x): mat.set_shader_parameter("intensity", x), 0.0, 1.35, 3.4)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	bg_a.texture = Art.texture("woodcut_muerte_juan_01")
	bg_a.scale = Vector2.ONE
	var tw2 := create_tween()
	tw2.tween_method(func(x): mat.set_shader_parameter("intensity", x), 1.35, 0.0, 1.6)
	await tw2.finished
	er.queue_free()
	hb.stop()
	await get_tree().create_timer(2.0).timeout
	note_btn.visible = true
	cards_btn.visible = true
	_advance()

# ---------- 理解度结局（M6） ----------

const ENDING_DEEP := [
	["", "科马拉安静下来了。"],
	["", "现在你全都听见了：一封没有寄到的信，一场替来的婚，一匹找主人的马，一口井底的头颅骨，一场错认成节日的葬礼。"],
	["", "佩德罗·巴拉莫不是一个人——他是这片土地干死的原因。他把一切据为己有，最后连科马拉的死，也是他的私产。"],
	["", "而你，胡安·普雷西亚多，你要向他讨回的东西，其实在下山之前就死了。带你下山的，是他没有认下的儿子；埋你的，是替他拉过皮条的女人；隔壁躺着的，是他等了三十年的疯子。"],
	["", "全村人都在替他还债。这里没有冤魂——只有债。"],
	["多罗脱阿", "睡吧，胡安·普雷西亚多。你比谁都听得完整。往后地上有人走过，我们讲给他们听。"]
]
const ENDING_MID := [
	["", "科马拉安静下来了。"],
	["", "你听见了大半个村庄的声音：婚礼、马蹄、钟、狂欢的旗。它们在你的祭坛上排成了队，可是还有几支蜡烛没有点亮。"],
	["", "佩德罗·巴拉莫死了，像一堆石头一样。可他为什么放任全村饿死，你只听到了一半。"],
	["多罗脱阿", "睡吧，胡安·普雷西亚多。地底下有的是时间，那些没听完的，慢慢会渗下来的。"]
]
const ENDING_SHALLOW := [
	["", "科马拉安静下来了。"],
	["", "你听见一个老人死在皮椅上，像一堆石头。你听见许多声音，可它们没有连成一条路。"],
	["", "谁杀了谁，谁欠了谁，谁在等谁——这些声音还压在墙洞里、石块底下，等着你把它们摆上祭坛。"],
	["多罗脱阿", "睡吧，胡安·普雷西亚多。你听见的还太少。这个村庄的话，比它的死人还多。"]
]

var ending_lines: Array = []

func _play_ending() -> void:
	var n := GameState.unlocked_cards.size()
	if n >= 40:
		ending_lines = ENDING_DEEP.duplicate()
	elif n >= 26:
		ending_lines = ENDING_MID.duplicate()
	else:
		ending_lines = ENDING_SHALLOW.duplicate()
	_crossfade("present_cementerio_01")
	_show_ending_line()

func _show_ending_line() -> void:
	if ending_lines.is_empty():
		_roll_credits()
		return
	var line: Array = ending_lines.pop_front()
	dlg_panel.visible = true
	name_label.text = line[0]
	name_label.visible = line[0] != ""
	text_label.text = line[1]
	waiting_click = false
	await get_tree().create_timer(0.1).timeout
	waiting_click = true

func _roll_credits() -> void:
	dlg_panel.visible = false
	note_btn.visible = false
	cards_btn.visible = false
	_crossfade("ui_creditos_01")
	await get_tree().create_timer(1.2).timeout
	var cr := Label.new()
	cr.text = "佩德罗·巴拉莫\n\n原著 · 胡安·鲁尔福（屠孟超 译）\n改编与制作 · 你与 Claude\n美术生成 · CodeX Image\n引擎 · Godot 4\n\n谨以此 demo 致敬科马拉的亡魂\n\n—— 点击返回标题 ——"
	cr.add_theme_color_override("font_color", INK)
	cr.add_theme_font_size_override("font_size", 32)
	cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cr)
	ending_lines = []
	waiting_click = false
	state_credits = true

var state_credits := false

# ---------- 坟中倾听 ----------

func _build_listen(cfg: Dictionary) -> void:
	listen_cfg = cfg
	listen_sources = []
	listen_lock = 0.0
	listen_target = -1
	listen_root = Control.new()
	listen_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	listen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 否则吞掉点击，台词无法推进
	add_child(listen_root)
	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.01, 0.02, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_root.add_child(veil)
	var hint := Label.new()
	hint.text = cfg.get("hint", "左右移动鼠标，把耳朵转向声音；对准了，就停住。")
	hint.add_theme_color_override("font_color", DIM)
	hint.add_theme_font_size_override("font_size", 26)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_top = 70
	listen_root.add_child(hint)
	listen_counter = Label.new()
	listen_counter.add_theme_color_override("font_color", DIM)
	listen_counter.add_theme_font_size_override("font_size", 24)
	listen_counter.position = Vector2(920, 120)
	listen_root.add_child(listen_counter)
	listen_compass = TextureRect.new()
	listen_compass.texture = Art.texture("ui_oido_01")
	listen_compass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	listen_compass.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	listen_compass.size = Vector2(220, 220)
	listen_compass.position = Vector2(960 - 110, 540)
	listen_compass.pivot_offset = Vector2(110, 110)
	listen_compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_root.add_child(listen_compass)
	for s in cfg.get("sources", []):
		var p := AudioStreamPlayer2D.new()
		p.stream = load("res://assets/audio/%s.wav" % s["sound"])
		p.max_distance = 2400.0
		p.attenuation = 1.6
		listen_root.add_child(p)
		p.play()
		listen_sources.append({"data": s, "player": p, "done": false})
	_update_listen_counter()
	set_process(true)

func _update_listen_counter() -> void:
	var done := 0
	for s in listen_sources:
		if s["done"]:
			done += 1
	listen_counter.text = "听见 %d / %d" % [done, listen_sources.size()]

func _process(delta: float) -> void:
	if listen_root == null or not listen_lines.is_empty():
		return
	listen_aim = clampf((get_global_mouse_position().x - 960.0) / 960.0 * 90.0, -90.0, 90.0)
	listen_compass.rotation_degrees = listen_aim
	var best := -1
	var best_diff := 999.0
	for i in range(listen_sources.size()):
		var s: Dictionary = listen_sources[i]
		var diff: float = abs(float(s["data"]["angle"]) - listen_aim)
		var p: AudioStreamPlayer2D = s["player"]
		if s["done"]:
			p.volume_db = -60.0
			continue
		# 声源随"转头"在听者(屏幕中心)周围移动：正对时近而居中，偏离时远而偏侧
		var rel := deg_to_rad(float(s["data"]["angle"]) - listen_aim)
		var dist := 260.0 + (1.0 - cos(rel)) * 900.0
		p.position = Vector2(960, 540) + Vector2(sin(rel), -cos(rel) * 0.25) * dist
		if diff < best_diff:
			best_diff = diff
			best = i
	if best >= 0 and best_diff < 12.0:
		listen_compass.modulate = Color(1.0, 0.75, 0.4)
		if best == listen_target:
			listen_lock += delta
			if listen_lock >= 1.2:
				_capture_source(best)
		else:
			listen_target = best
			listen_lock = 0.0
	else:
		listen_compass.modulate = Color.WHITE
		listen_target = -1
		listen_lock = 0.0

func _capture_source(i: int) -> void:
	var s: Dictionary = listen_sources[i]
	s["done"] = true
	listen_lock = 0.0
	listen_target = -1
	_update_listen_counter()
	listen_after_card = s["data"].get("card", "")
	listen_lines = s["data"].get("lines", []).duplicate()
	_show_listen_line()

func _show_listen_line() -> void:
	if listen_lines.is_empty():
		dlg_panel.visible = false
		if listen_after_card != "":
			GameState.unlock_card(listen_after_card)
			_show_toast("✚ 拾得记忆碎片 · " + CardDb.title_of(listen_after_card))
			listen_after_card = ""
		var all_done := true
		for s in listen_sources:
			if not s["done"]:
				all_done = false
		if all_done:
			_end_listen()
		return
	var line: Array = listen_lines.pop_front()
	dlg_panel.visible = true
	name_label.text = line[0]
	name_label.visible = line[0] != ""
	text_label.text = line[1]

func _end_listen() -> void:
	for s in listen_sources:
		(s["player"] as AudioStreamPlayer2D).stop()
	listen_root.queue_free()
	listen_root = null
	set_process(false)
	_advance()

# ---------- 拼图板（通用 N 卡） ----------

func _build_puzzle(cfg: Dictionary) -> void:
	puzzle_active = true
	puzzle_order = cfg.get("order", [])
	var lore: Dictionary = cfg.get("lore", {})
	var n := puzzle_order.size()
	puzzle_root = Control.new()
	puzzle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	puzzle_root.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 卡牌自己收事件，根层放行
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
