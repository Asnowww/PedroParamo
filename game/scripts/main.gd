extends Control
## 垂直切片：爱杜薇海斯的家（F04）
## 流程：Ken Burns 背景 -> 对话 -> 三卡迷你拼图板 -> 低语侵蚀展示 -> 结束卡
## 自测：命令行 -- --shot=路径 会在 2.2 秒后截图退出。

const INK := Color(0.93, 0.89, 0.80)          # 纸白
const DIM := Color(0.93, 0.89, 0.80, 0.55)
const MARIGOLD := Color(0.91, 0.57, 0.18)      # 万寿菊橙（全游戏唯一饱和引导色）

var whisper := 0.0                              # 低语值 0..1，只升不降
var dialogue := [
	["", "雨中的科马拉。有人给我开了门。"],
	["爱杜薇海斯", "请进来吧。"],
	["我", "（她好像一直在等我。屋里堆满了别人寄存的家具。）"],
	["爱杜薇海斯", "是你母亲通知我说你要来。"],
	["我", "我母亲……她七天前就死了。"],
	["爱杜薇海斯", "……原来是这样。怪不得她的声音听起来那么远。"],
	["我", "（这句话像一滴冷水，顺着后颈流了下去。）"],
	["爱杜薇海斯", "房间在里头。你先歇着，天亮再看这村子。"],
	["", "我躺下时想：这些声音，白天听不见的，一到夜里就都醒了。"],
]
var d_index := 0
var state := "dialogue"                          # dialogue -> puzzle -> done

var bg: TextureRect
var erosion: ColorRect
var dlg_panel: PanelContainer
var name_label: Label
var text_label: RichTextLabel
var puzzle_root: Control
var slots: Array = []                            # 3 个槽位 Control
var cards: Array = []                            # 3 张卡 TextureRect
var correct_order := ["card_16_rebozo", "card_11_puerta", "card_13_muebles"]
var drag_card: TextureRect = null
var drag_offset := Vector2.ZERO
var candles: Array = []
var end_label: Label

func _ready() -> void:
	_build_bg()
	_build_erosion()
	_build_dialogue()
	_show_line()
	var args := OS.get_cmdline_user_args()
	if "--state=puzzle" in args:
		state = "puzzle"
		dlg_panel.visible = false
		_set_whisper(0.55)
		_build_puzzle()
	if "--clicktest" in args:
		await get_tree().create_timer(1.0).timeout
		for pressed in [true, false]:
			var ev := InputEventMouseButton.new()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = pressed
			ev.position = Vector2(960, 540)
			Input.parse_input_event(ev)
	for a in args:
		if a.begins_with("--shot="):
			await get_tree().create_timer(2.2).timeout
			var img := get_viewport().get_texture().get_image()
			img.save_png(a.substr(7))
			get_tree().quit()

