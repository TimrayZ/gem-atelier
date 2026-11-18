extends SceneTree
var app
var failures := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)

func capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output: String = ProjectSettings.globalize_path("res://").path_join("../artifacts").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	check(image.save_png(output.path_join("v02-"+filename+".png"))==OK,"Screenshot saved")
	print("CAPTURE: ",filename)

func work_face(id: int, error: float = 0.0) -> void:
	app.model.facet=id
	app.model.angle=app.model.tasks[id].angle+error if app.model.stage==2 else app.model.cut_angles[id]
	app.refresh()
	app.start_work()
	for frame in range(25):
		app._process(0.08)
		if app.facet_latched: break
	check(app.facet_latched,"Facet input completes")
	app.stop_work()
	app.world._process(0.1)
	await process_frame

func process_all(error: float = 0.0) -> void:
	for section in range(2):
		for id in app.model.active_ids(): await work_face(id,error if id<8 else 0.0)
		app.on_primary()
		for wheel in [1]:
			app.model.wheel=wheel
			for id in app.model.active_ids(): await work_face(id)
		app.on_primary()
		if section==0:
			await capture("05-transfer")
			app.on_primary()
	check(app.model.stage==4,"Real UI reaches showcase after transfer")

func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(true)
	await create_timer(0.8).timeout
	await capture("01-coated-rough")
	app.model.crust=false
	app.refresh()
	await capture("02-uncoated-rough")
	await click_at(Vector2(950,640))
	check(app.model.stage==2,"Debug primary click goes straight to cutting")
	await click_at(Vector2(950,640))
	check(app.model.stage==2,"Actual click begins pavilion")
	await mouse_event(Vector2(970,532),true)
	await create_timer(0.25).timeout
	check(app.holding and app.model.cut[0]>0,"Actual hold clips raw")
	await mouse_event(Vector2(500,590),false)
	check(not app.holding,"Release outside stops cutting")
	await work_face(0)
	await capture("03-machine-contact")
	app.world.inspection=true
	app.world.yaw=-PI/2
	app.refresh()
	await capture("03-first-face")
	await work_face(1)
	app.world.inspection=true
	await capture("04-second-face")
	# Real Godot rigid bodies should move under gravity.
	app.world._process(0.01)
	check(not app.world.chunks.is_empty(),"Cut creates RigidBody3D debris")
	if not app.world.chunks.is_empty():
		var chunk: RigidBody3D = app.world.chunks.back().node
		var before: Vector3 = chunk.position
		await create_timer(0.2).timeout
		check(chunk.position.distance_to(before)>0.0001,"Physics engine moves debris")
	# Fresh specimen for the complete reference cut.
	app.model.reset(1)
	app.on_primary()
	app.on_primary()
	await process_all()
	app.world.auto_rotate=false
	app.world.yaw=0.35
	app.world.tilt=-0.85
	for mode in range(3):
		app.world.light_mode=mode
		app.refresh()
		await create_timer(0.5).timeout
		await capture("06-correct-light-%d"%mode)
	app.world.light_mode=0
	var before_yaw: float = app.world.yaw
	await mouse_event(Vector2(550,350),true)
	var drag := InputEventMouseMotion.new()
	drag.position=Vector2(610,370)
	drag.global_position=drag.position
	drag.relative=Vector2(60,20)
	Input.parse_input_event(drag)
	await process_frame
	await mouse_event(Vector2(610,370),false)
	check(absf(app.world.yaw-before_yaw)>0.1,"Actual dragging rotates optical geometry")
	await capture("06-rotated-optics")
	app.world.yaw=0.35
	app.world.tilt=-0.85
	app.world.optical_enabled=false
	await capture("07-correct-geometry")
	app.world.optical_enabled=true
	var good_return: float=app.model.optical_return
	app.model.reset(1)
	app.on_primary()
	app.on_primary()
	await process_all(-18.0)
	app.world.auto_rotate=false
	app.world.yaw=0.35
	app.world.tilt=-0.85
	await capture("08-shallow-optics")
	check(good_return>app.model.optical_return+0.2,"Wrong cut visibly uses leaking geometry")
	app.world.optical_enabled=false
	await capture("09-shallow-geometry")
	app.model.reset(1)
	app.on_primary()
	app.on_primary()
	app.model.temperature=85.0
	app.model.set_water(false)
	app.start_work()
	for i in range(20):
		app._process(0.08)
		if app.model.failed: break
	app.world.inspection=true
	app.world._process(0.01)
	app.refresh()
	await capture("10-fractured")
	check(app.model.failed and not app.holding,"Fracture stops user machining permanently")
	app.audio_playback = null
	app.audio_player.stop()
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	await process_frame
	print("SCENE / INPUT / PHYSICS / SHADER: %d failures"%failures)
	quit(1 if failures else 0)

func mouse_event(at: Vector2, down: bool) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=at
	motion.global_position=at
	Input.parse_input_event(motion)
	var event:=InputEventMouseButton.new()
	event.position=at
	event.global_position=at
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=down
	Input.parse_input_event(event)
	await process_frame

func click_at(at: Vector2) -> void:
	await mouse_event(at,true)
	await mouse_event(at,false)
