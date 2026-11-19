extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.progression_path = "user://cut_gameplay_test.cfg"
	app.experience = 0
	app.panpan_sleeping = false
	app.model.reset(0, 0)
	app.model.advance()
	app.model.advance()
	app.start_work()
	app.model.work(0.30, true)
	var early: float = app.model.cut[app.model.facet]
	var original_green: float = app.green_start()
	app.stop_work()
	assert(app.model.cut[app.model.facet] == early and early < original_green, "Early release keeps progress on the same face")
	assert(app.green_start() < original_green, "Retry widens the green area")
	app.start_work()
	app.model.work((app.green_start()+0.02-early)/0.64, true)
	app.stop_work()
	assert(app.model.cut[0] == 1.0 and app.model.facet != 0, "Green release completes and selects the next face")
	assert(app.model.facet_grades[0] == "S" and app.model.facet_scores[0] >= 90, "Every green release earns S with a perfection score")
	assert(app.experience > 0, "Manual cut earns skill experience")
	var earned: int = app.experience
	app.model.reset(0,0)
	app.model.advance(); app.model.advance()
	assert(app.cutting_speed(0.9) < app.cutting_speed(0.1), "Cutting slows smoothly near the target")
	app.start_work()
	app.model.work(1.80,true)
	app.stop_work()
	assert(app.model.cut[0] == 1.0 and app.model.cut_depths[0] > 0.0, "Overcut is permanent and advances")
	var before: float = app.model.Solid.volume(app.model.body)
	app.model.fracture("test")
	assert(app.model.failed and app.model.can_magic_repair())
	app.use_magic()
	assert(not app.model.failed and absf(app.model.Solid.volume(app.model.body)-before) < 0.01, "Magic restores the last damaged solid")
	assert(app.panpan_sleeping, "Magic makes Panpan sleep")
	app.panpan_sleeping = false
	app.load_progression()
	assert(app.panpan_sleeping, "Sleeping state survives reload")
	app.model.fracture("again")
	app.use_magic()
	assert(app.model.failed, "Sleeping Panpan cannot repair twice today")
	app.panpan_sleeping = false
	app.use_magic()
	assert(not app.model.failed, "An awake Panpan can repair the next fracture")
	var xp_before_demo: int = app.experience
	app.model.reset(0,0)
	app.toggle_fast()
	for i in range(800):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage == 4 and app.model.geometry_quality() > 99.0, "F8 completes a perfect fresh demonstration")
	assert(app.experience == xp_before_demo and app.experience > earned, "Demonstrations do not earn XP")
	app.exhibition.close()
	app.model.reset(0,0)
	app.toggle_random_demo()
	assert(app.fast_mode and app.demo_random, "F9 selects randomized demonstration")
	seed(315)
	for i in range(800):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage == 4 and app.model.geometry_quality() < 99.0, "Novice F9 produces real imperfect geometry")
	assert(app.experience == xp_before_demo, "Random demonstration does not earn XP")
	assert(app.panpan_sleeping, "Demonstrations cannot wake Panpan")
	app.exhibition.close()
	app.model.reset(0,10)
	for i in range(app.model.facet_grades.size()): app.model.facet_grades[i] = "A" if i%2 == 0 else "S"
	assert(app.model.all_a_or_better(), "A and S both satisfy the wake condition")
	app.model.facet_grades[0] = "B"
	assert(not app.model.all_a_or_better(), "B does not satisfy the wake condition")
	app.model.reset(0,10)
	app.demo_run = false
	var guard := 0
	while app.model.stage != 4 and guard < 100:
		guard += 1
		if app.model.stage in [0,1]:
			app.on_primary()
		elif app.model.stage == 2:
			if app.model.section_done(app.model.cut):
				app.on_primary()
			else:
				app.start_work()
				while app.model.cut[app.model.facet] < app.green_start()+0.02 and not app.model.failed:
					app.model.work(0.03,true)
				app.stop_work()
		else:
			if app.model.section_done(app.model.polish):
				app.on_primary()
			else:
				while app.model.polish[app.model.facet] < 1.0 and not app.model.failed:
					app.model.work(0.03)
				app.model.next_facet()
	print("MANUAL RUN: ",app.model.stage," section=",app.model.section," failed=",app.model.failed," grades=",app.model.facet_grades," cut=",app.model.cut," polish=",app.model.polish)
	assert(app.model.stage == 4 and app.model.all_a_or_better(), "Real manual releases complete an all-A-or-better gem")
	assert(not app.panpan_sleeping, "A completed manually graded all-A-or-better gem wakes Panpan")
	app.model.save_path = "user://cut_gameplay_collection_test.json"
	app.model.collection.clear()
	assert(app.model.save_piece(), "Graded gem can be saved")
	var restored = load("res://scripts/workshop.gd").new()
	assert(restored.restore_piece(app.model.collection[0]), "Graded gem can be reopened")
	assert(restored.facet_grades == app.model.facet_grades and restored.overall_score() == app.model.overall_score(), "Scores survive collection restore")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.model.save_path))
	var saved_xp: int = app.experience
	app.experience = 0
	app.load_progression()
	assert(app.experience == saved_xp, "Skill XP survives reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(app.progression_path))
	app.sound.stop_all()
	app.queue_free()
	await process_frame
	print("CUT GRADES / XP / REPAIR / ALL-A WAKE / DEMOS: passed")
	quit()
