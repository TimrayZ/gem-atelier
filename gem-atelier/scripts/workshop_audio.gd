extends Node
var impact: AudioStreamPlayer
var completion: AudioStreamPlayer
var music: AudioStreamPlayer
var timer := 0.0
var silent := false
var audible := true

func player(path: String, gain: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = load(path)
	p.volume_db = gain
	p.max_polyphony = 4
	add_child(p)
	return p

func _ready() -> void:
	audible = AudioServer.get_driver_name() != "Dummy"
	impact = player("res://audio/jade.wav", -13.0)
	completion = player("res://audio/complete.wav", -11.0)
	music = player("res://audio/carefree.mp3", -25.0)
	music.finished.connect(restart_music)
	if audible: music.play()

func restart_music() -> void:
	music.play()

func set_muted(all_off: bool, music_off: bool) -> void:
	silent = all_off
	impact.volume_db = -80.0 if all_off else -13.0
	completion.volume_db = -80.0 if all_off else -11.0
	music.volume_db = -80.0 if all_off or music_off else -25.0

func tick(working: bool, delta: float) -> void:
	timer -= delta
	if working and timer <= 0.0:
		play_impact()
		timer = 0.40

func play_impact() -> void:
	if silent or not audible: return
	impact.pitch_scale = randf_range(0.88, 1.05)
	impact.play()

func play_complete() -> void:
	if not silent and audible: completion.play()

func stop_all() -> void:
	for p in [impact, completion, music]:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
