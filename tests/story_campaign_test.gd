extends SceneTree
const Rules = preload("res://scripts/story_rules.gd")
var failures := 0
var world: Node
var policy := "talk"
var used_receipt := false
var skip_search := false

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func drain() -> void:
	for step in range(2500):
		var dialogue = world.dialogue
		if not dialogue.active:
			check(not world.director.busy, "Encounter must finish without deadlocking")
			return
		if not dialogue.waiting_for_choice:
			dialogue.advance()
			continue
		var index := 0
		var text: String = dialogue.body.text
		for i in range(dialogue.current_choices.size()):
			var label: String = dialogue.current_choices[i].label
			if label == "直接上前。": index = i
			if policy == "fight":
				if label == "動手。": index = i
				if label.begins_with("你們半夜在這裡"): index = i
				if label.begins_with("最北邊"): index = i
				continue
			if label.begins_with("他的包袱") or label.begins_with("你弟弟是") or label.begins_with("竹管是傳聲") or label == "跟他談。": index = i
			if label == "出示：兩半收訖單" and not used_receipt: index = i
			if label.begins_with("我不是來抓") and used_receipt: index = i
			if label.begins_with("最北邊"): index = i
			if "披蓑衣的是" in text and label == "釘底靴與真劍": index = i
			if "名簿少一頁" in text and label == "燈座裡的紙灰": index = i
			if "床上不是擺著" in text and label == "周伯收走的書套": index = i
			if "要怎麼回應" in text and label.begins_with("他的床靠窗"): index = i
			if policy == "fail" and "耐心：" in text and label.begins_with("沾血的"): index = i
			if policy == "treasure" and (label.begins_with("（放著") or label == "你拿著。你自己交。"): index = i
			if label == "讓他走": index = i
			if label == "結束調查": index = i
		if policy != "fight":
			var found_tier := false
			for prefix in ["這些竹管是", "橋下那兩聲", "鞋底有釘子"]:
				for i in range(dialogue.current_choices.size()):
					if String(dialogue.current_choices[i].label).begins_with(prefix):
						index = i
						found_tier = true
						break
				if found_tier: break
			if not found_tier:
				for i in range(dialogue.current_choices.size()):
					if dialogue.current_choices[i].label == "先到這裡。": index = i
		if dialogue.current_choices[index].label == "出示：兩半收訖單": used_receipt = true
		dialogue.choose(index)
	check(false, "Story exceeded step limit")
	world.dialogue.cancel()

func event(id: String) -> void:
	for entry in world.director.logic.events:
		if entry.get("id") == id:
			world.map_id = entry.map
			check(world.director.eligible(entry), "Event prerequisites satisfied: " + id)
			if not world.director.eligible(entry): return
			if entry.get("trigger") == "enter" or id == "act3_chen_bai_nails":
				world.director.enter_map()
			else:
				check(world.director.interact(entry.get("npc", entry.get("trigger", ""))), "Player interaction starts " + id)
			drain()
			return
	check(false, "Missing event " + id)

func run() -> void:
	check(Rules.matches({}, {"x": {"$exists": false, "$nin": ["fight"]}}), "Missing keys and $nin")
	check(not Rules.matches({"x": 2}, {"x": {"$gt": 2}}), "Numeric strict comparison")
	check(Rules.matches({"x": 2}, {"x": {"$gte": 2, "$lte": 2}}), "Numeric inclusive comparison")
	check(Rules.value({"heart_shi_an": true, "heart_xiaoman": true}, "heart_count") == 2, "Heart count is derived")
	for scenario in ["talk", "treasure", "fight", "mixed", "fail", "fight_lost", "mixed_lost"]:
		for branch in range(4 if scenario == "talk" else 1):
			world = load("res://scenes/courtyard.tscn").instantiate()
			root.add_child(world)
			await process_frame
			used_receipt = false
			skip_search = scenario in ["fight_lost", "mixed_lost"]
			policy = "talk"
			for id in ["master_start", "disciple_clue", "guard_route", "residence_shen_he", "residence_bai_zhi", "residence_gu_heng", "residence_uncle_zhou", "residence_uncle_zhou_resolution"]:
				world._open_dialogue(id)
				drain()
			world.story_flags.approach = "compassion" if branch < 2 else "justice"
			world.story_flags.residence_next_lead = "seal" if branch % 2 == 0 else "safety"
			event("dorm_chen_bai_first")
			check(world.story_flags.get("met_chen_bai", false), "Line actions commit")
			policy = "fight" if scenario.begins_with("fight") else "talk"
			event("n1")
			check(world.story_flags.has("n1_result"), "N1 complete")
			for id in ["explore_dormitory_bed", "explore_dormitory_pouch", "explore_town_notice"]:
				world._open_dialogue(id)
				drain()
			event("n2")
			if scenario == "mixed_lost": policy = "fight"
			event("n3")
			check(world.story_flags.has("n3_result"), "N3 complete")
			event("act3_chen_bai_nails")
			world._open_dialogue("explore_wind_cliff_record")
			drain()
			if scenario.begins_with("mixed"): policy = "fight"
			event("n4")
			if scenario in ["fight", "mixed"] and not world.story_flags.get("hide_spot", false): event("cliff_search")
			event("hall_revisit")
			for key in ["e1_boots", "e2_ash", "e3_sheath", "revealed", "suspect_known", "monologue"]:
				check(world.story_flags.has(key), "Hall grants " + key)
			if scenario in ["fail", "treasure"]: policy = scenario
			event("n5")
			var expected: String = {"talk": "ending_junzi", "treasure": "ending_treasure", "fight": "ending_tyrant", "mixed": "ending_ordinary_master", "fail": "ending_junzi", "fight_lost": "ending_exiled", "mixed_lost": "ending_own_world"}[scenario]
			check(world.director.ending_record().get("id") == expected, scenario + " ending: " + str(world.story_flags))
			if scenario == "treasure":
				check(world.story_flags.get("handed_back") == "yan_cheng" and world.story_flags.get("yan_cheng_yielded", false), "Treasure ending comes from Yan returning the manual")
				check(world.director.report_dialogue() == "finale_report_handed_back", "Treasure ending uses Yan's report scene")
			world.director.run_event({"id": "test_finale", "sequence": ["@report", "finale_courtyard", "@rollcall", "finale_monologue", "@ending"]})
			drain()
			check(world.story_flags.get("ending_seen", false), "Finale completes")
			world.queue_free()
			await process_frame
	print("STORY_CAMPAIGN_TEST: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
