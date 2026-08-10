extends Node
## 全局状态（autoload GameState）：低语值、进度、卡牌、生死笔记、存档

## 存档位：0 = 自动存档（系统写），1–3 = 手动存档（玩家写）
const SLOT_AUTO := 0
const SLOT_COUNT := 4
const CHAPTER_OF := {
	"F01": "序章 · 下山", "F04": "第一章 · 空村投宿", "F14": "第二章 · 回声",
	"F28": "第三章 · 塌了一半的屋顶", "F33": "第四章 · 坟中", "F18": "第五章 · 半月庄",
	"F36": "第六章 · 苏萨娜", "F55": "第七章 · 钟声", "F58": "第八章 · 崩塌",
}
const CHAPTER_ORDER := ["F01", "F04", "F14", "F28", "F33", "F18", "F36", "F55", "F58"]

static func slot_path(slot: int) -> String:
	return "user://save_%d.json" % slot

var whisper := 0.0                    # 0..1，只升不降
var current_fragment := "F01"
var unlocked_cards: Array = []        # 已获得的记忆卡 id
var notebook := {}                    # 人名 -> 0未知 1活人 2死人
var seen_fragments: Array = []

func raise_whisper(v: float) -> void:
	whisper = clampf(maxf(whisper, whisper + v), 0.0, 1.0)

func unlock_card(id: String) -> void:
	if id != "" and not unlocked_cards.has(id):
		unlocked_cards.append(id)

func meet(person: String) -> void:
	if person != "" and not notebook.has(person):
		notebook[person] = 0

func cycle_mark(person: String) -> void:
	notebook[person] = (int(notebook.get(person, 0)) + 1) % 3

func _chapter_name() -> String:
	## 当前碎片属于哪一章：沿章节起点表回溯，取最近一个已到达的章首
	var best := "序章 · 下山"
	for fid in CHAPTER_ORDER:
		if seen_fragments.has(fid):
			best = CHAPTER_OF[fid]
	if CHAPTER_OF.has(current_fragment):
		best = CHAPTER_OF[current_fragment]
	return best

func save(slot: int = SLOT_AUTO) -> void:
	var t := Time.get_datetime_dict_from_system()
	var data := {
		"whisper": whisper,
		"current_fragment": current_fragment,
		"unlocked_cards": unlocked_cards,
		"notebook": notebook,
		"seen_fragments": seen_fragments,
		"chapter": _chapter_name(),
		"cards_count": unlocked_cards.size(),
		"stamp": "%04d-%02d-%02d %02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute],
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))

func has_save(slot: int = SLOT_AUTO) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func any_save() -> bool:
	for i in range(SLOT_COUNT):
		if has_save(i):
			return true
	return false

func slot_info(slot: int) -> Dictionary:
	## 给存档界面用：没有存档返回空字典
	if not has_save(slot):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if data == null:
		return {}
	return {
		"chapter": String(data.get("chapter", "？")),
		"fragment": String(data.get("current_fragment", "F01")),
		"cards": int(data.get("cards_count", (data.get("unlocked_cards", []) as Array).size())),
		"stamp": String(data.get("stamp", "")),
	}

func load_save(slot: int = SLOT_AUTO) -> bool:
	if not has_save(slot):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	if data == null:
		return false
	whisper = float(data.get("whisper", 0.0))
	current_fragment = String(data.get("current_fragment", "F01"))
	unlocked_cards = data.get("unlocked_cards", [])
	notebook = data.get("notebook", {})
	seen_fragments = data.get("seen_fragments", [])
	return true

## 章节跳转：从 F01 沿碎片链走到目标碎片，把沿途该拿的卡与该遇见的人补齐，
## 这样中途开局的拼图板、卡册、笔记与结局分层都不会缺料。
func fast_forward_to(target: String) -> void:
	reset()
	var cur := "F01"
	var guard := 0
	while cur != target and cur != "end" and guard < 200:
		guard += 1
		var path := "res://data/fragments/%s.json" % cur
		if not FileAccess.file_exists(path):
			break
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		var nxt := ""
		for op in data.get("ops", []):
			if op.has("card"):
				unlock_card(op["card"])
			elif op.has("meet"):
				meet(op["meet"])
			elif op.has("whisper"):
				whisper = clampf(whisper + float(op["whisper"]), 0.0, 1.0)
			elif op.has("listen"):
				for s in op["listen"].get("sources", []):
					if s.has("card"):
						unlock_card(s["card"])
			elif op.has("next"):
				nxt = op["next"]
		if not seen_fragments.has(cur):
			seen_fragments.append(cur)
		if nxt == "":
			break
		cur = nxt
	current_fragment = target
	save()

func reset() -> void:
	whisper = 0.0
	current_fragment = "F01"
	unlocked_cards = []
	notebook = {}
	seen_fragments = []
