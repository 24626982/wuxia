extends Node
## Owns complete story transactions; cancelled encounters restore their entry flags.
const Rules = preload("res://scripts/story_rules.gd")
var world: Node
var logic: Dictionary
var busy := false
var aborted := false
var selection := -1
var entry_seen: Dictionary = {}

func setup(owner_world: Node) -> void:
	world = owner_world
	logic = JSON.parse_string(FileAccess.get_file_as_string("res://data/game_logic.json"))

func eligible(event: Dictionary) -> bool:
	return world.story_stage >= 4 and event.get("map") == world.map_id and Rules.matches(world.story_flags, event.get("requires", {}))

func interact(id: String) -> bool:
	if busy: return true
	for event in logic.events:
		if not eligible(event): continue
		if event.get("npc") == id or event.get("trigger") == id:
			run_event(event)
			return true
	return false

func enter_map() -> void:
	if busy or world.dialogue.active or world.story_stage < 4: return
	if world.map_id == "courtyard" and world.story_flags.get("finale_pending", false):
		run_event({"id": "finale_courtyard", "sequence": ["finale_courtyard", "finale_monologue", "@ending"]})
		return
	for event in logic.events:
		if not eligible(event) or entry_seen.has(event.get("id")): continue
		if event.get("trigger") == "enter" or event.get("id") == "act3_chen_bai_nails":
			if event.id == "finale" and world.story_flags.get("ending_seen", false): continue
			entry_seen[event.id] = true
			run_event(event)
			return
	if world.map_id == "residence" and not entry_seen.has("echo"):
		entry_seen.echo = true
		var echo := echo_lines("residence_enter")
		if not echo.is_empty(): world.dialogue.begin("echo", echo, world.story_flags)

func echo_lines(target: String) -> Array:
	var result: Array = []
	var threshold := -1
	for entry in logic.violence_echo.entries:
		if entry.target == target and entry.has("line") and entry.min_fight_count <= Rules.value(world.story_flags, "fight_count") and entry.min_fight_count > threshold:
			result = [entry.line]
			threshold = entry.min_fight_count
	return result

func play(content) -> bool:
	if aborted: return false
	var lines: Array = world.story.dialogues.get(content, []) if content is String else content
	if lines.is_empty(): return true
	world.dialogue.begin("story_runtime", lines, world.story_flags)
	if not world.dialogue.active: return true
	var result: Array = await world.dialogue.closed
	if not result[0]:
		aborted = true
		return false
	return true

func menu(prompt: Dictionary, options: Array) -> Dictionary:
	var line := prompt.duplicate(true)
	var choices := []
	var available := []
	for option in options:
		if not Rules.matches(world.story_flags, option.get("requires", {})): continue
		if option.has("evidence") and not Rules.matches(world.story_flags, logic.evidence[option.evidence].requires): continue
		var choice := {"label": option.label, "effects": {"_selection": available.size()}}
		choices.append(choice)
		available.append(option)
	line.choices = choices
	selection = -1
	if not await play([line]): return {}
	if selection < 0 or selection >= available.size(): return {}
	return available[selection]

func run_event(event: Dictionary) -> void:
	busy = true
	aborted = false
	var original: Dictionary = world.story_flags.duplicate(true)
	if event.has("node"):
		await run_node(event.node)
	elif event.has("puzzle"):
		await puzzle(event.puzzle)
	elif event.has("dialogue"):
		await play(event.dialogue)
	else:
		for id in event.get("sequence", []):
			if id == "@ending":
				var ending := ending_record()
				if await play(ending.id):
					world.story_flags.ending_seen = true
					world.story_flags.ending_title = ending.title
					world.story_flags.erase("finale_pending")
			else:
				if not await play(id): break
		if event.id == "hall_revisit" and not aborted:
			await play("hall_revisit_bai_zhi")
	if aborted:
		world.story_flags = original
		entry_seen.erase(event.get("id"))
	busy = false
	if not aborted:
		world.ClueJournal.collect(world.story_flags, world.story_stage, world.story.dialogues, event.get("id", ""))
	world.player.movement_enabled = true
	world._update_objective()
	world.refresh_story_spots()
	if not aborted and event.has("then"):
		world.story_flags.finale_pending = true
		WorldState.travel(world, "res://scenes/" + event.then.map + ".tscn", Vector2(480, 430))

