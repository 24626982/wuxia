extends RefCounted
## Atlas regions are native textures; generated alpha is preserved unchanged.
const EXISTING := {"master": "master-directions", "disciple": "disciple-directions", "guard": "guard-directions", "shen_he": "shen_he-directions", "bai_zhi": "bai_zhi-directions", "gu_heng": "gu_heng-directions", "uncle_zhou": "uncle_zhou-directions", "hero": "swordsman"}
const MAIN := ["chen_bai", "shi_an", "xiaoman", "brother", "yan_cheng", "npc_elder_yan"]
const SUPPORT := ["npc_town_vendor", "npc_town_tea", "npc_station_keeper", "npc_herb_elder", "npc_town_tea_b", "practice_disciple"]
const SPEAKERS := {"少俠": "hero", "柳青霄": "master", "阿棠": "disciple", "秦川": "guard", "沈禾": "shen_he", "白芷": "bai_zhi", "顧衡": "gu_heng", "周伯": "uncle_zhou", "陳白": "chen_bai", "石安": "shi_an", "小滿": "xiaoman", "小滿的哥哥": "brother", "嚴承": "yan_cheng", "嚴長老": "npc_elder_yan", "攤販": "npc_town_vendor", "貨主": "npc_town_vendor", "茶客": "npc_town_tea", "驛站掌櫃": "npc_station_keeper", "掌櫃": "npc_station_keeper", "採藥老人": "npc_herb_elder", "西院弟子": "practice_disciple", "西院弟子甲": "shi_an", "西院弟子乙": "practice_disciple"}
static var cache: Dictionary = {}
static var frame_cache: Dictionary = {}
static var standing_cache: Dictionary = {}

static func standing_portrait(gender: String) -> Texture2D:
	if standing_cache.has(gender): return standing_cache[gender]
	var source: Texture2D = load("res://assets/characters/hero-female-portrait.png") if gender == "female" else texture("hero")
	var image := source.get_image()
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	# Measure visible pixels only; faint alpha fringe must not change preview scale.
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a >= 0.5:
				minimum.x = mini(minimum.x, x)
				minimum.y = mini(minimum.y, y)
				maximum.x = maxi(maximum.x, x + 1)
				maximum.y = maxi(maximum.y, y + 1)
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = Rect2(Vector2(minimum), Vector2(maximum - minimum))
	standing_cache[gender] = result
	return result
const DIRECTION_FILES := {"chen_bai": "chen_bai", "shi_an": "shi_an", "xiaoman": "xiaoman", "brother": "brother", "yan_cheng": "yan_cheng", "npc_elder_yan": "elder_yan", "npc_town_vendor": "town_vendor", "npc_town_tea": "tea_a", "npc_station_keeper": "station_keeper", "npc_herb_elder": "herb_elder", "npc_town_tea_b": "tea_b", "practice_disciple": "practice_disciple"}

static func directions(id: String) -> Array[Texture2D]:
	if id == "npc_station_keeper_closed": id = "npc_station_keeper"
	if frame_cache.has(id): return frame_cache[id]
	var result: Array[Texture2D] = []
	var basename: String = DIRECTION_FILES.get(id, "")
	if basename.is_empty(): return result
	var path := "res://assets/characters/" + basename + "-directions.png"
	if not ResourceLoader.exists(path): return result
	var source: Texture2D = load(path)
	var size := source.get_size() / 2.0
	var source_image := source.get_image()
	for index in range(4):
		var region := Rect2(Vector2(index % 2, index / 2) * size, size)
		var bounds := source_image.get_region(Rect2i(region)).get_used_rect()
		var frame := AtlasTexture.new()
		frame.atlas = source
		frame.region = Rect2(region.position + Vector2(bounds.position), Vector2(bounds.size))
		result.append(frame)
	frame_cache[id] = result
	return result

static func portrait(speaker: String) -> Texture2D:
	var name := speaker.replace(" · ", "・").split("・")[0].strip_edges()
	var aliases := {"貨攤老闆娘": "npc_town_vendor", "茶客甲": "npc_town_tea", "茶客乙": "npc_town_tea_b", "老夥計": "npc_station_keeper"}
	if aliases.has(name): return texture(aliases[name])
	return texture(SPEAKERS.get(name, ""))

static func texture(id: String) -> Texture2D:
	if id == "npc_station_keeper_closed": id = "npc_station_keeper"
	if cache.has(id): return cache[id]
	var path := ""
	var region := Rect2()
	if id in MAIN or id in SUPPORT:
		var main: bool = id in MAIN
		var index: int = (MAIN if main else SUPPORT).find(id)
		path = "res://assets/characters/cast_main.png" if main else "res://assets/characters/cast_support.png"
		var rows: Array = [0, 528, 1004, 1536] if main else [0, 548, 1026, 1536]
		var row: int = index / 2
		region = Rect2((index % 2) * 512, rows[row], 512, rows[row + 1] - rows[row])
	elif EXISTING.has(id):
		path = "res://assets/characters/" + EXISTING[id] + ".png"
	else: return null
	var source: Texture2D = load(path)
	if not region.has_area(): region = Rect2(Vector2.ZERO, source.get_size() / 2.0)
	var bounds := source.get_image().get_region(Rect2i(region)).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(region.position + Vector2(bounds.position), Vector2(bounds.size))
	cache[id] = atlas
	return atlas
