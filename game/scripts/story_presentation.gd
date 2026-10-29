extends Node
## Timed actions share one honest progress display. Endings play before results.
const ACTIONS := {
	"repairing":[5.0,"REPAIRING THE ENGINE",["Seat the replacement parts","Tighten the housing","Check the ignition"]],
	"burying":[8.0,"CLOSING THE GRAVE",["Lower the body","Cover with earth","Pack down the soil"]],
	"brewing":[4.0,"MAKING COFFEE",["Fill the kettle","Wait for the water","Pour a cup"]]
}
var game
var after
var panel: PanelContainer
var action_title: Label
var action_step: Label
var progress: ProgressBar
var credit_card: ColorRect
var credit_text: Label
var ending_kind := ""
var ending_beat := 0
var start_yaw := 0.0
var start_pitch := 0.0
var clock_yaw := 0.0
var clock_pitch := 0.0
var end_sound: AudioStreamPlayer3D

func setup(g,a) -> void:
	game=g
	after=a
	panel=PanelContainer.new()
	game.hud.add_child(panel)
	panel.position=Vector2(420,445)
	panel.custom_minimum_size=Vector2(440,100)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(.025,.03,.025,.86)
	style.border_color=Color("a39472")
	style.border_width_top=1
	style.content_margin_left=22
	style.content_margin_right=22
	style.content_margin_top=16
	style.content_margin_bottom=16
	panel.add_theme_stylebox_override("panel",style)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",9)
	panel.add_child(stack)
	action_title=game.label("",20)
	action_step=game.label("",16,Color("bbb8aa"))
	progress=ProgressBar.new()
	progress.custom_minimum_size.y=5
	progress.show_percentage=false
	progress.max_value=1
	var fill := StyleBoxFlat.new()
	fill.bg_color=Color("c4b992")
	progress.add_theme_stylebox_override("fill",fill)
	var base := StyleBoxFlat.new()
	base.bg_color=Color("33382f")
	progress.add_theme_stylebox_override("background",base)
	stack.add_child(action_title)
	stack.add_child(progress)
	stack.add_child(action_step)
	credit_card=ColorRect.new()
	game.hud.add_child(credit_card)
	credit_card.color=Color.BLACK
	credit_card.size=Vector2(1280,720)
	credit_card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	credit_text=game.label("",23)
	credit_card.add_child(credit_text)
	credit_text.position=Vector2(240,185)
	credit_text.size=Vector2(800,390)
	credit_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	credit_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	end_sound=AudioStreamPlayer3D.new()
	after.add_child(end_sound)
	end_sound.max_distance=28
	end_sound.unit_size=8
	end_sound.volume_db=-12
	reset()

func reset() -> void:
	panel.hide()
	credit_card.hide()
	ending_kind=""
	ending_beat=0
	end_sound.stop()

func update() -> void:
	panel.visible=ACTIONS.has(after.phase)
	if panel.visible:
		var action: Array=ACTIONS[after.phase]
		var fraction := clampf(after.state_time/float(action[0]),0,1)
		action_title.text=action[1]
		progress.value=fraction
		var step := mini(2,int(fraction*3))
		action_step.text="%s   %ds" % [action[2][step],maxi(0,ceili(float(action[0])-after.state_time))]
	if after.phase=="epilogue":update_ending()

func start_ending(kind: String) -> void:
	ending_kind=kind
	ending_beat=0
	after.set_phase("epilogue","")
	after.status.text=""
	panel.hide()
	game.player.enabled=false
	game.player.velocity=Vector3.ZERO
	start_yaw=game.player.rotation.y
	start_pitch=game.player.camera.rotation.x
	var target: Vector3=after.HOUSE+Vector3(3.4,2.25,5.04) if kind=="newspaper" else Vector3(0,2.2,12)
	var diff: Vector3=target-game.player.camera.global_position
	clock_yaw=atan2(-diff.x,-diff.z)
	clock_pitch=atan2(diff.y,Vector2(diff.x,diff.z).length())
	game.transition_shade.color=Color(0,0,0,0)
	end_sound.position=after.HOUSE+Vector3(0,1.4,5.7) if kind=="newspaper" else Vector3(0,1.5,18)
	game.say("That's my photograph..." if kind=="newspaper" else "This is the same ticket.",3.5,true)

func update_ending() -> void:
	var t: float=after.state_time
	# An unhurried first-person glance toward the clock, then the doorway.
	var turn := smoothstep(2,7,t)
	game.player.rotation.y=lerp_angle(start_yaw,clock_yaw,turn)
	game.player.camera.rotation.x=lerpf(start_pitch,clock_pitch,turn)
	game.player.camera.rotation.z=sin(t*1.2)*.008*(1-smoothstep(12,17,t))
	if t>=5 and ending_beat==0:
		game.say("Two thirty-six. It can't be." if ending_kind=="newspaper" else "I already took this bus.",3.5,true)
		ending_beat=1
	if t>=9 and ending_beat==1:
		end_sound.stream=preload("res://assets/audio/knock.wav") if ending_kind=="newspaper" else preload("res://assets/audio/chime.wav")
		end_sound.play()
		ending_beat=2
	if t>=12 and ending_beat==2:
		game.say("I remember the ride. But the fire..." if ending_kind=="newspaper" else "No. Not again.",4,true)
		ending_beat=3
	game.transition_shade.visible=t>=16 and t<20
	game.transition_shade.color.a=smoothstep(16,20,t)
	if t>=20:
		credit_card.show()
		credit_text.modulate.a=smoothstep(20,22,t)*(1-smoothstep(30,32,t))
		credit_text.text="BUS 47C\n\n"+("THE MORNING EDITION" if ending_kind=="newspaper" else "THE LAST SERVICE")+"\n\nTHE END\n\nStory and direction\nAshmit Avash\n\nThank you for playing."
	if t>=33:
		credit_card.hide()
		game.player.camera.rotation.z=0
		after.complete("THE MORNING EDITION" if ending_kind=="newspaper" else "THE LAST SERVICE","You made it home.\nThe night came with you." if ending_kind=="newspaper" else "The last service is arriving.\nYou have been here before.")