func outcome(data: Dictionary) -> void:
	if aborted: return
	if data.has("dialogue") and not await play(data.dialogue): return
	world.story_flags.merge(data.get("effects", {}), true)
	if data.has("if"):
		await outcome(data["then"] if Rules.matches(world.story_flags, data["if"]) else data["else"])

func search_available() -> bool:
	for event in logic.events:
		if event.get("id") == "cliff_search":
			return Rules.matches(world.story_flags, event.get("requires", {}))
	return false

func run_node(id: String) -> void:
	var node: Dictionary = logic.nodes[id]
	# 崖上的對質沒有離開選項，所以還能搜查的竹管必須在這裡問，否則藏處永久錯過。
	if id == "n5" and not world.story_flags.get("hide_spot", false) and search_available():
		var search := await menu(node.search_prompt, node.search_choices)
		if search.is_empty(): return
		if search.id == "search": await puzzle("cliff_search")
	if id == "n5" and world.story_flags.get("hide_spot", false):
		var retrieval := await menu(node.retrieval_prompt, node.retrieval_choices)
		if retrieval.is_empty(): return
		world.story_flags.manual_secured = retrieval.id == "retrieve"
	if not await play(node.intro): return
	if id == "n5":
		var entry := await menu(node.prompt, node.entry_choices)
		if entry.is_empty(): return
		if entry.type == "fight": await fight_node(id, "fight")
		else: await final_talk(node.talk)
		return
	var misses := 0
	var valid := []
	while not aborted:
		var options: Array = node.choices.duplicate(true)
		options.append({"id": "leave", "type": "leave", "label": "先離開，繼續調查。"})
		var choice := await menu(node.prompt, options)
		if choice.is_empty(): return
		match choice.type:
			"leave":
				await leave_node(node)
				return
			"fight":
				await fight_node(id, "fight")
				return
			"correct":
				await outcome(node.on_success)
				return
			_:
				if not await play(choice.get("reply", [])): return
				if choice.type == "valid":
					if not choice.id in valid: valid.append(choice.id)
					var rule: Dictionary = node.success_rule
					rule = rule["then"] if Rules.matches(world.story_flags, rule["if"]) else rule["else"]
					if rule.get("all_of", []).all(func(v): return v in valid) and (not rule.has("any_of") or rule.any_of.any(func(v): return v in valid)):
						await outcome(node.on_success)
						return
				if choice.type == "wrong": misses += 1
		if misses > logic.node_rules.miss_limit:
			var decision := await menu({"speaker": "旁白", "text": logic.node_rules.on_third_miss.line}, logic.node_rules.on_third_miss.options)
			if decision.is_empty(): return
			if decision.action == "start_battle": await fight_node(id, decision.result)
			else: await leave_node(node)
			return

func leave_node(node: Dictionary) -> void:
	var hint: String = node.leave_hint
	if node.has("leave_hint_when_impossible") and Rules.matches(world.story_flags, node.leave_hint_when_impossible.when):
		hint = node.leave_hint_when_impossible.text
	await play([{"speaker": "旁白", "text": hint}])

func fight_node(id: String, result: String) -> void:
	var node: Dictionary = logic.nodes[id]
	world.story_flags[id + "_result"] = result
	await battle(node.battle)
	await outcome(node.after_battle)

