extends RefCounted
## Old numeric checkpoint IDs remain valid; extra stops have appended IDs.
enum Stage { STOP, ARRIVING, BOARD, CAB, CLOCK, RIDING, PASSENGER, NEXT_RIDE, SECOND_STOP, FINAL_RIDE, DEER, FINISHED, THIRD_RIDE, THIRD_STOP, FOURTH_RIDE, FOURTH_STOP }
const STOP_NAMES := ["FIREWATCH SHELTER","MILL ROAD","OLD QUARRY","PINE CROSSING","ST BRIDE'S","LOOMESVILLE"]
const STOP_Z := [0.0,-130.0,-270.0,-410.0,-550.0,-900.0]
const MOVING := [Stage.RIDING,Stage.NEXT_RIDE,Stage.THIRD_RIDE,Stage.FOURTH_RIDE,Stage.FINAL_RIDE]
const STOP_STAGES := [Stage.BOARD,Stage.PASSENGER,Stage.SECOND_STOP,Stage.THIRD_STOP,Stage.FOURTH_STOP]
const DURATIONS := {Stage.ARRIVING:12.0,Stage.RIDING:26.0,Stage.NEXT_RIDE:30.0,Stage.THIRD_RIDE:28.0,Stage.FOURTH_RIDE:28.0,Stage.FINAL_RIDE:32.0}
var stage: int = Stage.STOP
var elapsed := 0.0

func interact(id: String) -> bool:
	var expected := {Stage.STOP:"note",Stage.BOARD:"door",Stage.CAB:"driver",Stage.CLOCK:"clock",Stage.PASSENGER:"passenger",Stage.DEER:"deer"}
	if expected.get(stage, "")!=id or id.is_empty():return false
	stage+=1
	elapsed=0
	return true

func depart_stop() -> bool:
	var next := {Stage.PASSENGER:Stage.NEXT_RIDE,Stage.SECOND_STOP:Stage.THIRD_RIDE,Stage.THIRD_STOP:Stage.FOURTH_RIDE,Stage.FOURTH_STOP:Stage.FINAL_RIDE}
	if not next.has(stage):return false
	stage=next[stage]
	elapsed=0
	return true

func tick(delta: float) -> bool:
	elapsed+=delta
	if elapsed<float(DURATIONS.get(stage,INF)):return false
	stage={Stage.ARRIVING:Stage.BOARD,Stage.RIDING:Stage.PASSENGER,Stage.NEXT_RIDE:Stage.SECOND_STOP,Stage.THIRD_RIDE:Stage.THIRD_STOP,Stage.FOURTH_RIDE:Stage.FOURTH_STOP,Stage.FINAL_RIDE:Stage.DEER}[stage]
	elapsed=0
	return true

func leg_index() -> int:
	return {Stage.RIDING:0,Stage.NEXT_RIDE:1,Stage.THIRD_RIDE:2,Stage.FOURTH_RIDE:3,Stage.FINAL_RIDE:4}.get(stage,-1)

func stop_index() -> int:
	return {Stage.BOARD:0,Stage.PASSENGER:1,Stage.SECOND_STOP:2,Stage.THIRD_STOP:3,Stage.FOURTH_STOP:4}.get(stage,0)

func checkpoint() -> int:
	if stage in [Stage.DEER,Stage.FINISHED]:return Stage.DEER
	if stage in [Stage.FOURTH_STOP,Stage.FINAL_RIDE]:return Stage.FOURTH_STOP
	if stage in [Stage.THIRD_STOP,Stage.FOURTH_RIDE]:return Stage.THIRD_STOP
	if stage in [Stage.SECOND_STOP,Stage.THIRD_RIDE]:return Stage.SECOND_STOP
	if stage in [Stage.PASSENGER,Stage.NEXT_RIDE]:return Stage.PASSENGER
	if stage in [Stage.CAB,Stage.CLOCK,Stage.RIDING]:return Stage.CAB
	if stage==Stage.BOARD:return Stage.BOARD
	return Stage.STOP

func restore(value: Variant) -> void:
	stage=Stage.STOP
	if value is int or value is float:
		if int(value) in [Stage.STOP,Stage.BOARD,Stage.CAB,Stage.PASSENGER,Stage.SECOND_STOP,Stage.THIRD_STOP,Stage.FOURTH_STOP,Stage.DEER]:stage=int(value)
	elapsed=0
