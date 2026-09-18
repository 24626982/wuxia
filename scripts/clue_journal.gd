extends RefCounted
## Record only committed discoveries; provenance stays fixed after acquisition.
const Rules = preload("res://scripts/story_rules.gd")
const ITEMS := [
	["ev_seal_sketch", "阿棠畫的竹印", "三片竹葉，下方缺一角，屬於東竹亭舊驛站。", "庭院・阿棠憑記憶畫下，交談取得"],
	["residence_resolved", "兩半收訖單", "西院查訪所得的兩半單據，可帶往東竹亭核對。", "西院・查訪沈禾、白芷、顧衡後，與周伯核對取得"],
	["bai_method", "白芷窗下的藥包", "白芷提供了藥包的情況，可與宿舍及城鎮的包裹比對。", "西院・詢問白芷取得"],
	["met_chen_bai", "陳白未看清襲擊者", "陳白表示天太黑，沒有看清打傷他的人。", "宿舍・探望陳白，聽取本人說法"],
	["heart_shi_an", "不是小滿疊的被子", "石安說小滿不會把被子疊得這麼整齊；他離開時說很快回來。", "宿舍・說服石安後，由他主動告知"],
	["heart_brother", "失約與寄藥", "小滿約好第二遍更鼓後下山，哥哥等到天亮也沒見到他；小滿原想寄藥給母親。", "城鎮・安撫小滿的哥哥，交談取得"],
	["xiaoman_safe", "找到小滿", "已在東竹亭找到小滿，確認他平安。", "東竹亭・與小滿會面"],
	["chen_bai_nails", "襲擊者的釘底靴", "陳白想起打傷他的人鞋底有釘子。", "宿舍・小滿平安後再訪陳白，聽取補充證詞"],
	["heart_shen_he", "三聲短笛的意思", "沈禾說：兩短是招呼同伴，三短且最後一聲急，表示有人受傷。", "聽風崖・說服沈禾，交談取得"],
	["hide_spot", "北邊竹管的藏處", "劍譜藏處指向聽風崖最北邊的竹管。", "聽風崖・調查竹管"],
	["e1_boots", "釘底靴與真劍", "配給帳記載嫡系入門即領釘底靴與真劍，與陳白的證詞相互印證。", "議事廳・翻查配給帳，與陳白證詞比對"],
	["e2_ash", "燈座裡的紙灰", "燈座縫隙的紙灰還能辨認出「滿」、「勝」兩字。", "議事廳・獲准開封卷宗後，親自檢查燈座"],
	["e3_sheath", "周伯收走的書套", "周伯說他在小滿床上發現裝劍譜的長布套，並私下收走。", "議事廳・周伯親口告知，交談取得"],
	["revealed", "配給帳上的差別", "兵器、藥物、夜間出入與劍譜閱覽，對嫡系及中途入門弟子有不同規定。", "議事廳・獲准查閱配給帳"],
	["suspect_known", "顧衡指向嚴承的證詞", "小滿常往外跑的傳言出自嚴承；顧衡所知，當晚未排巡夜又不在房中的只有他。", "議事廳・顧衡補充證詞；仍須向本人求證"]
]

static func collect(flags: Dictionary, stage: int, library: Dictionary, event_id: String = "") -> void:
	var records: Dictionary = flags.get("_clue_journal", {}).duplicate(true)
	if stage >= 2:
		add(records, "pass", "沾血的半張路引", "阿棠說陳白手中抓著沾血的半張路引，袖口繡著墨竹。", "庭院・阿棠目擊後轉述，尚非本人查驗原物")
		add(records, "whistle", "天亮前的三聲短笛", "阿棠聽見聽風崖方向傳來三聲短笛，最後一聲特別急。", "庭院・聽取阿棠的目擊經過")
	for item in ITEMS:
		if not flags.get(item[0], false): continue
		var source: String = item[3]
		if item[0] == "hide_spot":
			if "search" in event_id: source = "聽風崖・依鞋印與新擦痕親自搜查竹管"
			elif flags.get("n3_result") == "talk": source = "東竹亭・說服小滿，交談取得藏處消息"
			elif flags.get("n4_result") == "talk": source = "聽風崖・說服沈禾，再比對竹管痕跡"
		if item[0] == "xiaoman_safe": source += "・" + method(flags.get("n3_result", "talk"))
		add(records, item[0], item[1], item[2], source)
	# Read actual selected investigation text instead of inventing clues from an object name.
	for id in library:
		if not id.begins_with("explore_") or not flags.has(id): continue
		var lines: Array = library[id]
		var body := ""
		var choice_label := "現場查看"
		for line in lines:
			if line.has("choices"):
				for choice in line.choices:
					if choice.get("effects", {}).get(id) != flags[id]: continue
					choice_label = choice.label
					for reply in choice.get("reply", []): body += resolved_text(reply, flags) + "\n"
			else: body += resolved_text(line, flags) + "\n"
		var source := "現場調查・" + choice_label
		if id.begins_with("explore_dormitory_"):
			source = "宿舍・" + method(flags.get("n1_result", "talk")) + "後調查；" + choice_label
		var names := {"explore_hall_record":"名簿封繩", "explore_hall_lamp":"議事廳的燈油", "explore_hall_ledger":"劍譜借閱簿", "explore_town_notice":"尋人告示", "explore_town_parcel":"寄放的包裹", "explore_dormitory_bed":"小滿的空床", "explore_dormitory_pouch":"床邊藥袋", "explore_bamboo_station_record":"驛站舊印模", "explore_bamboo_station_signal":"第三盞燈的繩結", "explore_wind_cliff_record":"竹管上的擦痕", "explore_wind_cliff_signal":"崖邊鞋印", "explore_station_backdoor":"驛站後門", "explore_cliff_rock":"崖邊大石"}
		add(records, id + "_" + str(flags[id]), names.get(id, "調查紀錄"), body.strip_edges(), source)
	if not records.is_empty(): flags._clue_journal = records

static func remember_dialogue(flags: Dictionary, id: String, lines: Array) -> void:
	if not (id.begins_with("npc_") or id in ["residence_shen_he", "residence_bai_zhi", "residence_gu_heng", "guard_route"]): return
	var body := ""
	var speaker := "查訪"
	for line in lines:
		var value := resolved_text(line, flags)
		if value.is_empty(): continue
		if speaker == "查訪" and line.get("speaker", "") not in ["少俠", "旁白", ""]: speaker = line.speaker
		body += value + "\n"
	if body.is_empty(): return
	var records: Dictionary = flags.get("_clue_journal", {}).duplicate(true)
	add(records, id, speaker + "的說法", body.strip_edges(), "當面交談・記錄對方說法，尚待查證")
	flags._clue_journal = records

static func resolved_text(line: Dictionary, flags: Dictionary) -> String:
	if not Rules.matches(flags, line.get("when", {})): return ""
	for variant in line.get("variants", []):
		if Rules.matches(flags, variant.get("when", {})): return variant.get("text", "")
	return line.get("text", "")

static func method(result) -> String:
	if result == "fight": return "武力取得"
	if result == "tried_then_fight": return "交涉未果後動武取得"
	return "說服對方取得"

static func add(records: Dictionary, id: String, title: String, body: String, source: String) -> void:
	if not records.has(id): records[id] = {"title": title, "body": body, "source": source}
