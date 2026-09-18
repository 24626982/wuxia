extends RefCounted
## Chapter rules are separate from map movement and native UI nodes.
const WITNESSES := ["shen_he", "bai_zhi", "gu_heng", "uncle_zhou"]
const TESTIMONY_IDS := ["shen_he", "bai_zhi", "gu_heng"]

static func testimony_count(flags: Dictionary) -> int:
	var count := 0
	for id in TESTIMONY_IDS:
		if flags.get("residence_seen_" + id, false):
			count += 1
	return count

static func dialogue_for(id: StringName, flags: Dictionary) -> StringName:
	if not String(id) in WITNESSES:
		return &""
	if id == &"uncle_zhou":
		if flags.get("residence_resolved", false):
			return &"residence_uncle_zhou_repeat"
		if testimony_count(flags) == TESTIMONY_IDS.size():
			return &"residence_uncle_zhou_resolution"
	elif flags.get("residence_seen_" + String(id), false):
		return StringName("residence_" + String(id) + "_repeat")
	return StringName("residence_" + String(id))

static func commit(id: StringName, effects: Dictionary, flags: Dictionary) -> void:
	flags.merge(effects, true)
	for witness in TESTIMONY_IDS:
		if id == StringName("residence_" + witness):
			flags["residence_seen_" + witness] = true
