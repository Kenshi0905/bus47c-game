extends Node
## Original cues arranged around space, close footsteps and deliberate quiet.
var game
var bed: AudioStreamPlayer
var tension: AudioStreamPlayer
var event: AudioStreamPlayer
var walk_age := 0.0
var swell_count := 0

func setup(g) -> void:
	game=g
	bed=AudioStreamPlayer.new()
	tension=AudioStreamPlayer.new()
	event=AudioStreamPlayer.new()
	for player in [bed,tension,event]:add_child(player)
	var loop: AudioStreamWAV=preload("res://assets/audio/beta_path_bed.wav").duplicate()
	loop.loop_mode=AudioStreamWAV.LOOP_FORWARD
	# Imported WAV data may be compressed. Loop points use decoded sample frames.
	loop.loop_end=roundi(loop.get_length()*loop.mix_rate)
	bed.stream=loop
	bed.volume_db=-60
	tension.stream=preload("res://assets/audio/beta_tension.wav")
	tension.volume_db=-2

func reset() -> void:
	for player in [bed,tension,event]:
		player.stop()
		player.stream_paused=false
	walk_age=0
	swell_count=0
	bed.volume_db=-60
	game.ambience.volume_db=-15

func on_phase(phase: String) -> void:
	if phase=="walk":
		walk_age=0
		swell_count=0
		bed.volume_db=-60
		bed.play()
	else:
		bed.stop()
		tension.stop()
	if phase=="jumpscare":
		event.stream=preload("res://assets/audio/beta_scare.wav")
		event.volume_db=-8
		event.play()
	elif phase=="dead":
		event.stream=preload("res://assets/audio/beta_death.wav")
		event.volume_db=-8
		event.play()
	elif phase in ["town","loop","ending"]:event.stop()

func update(delta: float) -> void:
	if not game.running:
		reset()
		return
	var blocked: bool=game.paused or game.modal
	bed.stream_paused=blocked
	tension.stream_paused=blocked
	# The failure sting resolves over the retry menu; Escape pauses other cues.
	event.stream_paused=blocked and game.aftermath.phase!="dead"
	if blocked:return
	var walking: bool=game.aftermath.active and game.aftermath.phase=="walk" and not game.aftermath.town_entered
	if walking:
		walk_age+=delta
		var quiet := fmod(walk_age,38)>27
		var target := -24.0 if quiet else -5.0
		bed.volume_db=move_toward(bed.volume_db,target,delta*24)
		# Two swells need not predict an attack. The second leaves a quiet gap.
		if (swell_count==0 and walk_age>=8) or (swell_count==1 and walk_age>=47):
			tension.play()
			swell_count+=1
	else:
		bed.stop()
		tension.stop()
	var ambience_level := -21.0 if walking else -15.0
	if event.playing:ambience_level=-27
	game.ambience.volume_db=move_toward(game.ambience.volume_db,ambience_level,delta*8)
