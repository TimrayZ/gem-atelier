extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> Image:
	app.world._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image=root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../artifacts/"+name+".png"))
	return img
func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(false)
	app.open_encyclopedia()
	assert(app.encyclopedia.visible and not app.guide.busy)
	await capture("v09-encyclopedia")
	# A real GUI click must close the panel, without starting machining.
	for down in [true,false]:
		var e:=InputEventMouseButton.new()
		e.position=Vector2(905,95)
		e.global_position=e.position
		e.button_index=MOUSE_BUTTON_LEFT
		e.pressed=down
		Input.parse_input_event(e)
		await process_frame
	assert(not app.encyclopedia.visible,"Encyclopedia close button works")
	app.model.reset(3,4)
	app.toggle_fast()
	for i in range(800):
		app.run_fast_steps()
		if not app.fast_mode: break
	assert(app.model.stage==4)
	app.world.set_process(false)
	app.world.auto_rotate=false
	app.world.t=0.0
	app.world.tilt=-0.9
	app.world.yaw=0.5
	var images: Array=[]
	for bounces in [6,12,20]:
		app.world.max_bounces=bounces
		app.refresh()
		images.append(await capture("v09-diamond-%d"%bounces))
	assert(images[0].get_data()!=images[2].get_data(),"Bounce limits must affect real transport")
	assert(app.world.optics.get_viewport().size==Vector2i(568,414),"Optics rendered independently at panel resolution")
	var start:=Time.get_ticks_msec()
	for i in range(30):
		app.world.yaw+=0.01
		app.world._process(0.0)
		await process_frame
		await RenderingServer.frame_post_draw
	print("NATIVE OPTICS 30 rotating frames, 20 bounces: ",Time.get_ticks_msec()-start," ms")
	# Exact same actual surface feeds damaged-shape optics.
	app.model.gem_id=4
	app.model.facet=app.model.tasks.size()-1
	app.model.angle=0.0
	app.model.pressure=1.8
	assert(app.model.make_edge_chip())
	app.world.yaw=0.5
	app.refresh()
	await capture("v09-chipped")
	app.sound.stop_all()
	app.queue_free()
	await process_frame
	print("ENCYCLOPEDIA / NATIVE OPTICS / BOUNCE COMPARISON / CHIP VIEW: passed")
	quit()
