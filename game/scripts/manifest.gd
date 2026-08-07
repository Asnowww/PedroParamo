extends Node
## 碎片清单（autoload Manifest）：解析 data/manifest.csv——引擎侧唯一数据源

var fragments := {}   # "F01" -> {lines, chapter, cluster, main_card, extra_cards[], assets[]}

func _ready() -> void:
	var f := FileAccess.open("res://data/manifest.csv", FileAccess.READ)
	if f == null:
		push_error("manifest.csv 缺失")
		return
	f.get_csv_line()  # 表头
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 7 or row[0] == "":
			continue
		fragments[row[0]] = {
			"lines": row[1],
			"chapter": row[2],
			"cluster": row[3],
			"main_card": row[4],
			"extra_cards": Array(row[5].split(";", false)),
			"assets": Array(row[6].split(";", false)),
		}

func get_fragment(id: String) -> Dictionary:
	return fragments.get(id, {})
