extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func snap(name: String) -> void:
	app.refresh()
	app.world._process(0.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/v05-"+name+".png"))
	print("CAPTURE ",name)
func run() -> void:
	root.size=Vector2i(1120,720)
	app=load("res://main.tscn").instantiate()
	root.add_child(app)
	app.set_debug(true)
	await snap("selection")
	for shape in range(app.model.SHAPES.size()):
		app.model.reset(3,shape)
		app.toggle_fast()
		for frame in range(600):
			app.run_fast_steps()
			if not app.fast_mode: break
			if frame%10==0: await process_frame
		assert(app.model.stage==4)
		app.world.auto_rotate=false
		app.world.yaw=0.35
		app.world.tilt=-1.1
		app.world.t=0.0
		await snap("diamond-%d"%shape)
		app.world.yaw+=0.3
		await snap("diamond-%d-rotated"%shape)
	var start:=Time.get_ticks_msec()
	for frame in range(60): await process_frame
	print("RENDER 60 frames elapsed ms=",Time.get_ticks_msec()-start)
	app.sound.stop_all()
	await create_timer(0.15).timeout
	app.queue_free()
	await process_frame
	print("SHAPE VIEWER: passed")
	quit()
