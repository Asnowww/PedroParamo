extends Node
## 全局状态（autoload GameState）：低语值、进度、卡牌、生死笔记、存档

const SAVE_PATH := "user://save.json"

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

func save() -> void:
	var data := {
		"whisper": whisper,
		"current_fragment": current_fragment,
		"unlocked_cards": unlocked_cards,
		"notebook": notebook,
		"seen_fragments": seen_fragments,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_save() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
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
