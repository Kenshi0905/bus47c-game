extends RefCounted
const Story=preload("res://scripts/story.gd")

static func content(g) -> String:
	var a=g.aftermath
	var lines: Array[String]=[]
	lines.append(entry("Read the shelter note. Board 47C.",g.story.stage>=Story.Stage.CAB))
	lines.append(entry("Ride toward Loomesville.",a.active))
	if a.active:
		lines.append(entry("Find something to eat.",a.fruit_taken.size()==3 or a.town_entered))
		var left_forest: bool=(a.branch=="walk" and a.phase not in ["fork","return","forage","disembark","hunger_cue","repairing"]) or a.town_entered
		lines.append(entry("Find five engine parts.  %d collected" % a.repairs.taken.size(),a.repairs.taken.size()==5 or left_forest))
		lines.append(entry("Repair the bus or take the footpath.",a.repairs.repaired or left_forest))
		if a.town_entered:
			lines.append(entry("Get to house 17.",a.phase not in ["town","walk"]))
			if a.phase in ["mirror","escape"]:
				lines.append(entry("Look into the mirror.",a.phase=="escape"))
	lines.append("")
	lines.append("[color=#302e26]NOW\n"+g.objective.text+"[/color]")
	lines.append("")
	lines.append(entry("Bus seats   E to sit   Space to stand",a.active))
	return "\n".join(lines)

static func entry(copy: String, done: bool) -> String:
	return "[color=#7a7565][s]"+copy+"[/s][/color]" if done else "[color=#33362e]"+copy+"[/color]"
