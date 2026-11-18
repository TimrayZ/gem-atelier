extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(true)
	await process_frame
	app.model.advance()
	app.model.advance()
	app.model.angle=25.0
	app.model.work(0.12)
	app.toggle_fast()
	for i in range(400):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage==4,"Fast processing finishes all stages")
	assert(app.model.cut_angles[0]==25.0,"Existing wrong cut is preserved")
	assert(app.model.polish.all(func(v):return v==1.0),"Only one polish pass per face")
	assert(app.sound.music.stream.get_length()>30.0,"Real BGM loaded")
	assert(app.sound.completion.stream.get_length()>3.0,"Completion chord loaded")
	app.model.reset(0)
	app.toggle_fast()
	app.toggle_fast()
	assert(not app.fast_mode,"F8 toggle cancels")
	app.model.fracture("test")
	app.toggle_fast()
	assert(not app.fast_mode,"Fast mode cannot revive lost stone")
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("FAST / SINGLE POLISH / AUDIO: passed")
	quit()