func _build_bg() -> void:
	bg = TextureRect.new()
	bg.texture = load("res://assets/present_eduviges_sala_01.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# Ken Burns：缓慢放大 + 平移，40 秒一个来回
	bg.pivot_offset = Vector2(960, 540)
	var tw := create_tween().set_loops()
	tw.tween_property(bg, "scale", Vector2(1.08, 1.08), 20.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(bg, "scale", Vector2(1.0, 1.0), 20.0).set_trans(Tween.TRANS_SINE)

func _build_erosion() -> void:
	erosion = ColorRect.new()
	erosion.set_anchors_preset(Control.PRESET_FULL_RECT)
	erosion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/erosion.gdshader")
	mat.set_shader_parameter("intensity", 0.0)
	erosion.material = mat
	add_child(erosion)

func _set_whisper(v: float) -> void:
	whisper = clampf(maxf(whisper, v), 0.0, 1.0)   # 只升不降
	var tw := create_tween()
	tw.tween_method(func(x): erosion.material.set_shader_parameter("intensity", x),
		erosion.material.get_shader_parameter("intensity"), whisper, 1.2)

func _build_dialogue() -> void:
	dlg_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.045, 0.06, 0.82)
	sb.border_color = Color(0.55, 0.48, 0.36)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(24)
	dlg_panel.add_theme_stylebox_override("panel", sb)
	dlg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dlg_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dlg_panel.offset_left = 240
	dlg_panel.offset_right = -240
	dlg_panel.offset_top = -260
	dlg_panel.offset_bottom = -60
	add_child(dlg_panel)
	var vb := VBoxContainer.new()
	dlg_panel.add_child(vb)
	name_label = Label.new()
	name_label.add_theme_color_override("font_color", MARIGOLD)
	name_label.add_theme_font_size_override("font_size", 30)
	vb.add_child(name_label)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = false
	text_label.fit_content = true
	text_label.add_theme_color_override("default_color", INK)
	text_label.add_theme_font_size_override("normal_font_size", 34)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(text_label)
	var hint := Label.new()
	hint.text = "点击继续 ▸"
	hint.add_theme_color_override("font_color", DIM)
	hint.add_theme_font_size_override("font_size", 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(hint)

func _show_line() -> void:
	var line: Array = dialogue[d_index]
	name_label.text = line[0]
	name_label.visible = line[0] != ""
	text_label.text = line[1]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if state == "dialogue":
				accept_event()
				d_index += 1
				_set_whisper(whisper + 0.06)      # 每推进一句，低语上升
				if d_index < dialogue.size():
					_show_line()
				else:
					state = "puzzle"
					dlg_panel.visible = false
					_build_puzzle()
		elif drag_card != null:                    # 在卡面外松手也能落卡
			_drop_card(drag_card)
			drag_card = null
	elif event is InputEventMouseMotion and drag_card != null:
		drag_card.global_position = get_global_mouse_position() - drag_offset

# ---------- 迷你拼图板 ----------

func _build_puzzle() -> void:
	puzzle_root = Control.new()
	puzzle_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(puzzle_root)
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.025, 0.04, 0.72)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	puzzle_root.add_child(veil)
	var title := Label.new()
	title.text = "把记忆按发生的先后摆上祭坛"
	title.add_theme_color_override("font_color", INK)
	title.add_theme_font_size_override("font_size", 40)
	title.position = Vector2(660, 90)
	puzzle_root.add_child(title)
	# 三个槽位
	for i in range(3):
		var slot := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.08, 0.07, 0.6)
		sb.border_color = Color(0.55, 0.48, 0.36)
		sb.set_border_width_all(2)
		slot.add_theme_stylebox_override("panel", sb)
		slot.position = Vector2(480 + i * 340, 260)
		slot.size = Vector2(280, 420)
		puzzle_root.add_child(slot)
		slots.append(slot)
		var cn := ColorRect.new()                  # 槽位上方的"蜡烛"
		cn.color = Color(0.25, 0.22, 0.18)
		cn.position = Vector2(610 + i * 340, 210)
		cn.size = Vector2(20, 34)
		puzzle_root.add_child(cn)
		candles.append(cn)
	# 三张卡乱序放底部
	var shuffled := correct_order.duplicate()
	shuffled.shuffle()
	if shuffled == correct_order:
		shuffled.reverse()
	for i in range(3):
		var card := TextureRect.new()
		card.texture = load("res://assets/%s.png" % shuffled[i])
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		card.size = Vector2(240, 370)
		card.position = Vector2(520 + i * 330, 690)
		card.set_meta("id", shuffled[i])
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(card))
		puzzle_root.add_child(card)
		cards.append(card)

func _on_card_input(event: InputEvent, card: TextureRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_card = card
			drag_offset = card.get_global_mouse_position() - card.global_position
			card.move_to_front()
		else:
			if drag_card == card:
				_drop_card(card)
			drag_card = null
	elif event is InputEventMouseMotion and drag_card == card:
		card.global_position = card.get_global_mouse_position() - drag_offset

func _drop_card(card: TextureRect) -> void:
	for slot in slots:
		if slot.get_global_rect().has_point(card.get_global_mouse_position()):
			card.global_position = slot.global_position + Vector2(10, 10)
			card.set_meta("slot", slots.find(slot))
			_check_order()
			return
	card.set_meta("slot", -1)

func _check_order() -> void:
	var placed := {}
	for card in cards:
		if card.has_meta("slot") and int(card.get_meta("slot")) >= 0:
			placed[int(card.get_meta("slot"))] = String(card.get_meta("id"))
	if placed.size() < 3:
		return
	var ok := true
	for i in range(3):
		if placed.get(i, "") != correct_order[i]:
			ok = false
	if ok:
		state = "done"
		for cn in candles:                          # 蜡烛点亮
			cn.color = MARIGOLD
		_set_whisper(whisper + 0.25)                # 记忆归位，亡魂靠近
		end_label = Label.new()
		end_label.text = "记忆点亮了。低语更近了。\n—— 垂直切片到此结束 ——"
		end_label.add_theme_color_override("font_color", INK)
		end_label.add_theme_font_size_override("font_size", 44)
		end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		end_label.set_anchors_preset(Control.PRESET_CENTER)
		puzzle_root.add_child(end_label)
	else:
		_set_whisper(whisper + 0.04)                # 摆错也有代价
