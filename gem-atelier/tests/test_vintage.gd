extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/v07-"+name+".png"))
	print("CAPTURE ",name)
func click(at: Vector2) -> void:
	var motion:=InputEventMouseMotion.new()
	motion.position=at
	motion.global_position=at
	Input.parse_input_event(motion)
	await process_frame
	for down in [true,false]:
		var e:=InputEventMouseButton.new()
		e.position=at
		e.global_position=at
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=down
		Input.parse_input_event(e)
		await process_frame
func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(false)
	await create_timer(3.5).timeout
	assert(not app.guide.busy and not app.guide.voice.playing,"Mascot stays silent by default")
	await snap("quiet-workshop")
	await click(Vector2(950,640))
	assert(app.model.stage==1 and not app.guide.busy,"First primary click advances without a greeting")
	await click(Vector2(950,640))
	assert(app.model.stage==2 and not app.guide.busy,"Second click starts cutting without a dialogue loop")
	app.open_notes()
	assert(app.guide.busy and app.guide.greeting,"Explicit help still starts greeting")
	await create_timer(0.7).timeout
	await snap("manual-greeting")
	app.guide.open_page()
	await snap("manual-notes")
	await click(Vector2(800,523))
	await process_frame
	assert(app.model.stage==2 and not app.guide.busy,"Closing manual notes does not queue processing actions")
	app.toggle_fast()
	for i in range(500):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage==4 and not app.guide.busy,"Every later stage completes without narrative gating")
	app.world.auto_rotate=false
	await snap("quiet-showcase")
	app.model.reset(0)
	app.set_debug(true)
	app.on_primary()
	assert(app.model.stage==2,"Debug direct start remains supported")
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("DEFAULT SILENCE / UNBLOCKED PRIMARY / EXPLICIT HELP / FAST PROCESS: passed")
	quit()
