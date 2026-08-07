extends Node
## 资产加载器（autoload Art）：优先 res://assets/，缺失时回落到仓库 art/final/
## 这样 500MB 的成品图不必复制进 game/，git 也只存一份原图。

var _cache := {}

func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var tex: Texture2D = null
	var res_path := "res://assets/%s.png" % name
	if ResourceLoader.exists(res_path):
		tex = load(res_path)
	else:
		var ext := ProjectSettings.globalize_path("res://").path_join("../art/final/%s.png" % name)
		if FileAccess.file_exists(ext):
			var img := Image.load_from_file(ext)
			if img != null:
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		push_warning("找不到资产: " + name)
	_cache[name] = tex
	return tex
