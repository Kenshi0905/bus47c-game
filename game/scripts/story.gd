extends RefCounted
## Explicit progression prevents repeated interactions from skipping story beats.
enum Stage { STOP, ARRIVING, BOARD, CAB, CLOCK, RIDING, PASSENGER, FINISHED }
var stage: int = Stage.STOP
var elapsed: float = 0.0

func interact(id: String) -> bool:
	var expected := {Stage.STOP: "note", Stage.BOARD: "door", Stage.CAB: "driver", Stage.CLOCK: "clock", Stage.PASSENGER: "passenger"}
	if expected.get(stage, "") != id or id.is_empty():
		return false
	stage += 1
	elapsed = 0.0
	return true

func tick(delta: float) -> bool:
	elapsed += delta
	if (stage == Stage.ARRIVING and elapsed >= 7.0) or (stage == Stage.RIDING and elapsed >= 16.0):
		stage += 1
		elapsed = 0.0
		return true
	return false

func checkpoint() -> int:
	if stage >= Stage.PASSENGER: return Stage.PASSENGER
	if stage >= Stage.CAB: return Stage.CAB
	if stage >= Stage.BOARD: return Stage.BOARD
	return Stage.STOP

func restore(value: Variant) -> void:
	stage = Stage.STOP
	if value is int or value is float:
		if int(value) in [Stage.STOP, Stage.BOARD, Stage.CAB, Stage.PASSENGER]: stage = int(value)
	elapsed = 0.0
