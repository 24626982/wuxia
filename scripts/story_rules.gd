extends RefCounted
## Shared condition semantics for dialogue, evidence and map events.
static func value(flags: Dictionary, key: String):
	if key == "fight_count":
		var count := 0
		for i in range(1, 6):
			if flags.get("n%d_result" % i) in ["fight", "tried_then_fight"]:
				count += 1
		return count
	if key == "route":
		var results := []
		for i in range(1, 6):
			results.append(flags.get("n%d_result" % i))
		if results.all(func(v): return v == "talk"):
			return "talk"
		if results.all(func(v): return v == "fight"):
			return "fight"
		return "mixed"
	if key == "heart_count":
		var count := 0
		for heart in ["heart_shi_an", "heart_brother", "heart_xiaoman", "heart_shen_he"]:
			if flags.get(heart, false):
				count += 1
		return count
	return flags.get(key)

static func matches(flags: Dictionary, conditions: Dictionary) -> bool:
	for key in conditions:
		var actual = value(flags, key)
		var expected = conditions[key]
		if not expected is Dictionary:
			if actual != expected:
				return false
			continue
		for operator in expected:
			var operand = expected[operator]
			match operator:
				"$exists":
					if (actual != null) != operand: return false
				"$in":
					if not actual in operand: return false
				"$nin":
					if actual in operand: return false
				"$gte":
					if actual == null or actual < operand: return false
				"$gt":
					if actual == null or actual <= operand: return false
				"$lte":
					if actual == null or actual > operand: return false
				"$lt":
					if actual == null or actual >= operand: return false
				_:
					return false
	return true
