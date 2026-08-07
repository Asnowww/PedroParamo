extends Node
## 卡牌图鉴数据（autoload CardDb）：data/cards.json —— 全部记忆卡的标题与剧情文案

var cards := {}

func _ready() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	if raw is Dictionary:
		cards = raw

func title_of(id: String) -> String:
	return cards.get(id, {}).get("title", id)

func lore_of(id: String) -> String:
	return cards.get(id, {}).get("lore", "")
