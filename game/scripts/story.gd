extends RefCounted
## Explicit progression prevents repeated interactions from skipping story beats.
enum Stage { STOP, ARRIVING, BOARD, CAB, CLOCK, RIDING, PASSENGER, NEXT_RIDE, SECOND_STOP, FINAL_RIDE, DEER, FINISHED }
var stage: int = Stage.STOP
var elapsed: float = 0.0

func interact(id: String) -> bool:
	var expected := {Stage.STOP: "note", Stage.BOARD: "door", Stage.CAB: "driver", Stage.CLOCK: "clock", Stage.PASSENGER: "passenger", Stage.DEER: "deer"}
	if expected.get(stage, "") != id or id.is_empty():
		return false
	stage += 1
	elapsed = 0.0
	return true

func depart_stop() -> bool:
	if stage!=Stage.SECOND_STOP:return false
	stage=Stage.FINAL_RIDE
	elapsed=0
	return true

func tick(delta: float) -> bool:
	elapsed += delta
	var duration: float = {Stage.ARRIVING:12.0,Stage.RIDING:26.0,Stage.NEXT_RIDE:30.0,Stage.FINAL_RIDE:24.0}.get(stage,INF)
	if elapsed >= duration:
		stage += 1
		elapsed = 0.0
		return true
	return false

func checkpoint() -> int:
	if stage >= Stage.DEER: return Stage.DEER
	if stage >= Stage.SECOND_STOP: return Stage.SECOND_STOP
	if stage >= Stage.PASSENGER: return Stage.PASSENGER
	if stage >= Stage.CAB: return Stage.CAB
	if stage >= Stage.BOARD: return Stage.BOARD
	return Stage.STOP

func restore(value: Variant) -> void:
	stage = Stage.STOP
	if value is int or value is float:
		if int(value) in [Stage.STOP, Stage.BOARD, Stage.CAB, Stage.PASSENGER, Stage.SECOND_STOP, Stage.DEER]: stage = int(value)
	elapsed = 0.0