func battle(id: String) -> void:
	var data: Dictionary = logic.battles[id]
	if not await play(data.get("intro_dialogue", data.get("intro", []))): return
	var hp := {}
	for enemy in data.enemies: hp[enemy.id] = 1.0
	var fired := []
	var turn := 1
	while hp.values().any(func(v): return v > 0.0) and not aborted:
		await battle_lines(data, hp, fired, turn)
		var options := []
		for enemy in data.enemies:
			if hp[enemy.id] > 0:
				options.append({"id": enemy.id, "label": "出劍 · %s（體力 %d%%）" % [enemy.name, roundi(hp[enemy.id] * 100)]})
		var attack := await menu({"speaker": "交鋒 · 第 %d 回合" % turn, "text": "選擇出手的對象。"}, options)
		if attack.is_empty(): return
		var damage := 1.0 if id == "battle_n2" else 0.4
		hp[attack.id] = maxf(0.0, hp[attack.id] - damage)
		await battle_lines(data, hp, fired, turn)
		turn += 1
	if not aborted and not world.story_flags.has(data.result_key): world.story_flags[data.result_key] = "fight"

func battle_lines(data: Dictionary, hp: Dictionary, fired: Array, turn: int) -> void:
	for i in range(data.get("turn_lines", []).size()):
		if i in fired: continue
		var entry: Dictionary = data.turn_lines[i]
		var trigger: Dictionary = entry.trigger
		var ready: bool = trigger.get("turn", -1) == turn
		if trigger.has("hp_below"): ready = hp.get(trigger.enemy, 1.0) < trigger.hp_below
		if trigger.has("on_defeat"): ready = hp.get(trigger.on_defeat, 1.0) <= 0
		if ready:
			fired.append(i)
			if not await play([entry.line]): return

func puzzle(id: String) -> void:
	var data: Dictionary = logic.puzzles[id]
	if not await play(data.intro): return
	while not aborted:
		var options: Array = data.options.duplicate(true)
		options.append({"label": "先離開", "id": "leave"})
		var choice := await menu({"speaker": "少俠", "text": "要查看哪一根竹管？"}, options)
		if choice.is_empty() or choice.id == "leave": return
		if choice.correct:
			await play(data.right)
			return
		if not await play(data.wrong): return

func final_talk(data: Dictionary) -> void:
	var patience: int = data.patience
	for question in data.reason_stage:
		while patience > 0 and not aborted:
			var evidence := []
			for id in data.reason_evidence_menu:
				var item: Dictionary = logic.evidence[id]
				evidence.append({"id": id, "label": item.label, "requires": item.requires})
			var prompt: Dictionary = question.line.duplicate(true)
			prompt.text += "\n（耐心：%d）" % patience
			var choice := await menu(prompt, evidence)
			if choice.is_empty(): return
			if choice.id == question.correct_evidence:
				if not await play(question.correct_reply): return
				if question.has("after_correct") and not await play(question.after_correct): return
				break
			patience -= 1
			if not await play(data.wrong_evidence_reply): return
		if patience == 0:
			await talk_failed(data.on_fail)
			return
	if not await play(data.heart_intro): return
	while patience > 0 and not aborted:
		var choice := await menu({"speaker": "少俠", "text": "（要怎麼回應？耐心：%d）" % patience}, data.heart_stage.choices)
		if choice.is_empty(): return
		if choice.type == "correct":
			await outcome(data.on_success)
			return
		patience -= 1
		if not await play(choice.get("reply_dialogue", choice.get("reply", []))): return
	await talk_failed(data.on_fail)

func talk_failed(data: Dictionary) -> void:
	if not await play(data.dialogue): return
	if not Rules.matches(world.story_flags, data["if"]):
		await outcome(data["else"])
		return
	var choice := await menu({"speaker": "少俠", "text": "（要攔下他嗎？）"}, data["then"].choices)
	if choice.is_empty(): return
	world.story_flags.merge(choice.get("effects", {}), true)
	if choice.get("action") == "start_battle":
		await battle(choice.battle)
		await play(choice.after_battle_dialogue)
	else: await outcome(choice)

func ending_record() -> Dictionary:
	var route = Rules.value(world.story_flags, "route")
	var manual: bool = world.story_flags.get("got_manual", false)
	for ending in logic.endings.table:
		if ending.route == route and ending.got_manual == manual: return ending
	# 結局表有缺口時寧可播同路線的結局，也不要讓玩家卡在最後一幕。
	push_error("No ending for route=%s got_manual=%s" % [str(route), str(manual)])
	for ending in logic.endings.table:
		if ending.route == route: return ending
	return logic.endings.table[0]
