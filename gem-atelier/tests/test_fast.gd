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
	assert(is_equal_approx(app.model.cut_angles[0],25.0),"F8 preserves a previously started incorrect cut")
	assert(app.model.polish.all(func(v):return v==1.0),"Only one polish pass per face")
	app.exhibition.close()
	app.model.reset(0)
	app.model.advance(); app.model.advance()
	while app.model.cut[0] < 1.0: app.model.work(0.04)
	app.model.facet_grades[0] = "A"
	app.model.facet_scores[0] = 85
	var completed_angle: float = app.model.cut_angles[0]
	app.model.next_facet()
	app.model.angle = 26.0
	app.model.work(0.12)
	var partial: float = app.model.cut[1]
	var generation: int = app.model.generation
	var xp: int = app.experience
	app.toggle_random_demo()
	assert(app.model.generation == generation and app.model.cut[1] == partial, "F9 keeps the current stone and progress")
	for i in range(400):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage == 4 and is_equal_approx(app.model.cut_angles[1],26.0), "F9 finishes the remainder and keeps the earlier error")
	assert(app.model.facet_grades[0] == "A" and app.model.facet_scores[0] == 85 and app.model.cut_angles[0] == completed_angle, "F9 keeps completed geometry and scores")
	assert(app.experience == xp, "Fast forward does not grant XP")
	app.exhibition.close()
	assert(app.sound.music.stream.get_length()>30.0,"Real BGM loaded")
	assert(app.sound.completion.stream.get_length()>3.0,"Completion chord loaded")
	app.model.reset(0)
	app.toggle_fast()
	app.toggle_fast()
	assert(not app.fast_mode,"F8 toggle cancels")
	app.model.fracture("test")
	app.toggle_fast()
	assert(not app.fast_mode and app.model.failed,"F8 cannot silently replace a broken stone")
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("FAST / SINGLE POLISH / AUDIO: passed")
	quit()
