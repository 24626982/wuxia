extends RefCounted
## Player-facing objectives describe actions and places, never hidden scoring.
const Residence = preload("res://scripts/residence_story.gd")
const MAP_NAMES := {"courtyard": "庭院", "residence": "西院", "hall": "議事廳", "dormitory": "弟子宿舍", "town": "山腳城鎮", "bamboo_station": "東竹亭", "wind_cliff": "聽風崖"}
const ROADS := {
	"courtyard": {"residence": "左側石橋", "hall": "掌門後方的北門", "town": "南方山門石階"},
	"residence": {"courtyard": "右側石橋", "dormitory": "周伯後方的屋門"},
	"dormitory": {"residence": "下方屋門"},
	"hall": {"courtyard": "下方大門"},
	"town": {"courtyard": "上方山路", "bamboo_station": "右下方東路"},
	"bamboo_station": {"town": "下方石路", "wind_cliff": "上方竹林小徑"},
	"wind_cliff": {"bamboo_station": "下方山徑"}
}

static func step(map: String, target: String, title: String, detail: String) -> Dictionary:
	return {"map": map, "target": target, "title": title, "detail": detail}

static func next(stage: int, flags: Dictionary) -> Dictionary:
	if flags.get("ending_seen", false): return step("", "", str(flags.get("ending_title", "故事完結")), "故事已結束，仍可自由走訪各地。")
	if stage < 3:
		return [step("courtyard", "master", "先向柳青霄掌門請示", "走近北側掌門，按 E 聽取劍譜失竊的消息。"), step("courtyard", "disciple", "詢問阿棠看見了什麼", "庭院東側，找阿棠了解受傷信使的線索。"), step("courtyard", "guard", "向秦川核對昨夜動靜", "庭院南側山門前，與秦川交談。")][stage]
	if stage == 3: return step("courtyard", "departure", "走到南方山門，整理線索", "沿中央石路向下走到門外石階，會自動接續劇情。")
	if not flags.get("residence_resolved", false):
		var names := {"shen_he": "沈禾", "bai_zhi": "白芷", "gu_heng": "顧衡"}
		var places := {"shen_he": "左側小橋旁", "bai_zhi": "右上方藥房前", "gu_heng": "中央石路旁"}
		var pending := []
		for id in Residence.TESTIMONY_IDS:
			if not flags.get("residence_seen_" + id, false): pending.append(id)
		if not pending.is_empty():
			var people := PackedStringArray()
			for id in pending: people.append(names[id])
			return step("residence", pending[0], "前往西院，詢問" + names[pending[0]], places[pending[0]] + "，走近按 E。尚待詢問：" + "、".join(people) + "；問清後再找周伯核對。")
		return step("residence", "uncle_zhou", "回找周伯，核對收訖單", "沈禾、白芷、顧衡的話已問清。到北側屋門前找周伯。")
	if not flags.has("n1_result"):
		if not flags.get("met_chen_bai", false): return step("dormitory", "chen_bai", "先探望受傷的陳白", "宿舍左側床邊，走近陳白按 E；再詢問守著小滿床位的石安。")
		return step("dormitory", "shi_an", "請石安讓你查看小滿的床", "宿舍右側床邊找石安交談。床鋪與藥袋需獲准後才能調查。")
	if not flags.has("n2_result"):
		if not flags.has("explore_dormitory_bed"): return step("dormitory", "explore_dormitory_bed", "調查小滿留下的空床", "靠近有放大鏡標記的左側床位，按 E 查看。")
		if not flags.has("explore_town_notice"): return step("town", "explore_town_notice", "查看城鎮的尋人告示", "告示板在城鎮左側。查完後，找附近的小滿哥哥交談。")
		return step("town", "brother", "告訴小滿哥哥你知道的事", "到城鎮告示板旁，與小滿的哥哥交談。")
	if not flags.has("n3_result"): return step("bamboo_station", "third_lamp_at_night", "在第三盞燈旁等候入夜", "沿東竹亭右側廊前走到第三盞燈，按 E 等候，與石安會面。")
	if not flags.has("chen_bai_nails"): return step("dormitory", "chen_bai", "回宿舍探望陳白", "陳白想起了新的細節；回到宿舍後會接續對話。")
	if not flags.has("n4_result"):
		if not flags.has("explore_wind_cliff_record"): return step("wind_cliff", "explore_wind_cliff_record", "查看崖邊竹管的傳聲痕跡", "先調查左側竹管，再去練劍空地等候入夜。")
		return step("wind_cliff", "enter_at_night", "到練劍空地等候入夜", "靠近空地的月亮標記按 E，聽聽沈禾怎麼說。")
	if not flags.has("revealed"): return step("hall", "", "回議事廳核對名簿與燈座", "進入議事廳後展開調查；離崖前也可以搜查竹管。")
	if not flags.has("n5_result"): return step("wind_cliff", "yan_cheng", "前往聽風崖，與嚴承對質", "證據已齊。若知道藏處，對質前可選擇是否先取回劍譜；之後可出示證據或動手。")
	return step("hall", "", "回議事廳，向掌門覆命", "走進議事廳，說明調查結果；終幕會接續回到庭院。")

static func next_map(from: String, destination: String) -> String:
	if from == destination or destination.is_empty(): return ""
	var queue := [[from]]
	var visited := [from]
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		for neighbor in ROADS.get(path.back(), {}):
			if neighbor in visited: continue
			var route := path + [neighbor]
			if neighbor == destination: return route[1]
			visited.append(neighbor)
			queue.append(route)
	return ""

static func instructions(current: String, task: Dictionary) -> String:
	var neighbor := next_map(current, task.map)
	if neighbor.is_empty(): return task.detail
	return "先走" + ROADS[current][neighbor] + " → " + MAP_NAMES[neighbor] + "。\n目的地：" + MAP_NAMES[task.map] + "。" + task.detail
